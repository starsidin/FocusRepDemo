import SwiftUI

struct ChallengeView: View {
    @EnvironmentObject private var session: FocusSession
    @State private var completed = 0

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "figure.strengthtraining.functional")
                .font(.system(size: 72))
                .foregroundStyle(.orange)
            Text("该活动一下了")
                .font(.largeTitle.bold())
            Text("完成 \(session.pushUpTarget) 个俯卧撑后继续")
                .font(.title3)
            Text("\(completed) / \(session.pushUpTarget)")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
            ProgressView(value: Double(completed), total: Double(session.pushUpTarget))
                .tint(.orange)

            Button(completed >= session.pushUpTarget ? "完成任务" : "记录一次俯卧撑") {
                if completed < session.pushUpTarget {
                    completed += 1
                } else {
                    session.finish()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!session.hasActivity)
            Spacer()
            Text("当前为演示计数按钮；摄像头自动计数尚未接入。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .navigationTitle("俯卧撑任务")
    }
}
