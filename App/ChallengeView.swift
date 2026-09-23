import SwiftUI

struct ChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: FocusSession
    @StateObject private var camera = PoseCameraModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            CameraPreview(session: camera.captureSession)
                .ignoresSafeArea()

            GeometryReader { geometry in
                if let pose = camera.pose {
                    PoseSkeletonView(pose: pose)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.65), in: Circle())
                    }
                    .accessibilityLabel("返回")

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(camera.completed) / \(session.pushUpTarget)")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text("真实姿态检测")
                            .font(.caption)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 18))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.top, 8)

                Spacer()

                VStack(spacing: 10) {
                    Text(camera.statusText)
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    if let angle = camera.elbowAngle {
                        Text("手肘角度 \(Int(angle.rounded()))° · 完整下压再推起计 1 次")
                            .font(.caption)
                            .monospacedDigit()
                    } else {
                        Text("将手机竖放在身体侧前方，屏幕朝向自己，让全身进入画面")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }

                    if session.hasActivity && camera.completed >= session.pushUpTarget {
                        Button("完成任务") {
                            session.finish()
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .padding(.top, 4)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 18)
                .padding(.bottom, 12)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
    }
}
