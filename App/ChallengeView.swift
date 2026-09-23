import SwiftUI

struct ChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: FocusSession
    @StateObject private var camera = PoseCameraModel()

    private let mint = Color(red: 0.42, green: 0.96, blue: 0.77)

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

            LinearGradient(
                colors: [.black.opacity(0.7), .clear, .clear, .black.opacity(0.88)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.55), in: Circle())
                    }
                    .accessibilityLabel("返回")

                    Spacer()

                    HStack(spacing: 7) {
                        Circle()
                            .fill(mint)
                            .frame(width: 7, height: 7)
                        Text("前置镜头 · 实时识别")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .padding(.horizontal, 13)
                    .frame(height: 36)
                    .background(.black.opacity(0.55), in: Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()

                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center, spacing: 16) {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("下蹲训练")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                            Text(camera.phaseLabel)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(mint)
                        }
                        Spacer()
                        ZStack {
                            Circle()
                                .stroke(.white.opacity(0.16), lineWidth: 6)
                            Circle()
                                .trim(from: 0, to: min(CGFloat(camera.completed) / CGFloat(max(session.pushUpTarget, 1)), 1))
                                .stroke(mint, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            VStack(spacing: -2) {
                                Text("\(camera.completed)")
                                    .font(.system(size: 30, weight: .bold, design: .rounded))
                                Text("/ \(session.pushUpTarget)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .monospacedDigit()
                        }
                        .frame(width: 82, height: 82)
                    }

                    Rectangle()
                        .fill(.white.opacity(0.16))
                        .frame(height: 1)

                    Text(camera.statusText)
                        .font(.system(size: 17, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)

                    HStack {
                        Label("下蹲幅度", systemImage: "figure.strengthtraining.functional")
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Text(camera.depthPercent.map { "\($0)%" } ?? "--")
                            .monospacedDigit()
                            .foregroundStyle(mint)
                    }
                    .font(.system(size: 13, weight: .medium))

                    ProgressView(value: Double(min(camera.depthPercent ?? 0, 40)), total: 40)
                        .tint(mint)

                    Text("手机固定在正前方，先站直校准，保持头到脚入镜。蹲下再站直计 1 次。")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.68))
                        .fixedSize(horizontal: false, vertical: true)

                    if session.hasActivity && camera.completed >= session.pushUpTarget {
                        Button {
                            session.finish()
                            dismiss()
                        } label: {
                            Label("完成任务", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                        }
                        .font(.headline)
                        .buttonStyle(.plain)
                        .foregroundStyle(Color(red: 0.06, green: 0.13, blue: 0.16))
                        .background(mint, in: RoundedRectangle(cornerRadius: 14))
                    }
                }
                .foregroundStyle(.white)
                .padding(20)
                .background(Color(red: 0.05, green: 0.12, blue: 0.16).opacity(0.94), in: RoundedRectangle(cornerRadius: 28))
                .overlay {
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
    }
}
