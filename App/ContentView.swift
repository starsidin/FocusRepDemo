import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var session: FocusSession

    private let mint = Color(red: 0.42, green: 0.96, blue: 0.77)
    private let ink = Color(red: 0.05, green: 0.10, blue: 0.14)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    HStack {
                        Image(systemName: "circle.hexagongrid.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(mint)
                        Text("FOCUS / MOVE")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .tracking(2)
                        Spacer()
                    }
                    .padding(.top, 16)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("放下屏幕，\n动起来。")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .tracking(-1.5)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("设定屏幕时间目标，再用一组下蹲找回专注。")
                            .font(.system(size: 15))
                            .foregroundStyle(.white.opacity(0.65))
                    }

                    VStack(alignment: .leading, spacing: 22) {
                        HStack {
                            Image(systemName: "figure.strengthtraining.functional")
                                .font(.system(size: 30, weight: .medium))
                                .frame(width: 64, height: 64)
                                .foregroundStyle(ink)
                                .background(mint, in: RoundedRectangle(cornerRadius: 20))
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(mint)
                        }

                        VStack(alignment: .leading, spacing: 7) {
                            Text("今日动作")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(mint)
                            Text("\(session.pushUpTarget) 次下蹲")
                                .font(.system(size: 31, weight: .bold, design: .rounded))
                            Text("前置镜头识别 · 实时骨架反馈")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.62))
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "iphone.gen3")
                            Text("站在手机正前方，全身入镜即可")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.78))
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.12, green: 0.25, blue: 0.28), Color(red: 0.07, green: 0.15, blue: 0.20)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 28)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(mint.opacity(0.24), lineWidth: 1)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label("运动屏幕时间控制", systemImage: "iphone.gen3")
                                .font(.system(size: 17, weight: .semibold))
                            Spacer()
                            Text(session.selectedControlMinutes == 60 ? "60 分钟（1）" : "30 分钟")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(mint)
                        }
                        Text("剩余时间会显示在灵动岛。长按可查看进度，轻点进入下蹲页面。")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.6))
                            .fixedSize(horizontal: false, vertical: true)
                        Picker("屏幕时间目标", selection: $session.selectedControlMinutes) {
                            Text("30 分钟").tag(30)
                            Text("60 分钟（1）").tag(60)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 24))

                    VStack(spacing: 12) {
                        Button {
                            session.start()
                        } label: {
                            HStack {
                                Image(systemName: "iphone.gen3")
                                Text(session.hasActivity ? "重新开始运动屏幕时间控制" : "开始运动屏幕时间控制")
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                            .font(.system(size: 17, weight: .bold))
                            .padding(.horizontal, 20)
                            .frame(height: 58)
                            .foregroundStyle(ink)
                            .background(mint, in: RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(.plain)

                        Button("开始下蹲检测") {
                            session.showChallenge = true
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundStyle(.white)
                        .background(.white.opacity(0.11), in: RoundedRectangle(cornerRadius: 16))
                        .buttonStyle(.plain)

                        if session.hasActivity {
                            Button("结束本次控制", role: .destructive) {
                                session.finish()
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.62))
                            .padding(.top, 4)
                        }
                    }

                    Text("系统 App 限额需在 iPhone 设置中单独配置；这里不会自动读取或修改系统限额。")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 16)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                ZStack {
                    ink
                    Circle()
                        .fill(mint.opacity(0.11))
                        .frame(width: 360, height: 360)
                        .blur(radius: 110)
                        .offset(x: 160, y: -300)
                }
                .ignoresSafeArea()
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $session.showChallenge) {
                ChallengeView()
            }
            .alert("启动失败", isPresented: Binding(
                get: { session.errorMessage != nil },
                set: { if !$0 { session.clearError() } }
            )) {
                Button("知道了") { session.clearError() }
            } message: {
                Text(session.errorMessage ?? "未知错误")
            }
        }
        .preferredColorScheme(.dark)
    }
}
