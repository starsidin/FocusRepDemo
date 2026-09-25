import ActivityKit
import Foundation
import Security
import SwiftUI

@MainActor
final class FocusSession: ObservableObject {
    @Published var showChallenge = false
    @Published private(set) var endsAt: Date?
    @Published private(set) var pushUpTarget = 8
    @Published private(set) var errorMessage: String?
    @Published private(set) var restEndsAt: Date?
    @Published private(set) var hasStopPassword = StopPasswordStore.load() != nil
    @Published private(set) var failedStopAttempts = UserDefaults.standard.integer(forKey: "failedStopAttempts")

    @Published var selectedControlMinutes = 30
    private var restTask: Task<Void, Never>?
    private var activityTask: Task<Void, Never>?
    private var generation = UUID()

    init() {
        if let active = Activity<FocusActivityAttributes>.activities.first {
            endsAt = active.content.state.endsAt
            pushUpTarget = active.content.state.pushUpTarget
        }
    }

    var hasActivity: Bool {
        !Activity<FocusActivityAttributes>.activities.isEmpty
    }

    enum PasswordCheck {
        case accepted
        case incorrect(remaining: Int)
        case resetRequired
    }

    func setStopPassword(_ password: String) -> Bool {
        guard password.count == 6,
              password.utf8.allSatisfy({ (48...57).contains($0) }),
              StopPasswordStore.save(password) else {
            errorMessage = "请设置 6 位数字密码。"
            return false
        }
        hasStopPassword = true
        failedStopAttempts = 0
        UserDefaults.standard.set(0, forKey: "failedStopAttempts")
        return true
    }

    func checkStopPassword(_ password: String) -> PasswordCheck {
        guard let saved = StopPasswordStore.load() else {
            hasStopPassword = false
            return .resetRequired
        }
        if password == saved {
            failedStopAttempts = 0
            UserDefaults.standard.set(0, forKey: "failedStopAttempts")
            return .accepted
        }
        failedStopAttempts += 1
        UserDefaults.standard.set(failedStopAttempts, forKey: "failedStopAttempts")
        if failedStopAttempts >= 5 {
            StopPasswordStore.delete()
            hasStopPassword = false
            failedStopAttempts = 0
            UserDefaults.standard.set(0, forKey: "failedStopAttempts")
            return .resetRequired
        }
        return .incorrect(remaining: 5 - failedStopAttempts)
    }

    func start() {
        errorMessage = nil
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            errorMessage = "请在 iPhone 设置中允许此 App 的实时活动。"
            return
        }

        restTask?.cancel()
        restTask = nil
        restEndsAt = nil
        activityTask?.cancel()
        let requestGeneration = UUID()
        generation = requestGeneration
        let now = Date()
        let actualMinutes = selectedControlMinutes == 60 ? 1 : 30
        let end = now.addingTimeInterval(TimeInterval(actualMinutes * 60))
        let state = FocusActivityAttributes.ContentState(
            startedAt: now,
            endsAt: end,
            pushUpTarget: pushUpTarget
        )

        activityTask = Task {
            for activity in Activity<FocusActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            guard !Task.isCancelled, generation == requestGeneration else { return }
            do {
                let activity = try Activity.request(
                    attributes: FocusActivityAttributes(sessionID: UUID().uuidString),
                    content: ActivityContent(state: state, staleDate: nil),
                    pushType: nil
                )
                if Task.isCancelled || generation != requestGeneration {
                    await activity.end(nil, dismissalPolicy: .immediate)
                    return
                }
                endsAt = end
            } catch {
                if generation == requestGeneration {
                    errorMessage = "无法启动灵动岛：\(error.localizedDescription)"
                }
            }
        }
    }

    func completeChallenge() {
        guard hasActivity, restTask == nil else { return }
        let currentGeneration = generation
        restEndsAt = Date().addingTimeInterval(10)
        restTask = Task {
            do {
                try await Task.sleep(for: .seconds(10))
            } catch {
                return
            }
            guard generation == currentGeneration else { return }
            restTask = nil
            restEndsAt = nil
            start()
            showChallenge = false
        }
    }

    func finish() {
        generation = UUID()
        restTask?.cancel()
        restTask = nil
        restEndsAt = nil
        activityTask?.cancel()
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

private enum StopPasswordStore {
    private static let service = "com.focusrep.demo.app.stop-control"
    private static let account = "stop-password"

    private static var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }

    static func load() -> String? {
        var search = query
        search[kSecReturnData as String] = true
        search[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(search as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func save(_ password: String) -> Bool {
        let data = Data(password.utf8)
        if load() != nil {
            return SecItemUpdate(query as CFDictionary,
                                 [kSecValueData as String: data] as CFDictionary) == errSecSuccess
        }
        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        return SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess
    }

    static func delete() {
        SecItemDelete(query as CFDictionary)
    }
}
