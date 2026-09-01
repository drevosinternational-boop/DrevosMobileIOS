import SwiftUI

struct AppRootView: View {
    @ObservedObject var auth: AuthSession

    var body: some View {
        Group {
            if auth.user == nil {
                LoginView(auth: auth)
            } else {
                MainShell(auth: auth)
            }
        }
    }
}

private struct MainShell: View {
    @ObservedObject var auth: AuthSession
    @State private var selected: AppTab = .home

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selected {
                case .home:
                    HomeView()
                case .recipes:
                    RecipesView()
                case .instructions:
                    InstructionsView()
                case .settings:
                    SettingsView(auth: auth)
                case .devices:
                    DevicesView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            BottomTabBar(selected: $selected)
        }
        .background(DrevosTheme.background.ignoresSafeArea())
    }
}
