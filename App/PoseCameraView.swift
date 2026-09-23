import AVFoundation
import SwiftUI
import UIKit

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.configureConnection()
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.configureConnection()
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        configureConnection()
    }

    func configureConnection() {
        guard let connection = previewLayer.connection else { return }
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }
    }
}

struct PoseSkeletonView: View {
    let pose: PoseSnapshot

    private let connections: [(BodyJoint, BodyJoint)] = [
        (.neck, .leftShoulder), (.neck, .rightShoulder),
        (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
        (.leftHip, .rightHip),
        (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee), (.rightKnee, .rightAnkle)
    ]

    var body: some View {
        Canvas { context, size in
            let scale = max(size.width / pose.imageSize.width, size.height / pose.imageSize.height)
            let width = pose.imageSize.width * scale
            let height = pose.imageSize.height * scale
            let xOffset = (size.width - width) / 2
            let yOffset = (size.height - height) / 2

            func screenPoint(_ joint: BodyJoint) -> CGPoint? {
                guard let point = pose.points[joint] else { return nil }
                return CGPoint(
                    x: xOffset + (1 - point.x) * width,
                    y: yOffset + (1 - point.y) * height
                )
            }

            for (first, second) in connections {
                guard let a = screenPoint(first), let b = screenPoint(second) else { continue }
                var path = Path()
                path.move(to: a)
                path.addLine(to: b)
                context.stroke(path, with: .color(.cyan), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            }
            for joint in BodyJoint.allCases {
                guard let point = screenPoint(joint) else { continue }
                let circle = Path(ellipseIn: CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10))
                context.fill(circle, with: .color(.orange))
            }
        }
    }
}
