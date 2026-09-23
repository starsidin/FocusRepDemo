import ActivityKit
import SwiftUI
import WidgetKit

@main
struct FocusRepWidgetBundle: WidgetBundle {
    var body: some Widget {
        FocusRepLiveActivity()
    }
}

struct FocusRepLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            lockScreenView(context: context)
                .activityBackgroundTint(.black)
                .activitySystemActionForegroundColor(.white)
                .widgetURL(URL(string: "focusrep://challenge"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("放下手机", systemImage: "hand.raised.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    countdown(context: context)
                        .monospacedDigit()
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("倒计时结束后，完成 \(context.state.pushUpTarget) 个俯卧撑")
                            .font(.caption)
                        ProgressView(
                            timerInterval: context.state.startedAt...context.state.endsAt,
                            countsDown: false
                        )
                        .tint(.orange)
                    }
                    .padding(.top, 6)
                }
            } compactLeading: {
                Image(systemName: "hand.raised.fill")
                    .foregroundStyle(.orange)
            } compactTrailing: {
                countdown(context: context)
                    .monospacedDigit()
                    .font(.caption2)
                    .frame(maxWidth: 55)
            } minimal: {
                Image(systemName: "hand.raised.fill")
                    .foregroundStyle(.orange)
            }
            .widgetURL(URL(string: "focusrep://challenge"))
        }
    }

    private func countdown(context: ActivityViewContext<FocusActivityAttributes>) -> some View {
        Text(
            timerInterval: context.state.startedAt...context.state.endsAt,
            countsDown: true,
            showsHours: false
        )
    }

    private func lockScreenView(context: ActivityViewContext<FocusActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("放下手机，做组俯卧撑", systemImage: "hand.raised.fill")
                .font(.headline)
            countdown(context: context)
                .font(.title.bold())
                .monospacedDigit()
            ProgressView(
                timerInterval: context.state.startedAt...context.state.endsAt,
                countsDown: false
            )
            .tint(.orange)
        }
        .padding()
    }
}
