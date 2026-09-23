import ActivityKit
import Foundation

struct FocusActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let startedAt: Date
        let endsAt: Date
        let pushUpTarget: Int
    }

    let sessionID: String
}
