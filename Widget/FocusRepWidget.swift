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
                    Label("活动一下", systemImage: "figure.strengthtraining.functional")
                        .font(.headline)
                        .foregroundStyle(Color(red: 0.42, green: 0.96, blue: 0.77))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    countdown(context: context)
                        .monospacedDigit()
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("屏幕时间结束后，完成 \(context.state.pushUpTarget) 次下蹲")
                            .font(.caption)
                        ProgressView(
                            timerInterval: context.state.startedAt...context.state.endsAt,
                            countsDown: false
                        )
                        .tint(Color(red: 0.42, green: 0.96, blue: 0.77))
                    }
                    .padding(.top, 6)
                }
            } compactLeading: {
                Image(systemName: "figure.strengthtraining.functional")
                    .foregroundStyle(Color(red: 0.42, green: 0.96, blue: 0.77))
            } compactTrailing: {
                countdown(context: context)
                    .monospacedDigit()
                    .font(.caption2)
                    .frame(maxWidth: 55)
            } minimal: {
                Image(systemName: "figure.strengthtraining.functional")
                    .foregroundStyle(Color(red: 0.42, green: 0.96, blue: 0.77))
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
            Label("放下手机，做组下蹲", systemImage: "figure.strengthtraining.functional")
                .font(.headline)
            countdown(context: context)
                .font(.title.bold())
                .monospacedDigit()
            ProgressView(
                timerInterval: context.state.startedAt...context.state.endsAt,
                countsDown: false
            )
            .tint(Color(red: 0.42, green: 0.96, blue: 0.77))
        }
        .padding()
    }
}
