import SwiftUI
import GoogleSignIn

@main
struct DrevosIOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var auth = AuthSession.shared

    var body: some Scene {
        WindowGroup {
            AppRootView(auth: auth)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    _ = GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
