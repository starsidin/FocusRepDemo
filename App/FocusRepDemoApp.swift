import SwiftUI

@main
struct FocusRepDemoApp: App {
    @StateObject private var session = FocusSession()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)
                .onOpenURL { url in
                    if url.scheme == "focusrep", url.host == "challenge" {
                        session.showChallenge = true
                    }
                }
        }
    }
}
