import AVFoundation
import Combine
import Foundation
import Vision

enum BodyJoint: CaseIterable, Hashable {
    case neck
    case leftShoulder, leftElbow, leftWrist, leftHip, leftKnee, leftAnkle
    case rightShoulder, rightElbow, rightWrist, rightHip, rightKnee, rightAnkle

    var visionName: VNHumanBodyPoseObservation.JointName {
        switch self {
        case .neck: return .neck
        case .leftShoulder: return .leftShoulder
        case .leftElbow: return .leftElbow
        case .leftWrist: return .leftWrist
        case .leftHip: return .leftHip
        case .leftKnee: return .leftKnee
        case .leftAnkle: return .leftAnkle
        case .rightShoulder: return .rightShoulder
        case .rightElbow: return .rightElbow
        case .rightWrist: return .rightWrist
        case .rightHip: return .rightHip
        case .rightKnee: return .rightKnee
        case .rightAnkle: return .rightAnkle
        }
    }
}

struct PoseSnapshot {
    let points: [BodyJoint: CGPoint]
    let imageSize: CGSize
}

final class PoseCameraModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published private(set) var pose: PoseSnapshot?
    @Published private(set) var completed = 0
    @Published private(set) var depthPercent: Int?
    @Published private(set) var phaseLabel = "准备中"
    @Published private(set) var statusText = "正在准备相机…"

    let captureSession = AVCaptureSession()

    private let captureQueue = DispatchQueue(label: "FocusRep.capture", qos: .userInitiated)
    private let visionRequest = VNDetectHumanBodyPoseRequest()
    private var configured = false
    private var frameNumber = 0
    private var phase: Phase = .calibrating
    private var counted = 0
    private var lastPoseTime = Date.distantPast
    private var standingHeight: CGFloat?
    private var standingThighHeight: CGFloat?
    private var calibrationSamples = 0
    private var bottomFrames = 0
    private var topFrames = 0

    private enum Phase {
        case calibrating, ready, down
    }

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startCapture()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] allowed in
                if allowed {
                    self?.startCapture()
                } else {
                    self?.publishStatus("未获得相机权限，请在设置中允许 FocusRep 使用相机")
                }
            }
        default:
            publishStatus("相机权限已关闭，请在设置中允许 FocusRep 使用相机")
        }
    }

    func stop() {
        captureQueue.async { [weak self] in
            guard let self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
        }
    }

    private func startCapture() {
        captureQueue.async { [weak self] in
            guard let self else { return }
            if !self.configured && !self.configureCapture() { return }
            guard !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
            self.publishStatus("寻找人体骨架…")
        }
    }

    private func configureCapture() -> Bool {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .hd1280x720
        defer { captureSession.commitConfiguration() }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input) else {
            publishStatus("无法打开前置相机")
            return false
        }
        captureSession.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        guard captureSession.canAddOutput(output) else {
            publishStatus("无法读取相机画面")
            return false
        }
        captureSession.addOutput(output)
        if let connection = output.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = false
            }
        }
        output.setSampleBufferDelegate(self, queue: captureQueue)
        configured = true
        return true
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        frameNumber += 1
        guard frameNumber.isMultiple(of: 3), let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        do {
            try handler.perform([visionRequest])
        } catch {
            publishStatus("人体姿态识别失败：\(error.localizedDescription)")
            return
        }

        guard let observation = visionRequest.results?.first else {
            resetTrackingIfStale()
            publish(pose: nil, depth: nil, phaseLabel: "等待入镜", status: "请站到镜头前，让全身进入画面")
            return
        }

        var points: [BodyJoint: CGPoint] = [:]
        for joint in BodyJoint.allCases {
            if let point = try? observation.recognizedPoint(joint.visionName), point.confidence >= 0.4 {
                points[joint] = point.location
            }
        }

        let size = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
        let snapshot = PoseSnapshot(points: points, imageSize: size)
        guard let metrics = Self.measure(snapshot) else {
            resetTrackingIfStale()
            publish(pose: snapshot, depth: nil, phaseLabel: "调整站位", status: "请后退一点，让髋、膝盖和脚踝都进入画面")
            return
        }

        lastPoseTime = Date()
        if phase == .calibrating {
            guard metrics.thighHeight / metrics.shinHeight >= 0.58 else {
                calibrationSamples = 0
                publish(pose: snapshot, depth: nil, phaseLabel: "先站直", status: "先站直，保持全身在画面里")
                return
            }
            standingHeight = max(standingHeight ?? 0, metrics.hipHeight)
            standingThighHeight = max(standingThighHeight ?? 0, metrics.thighHeight)
            calibrationSamples += 1
            if calibrationSamples < 5 {
                publish(pose: snapshot, depth: nil, phaseLabel: "正在校准", status: "保持站直，正在记录起始姿势")
                return
            }
            phase = .ready
        }

        guard let standingHeight, let standingThighHeight else { return }
        let depth = max(0, min(100, Int(((1 - metrics.hipHeight / standingHeight) * 100).rounded())))
        let status: String
        let label: String
        switch phase {
        case .calibrating:
            status = "保持站直，正在记录起始姿势"
            label = "正在校准"
        case .ready:
            topFrames = 0
            if depth >= 22 && metrics.thighHeight <= standingThighHeight * 0.7 {
                bottomFrames += 1
                if bottomFrames >= 2 {
                    phase = .down
                    bottomFrames = 0
                    status = "下蹲已识别，站起来完成这次"
                    label = "已蹲下"
                } else {
                    status = "继续下蹲，保持动作稳定"
                    label = "下蹲中"
                }
            } else {
                bottomFrames = 0
                status = "慢慢下蹲，再站直计 1 次"
                label = "准备下蹲"
            }
        case .down:
            if depth <= 12 && metrics.thighHeight >= standingThighHeight * 0.78 {
                topFrames += 1
                if topFrames >= 2 {
                    phase = .ready
                    topFrames = 0
                    counted += 1
                    status = "完成第 \(counted) 次下蹲"
                    label = "动作完成"
                } else {
                    status = "继续站直，完成这一次"
                    label = "起立中"
                }
            } else {
                topFrames = 0
                status = "向上站直，完成这一次"
                label = "起立中"
            }
        }
        publish(pose: snapshot, depth: depth, phaseLabel: label, status: status)
    }

    private struct Metrics {
        let hipHeight: CGFloat
        let thighHeight: CGFloat
        let shinHeight: CGFloat
    }

    private static func measure(_ pose: PoseSnapshot) -> Metrics? {
        let sides: [(BodyJoint, BodyJoint, BodyJoint)] = [
            (.leftHip, .leftKnee, .leftAnkle),
            (.rightHip, .rightKnee, .rightAnkle)
        ]
        var measurements: [Metrics] = []
        for (hipKey, kneeKey, ankleKey) in sides {
            guard let hip = pose.points[hipKey],
                  let knee = pose.points[kneeKey],
                  let ankle = pose.points[ankleKey] else { continue }
            let hipHeight = hip.y - ankle.y
            let shinHeight = knee.y - ankle.y
            guard hipHeight > 0.08, shinHeight > 0.05 else { continue }
            measurements.append(Metrics(
                hipHeight: hipHeight,
                thighHeight: hip.y - knee.y,
                shinHeight: shinHeight
            ))
        }
        guard !measurements.isEmpty else { return nil }
        let count = CGFloat(measurements.count)
        return Metrics(
            hipHeight: measurements.reduce(0) { $0 + $1.hipHeight } / count,
            thighHeight: measurements.reduce(0) { $0 + $1.thighHeight } / count,
            shinHeight: measurements.reduce(0) { $0 + $1.shinHeight } / count
        )
    }

    private func resetTrackingIfStale() {
        guard Date().timeIntervalSince(lastPoseTime) > 1.5 else { return }
        phase = .calibrating
        standingHeight = nil
        standingThighHeight = nil
        calibrationSamples = 0
        bottomFrames = 0
        topFrames = 0
    }

    private func publish(pose snapshot: PoseSnapshot?, depth: Int?, phaseLabel: String, status: String) {
        let total = counted
        DispatchQueue.main.async { [weak self] in
            self?.pose = snapshot
            self?.depthPercent = depth
            self?.phaseLabel = phaseLabel
            self?.completed = total
            self?.statusText = status
        }
    }

    private func publishStatus(_ status: String) {
        DispatchQueue.main.async { [weak self] in self?.statusText = status }
    }
}
