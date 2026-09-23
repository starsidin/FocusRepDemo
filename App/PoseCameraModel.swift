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
    @Published private(set) var elbowAngle: Double?
    @Published private(set) var statusText = "正在准备相机…"

    let captureSession = AVCaptureSession()

    private let captureQueue = DispatchQueue(label: "FocusRep.capture", qos: .userInitiated)
    private let visionRequest = VNDetectHumanBodyPoseRequest()
    private var configured = false
    private var frameNumber = 0
    private var phase: Phase = .waitingForTop
    private var counted = 0
    private var lastPoseTime = Date.distantPast

    private enum Phase {
        case waitingForTop, atTop, atBottom
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

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input) else {
            publishStatus("无法打开后置相机")
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
        if let connection = output.connection(with: .video), connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
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
            if Date().timeIntervalSince(lastPoseTime) > 1.5 { phase = .waitingForTop }
            publish(pose: nil, angle: nil, status: "未检测到人体，请退后让全身进入画面")
            return
        }

        lastPoseTime = Date()
        var points: [BodyJoint: CGPoint] = [:]
        for joint in BodyJoint.allCases {
            if let point = try? observation.recognizedPoint(joint.visionName), point.confidence >= 0.45 {
                points[joint] = point.location
            }
        }

        let size = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
        let snapshot = PoseSnapshot(points: points, imageSize: size)
        guard let metrics = Self.measure(snapshot) else {
            phase = .waitingForTop
            publish(pose: snapshot, angle: nil, status: "已看到骨架，请露出肩、手肘、手腕、髋和脚踝")
            return
        }

        let status: String
        if metrics.bodyAngle < 145 || metrics.tilt > 35 {
            phase = .waitingForTop
            status = "请侧身摆好平板姿势，再开始俯卧撑"
        } else {
            switch phase {
            case .waitingForTop:
                if metrics.elbow >= 155 { phase = .atTop }
                status = "先伸直手臂，准备下压"
            case .atTop:
                if metrics.elbow <= 100 {
                    phase = .atBottom
                    status = "已检测到下压，推起身体"
                } else {
                    status = "弯曲手臂，继续下压"
                }
            case .atBottom:
                if metrics.elbow >= 155 {
                    phase = .atTop
                    counted += 1
                    status = "完成第 \(counted) 个俯卧撑"
                } else {
                    status = "伸直手臂，完成这一次"
                }
            }
        }
        publish(pose: snapshot, angle: metrics.elbow, status: status)
    }

    private struct Metrics {
        let elbow: Double
        let bodyAngle: Double
        let tilt: Double
    }

    private static func measure(_ pose: PoseSnapshot) -> Metrics? {
        let sides: [(BodyJoint, BodyJoint, BodyJoint, BodyJoint, BodyJoint)] = [
            (.leftShoulder, .leftElbow, .leftWrist, .leftHip, .leftAnkle),
            (.rightShoulder, .rightElbow, .rightWrist, .rightHip, .rightAnkle)
        ]
        for (shoulderKey, elbowKey, wristKey, hipKey, ankleKey) in sides {
            guard let shoulder = pose.points[shoulderKey],
                  let elbow = pose.points[elbowKey],
                  let wrist = pose.points[wristKey],
                  let hip = pose.points[hipKey],
                  let ankle = pose.points[ankleKey] else { continue }
            let size = pose.imageSize
            func pixel(_ point: CGPoint) -> CGPoint {
                CGPoint(x: point.x * size.width, y: point.y * size.height)
            }
            let s = pixel(shoulder), e = pixel(elbow), w = pixel(wrist)
            let h = pixel(hip), a = pixel(ankle)
            return Metrics(
                elbow: angle(s, e, w),
                bodyAngle: angle(s, h, a),
                tilt: atan2(abs(Double(h.y - s.y)), abs(Double(h.x - s.x))) * 180 / Double.pi
            )
        }
        return nil
    }

    private static func angle(_ a: CGPoint, _ center: CGPoint, _ b: CGPoint) -> Double {
        let ax = Double(a.x - center.x), ay = Double(a.y - center.y)
        let bx = Double(b.x - center.x), by = Double(b.y - center.y)
        let length = hypot(ax, ay) * hypot(bx, by)
        guard length > 1 else { return 0 }
        let cosine = max(-1.0, min(1.0, (ax * bx + ay * by) / length))
        return acos(cosine) * 180 / .pi
    }

    private func publish(pose snapshot: PoseSnapshot?, angle: Double?, status: String) {
        let total = counted
        DispatchQueue.main.async { [weak self] in
            self?.pose = snapshot
            self?.elbowAngle = angle
            self?.completed = total
            self?.statusText = status
        }
    }

    private func publishStatus(_ status: String) {
        DispatchQueue.main.async { [weak self] in self?.statusText = status }
    }
}
