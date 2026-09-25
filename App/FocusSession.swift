import ActivityKit
import Foundation
import SwiftUI

@MainActor
final class FocusSession: ObservableObject {
    @Published var showChallenge = false
    @Published private(set) var endsAt: Date?
    @Published private(set) var pushUpTarget = 8
    @Published private(set) var errorMessage: String?

    @Published var selectedControlMinutes = 30

    init() {
        if let active = Activity<FocusActivityAttributes>.activities.first {
            endsAt = active.content.state.endsAt
            pushUpTarget = active.content.state.pushUpTarget
        }
    }

    var hasActivity: Bool {
        !Activity<FocusActivityAttributes>.activities.isEmpty
    }

    func start() {
        errorMessage = nil
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            errorMessage = "请在 iPhone 设置中允许此 App 的实时活动。"
            return
        }

        let now = Date()
        let actualMinutes = selectedControlMinutes == 60 ? 1 : 30
        let end = now.addingTimeInterval(TimeInterval(actualMinutes * 60))
        let state = FocusActivityAttributes.ContentState(
            startedAt: now,
            endsAt: end,
            pushUpTarget: pushUpTarget
        )

        Task {
            for activity in Activity<FocusActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            do {
                _ = try Activity.request(
                    attributes: FocusActivityAttributes(sessionID: UUID().uuidString),
                    content: ActivityContent(state: state, staleDate: nil),
                    pushType: nil
                )
                endsAt = end
            } catch {
                errorMessage = "无法启动灵动岛：\(error.localizedDescription)"
            }
        }
    }

    func finish() {
        Task {
            for activity in Activity<FocusActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            endsAt = nil
            showChallenge = false
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
