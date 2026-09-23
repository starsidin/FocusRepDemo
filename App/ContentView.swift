import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var session: FocusSession

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("少刷一会儿，做组俯卧撑")
                        .font(.largeTitle.bold())
                    Text("开启 30 分钟倒计时后，灵动岛会显示剩余时间。长按灵动岛可查看运动提示与进度。")
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        Label("\(session.demoDurationMinutes) 分钟倒计时", systemImage: "timer")
                        Label("到点后完成 \(session.pushUpTarget) 个俯卧撑", systemImage: "figure.strengthtraining.functional")
                        Label("第一版不涉及付款", systemImage: "checkmark.shield")
                    }
                    .font(.headline)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))

                    Picker("演示时长", selection: $session.demoDurationMinutes) {
                        Text("1 分钟测试").tag(1)
                        Text("30 分钟正式演示").tag(30)
                    }
                    .pickerStyle(.segmented)

                    Button(session.hasActivity ? "重新开始演示" : "开始倒计时") {
                        session.start()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)

                    if session.hasActivity {
                        Button("进入俯卧撑任务") {
                            session.showChallenge = true
                        }
                        .buttonStyle(.bordered)

                        Button("结束本次演示", role: .destructive) {
                            session.finish()
                        }
                    }

                    Button {
                        session.showChallenge = true
                    } label: {
                        Label("测试摄像头骨架识别", systemImage: "camera.viewfinder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .controlSize(.large)

                    Text("演示时请另外在 iPhone 设置里配置屏幕使用时间的 App 限额。系统限额与本 App 倒计时不会自动同步。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle("专注俯卧撑")
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
    }
}
