import SwiftUI

struct SettingsView: View {
    @ObservedObject var auth: AuthSession
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var active = ActiveSmokerStore.shared
    @State private var showSignOut = false

    var body: some View {
        ZStack {
            DrevosTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Settings").font(.system(size: 24, weight: .semibold)).foregroundStyle(DrevosTheme.text).frame(maxWidth: .infinity, alignment: .center)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("You are logged in as").font(.caption).foregroundStyle(DrevosTheme.muted)
                        Text(auth.user?.displayName ?? "Signed in").font(.system(size: 16, weight: .semibold)).foregroundStyle(DrevosTheme.text)
                        Text(auth.user?.email ?? "").font(.caption).foregroundStyle(DrevosTheme.muted)
                    }
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading).background(DrevosTheme.panel).clipShape(RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).stroke(DrevosTheme.border))

                    SectionHeader("General")
                    SettingsCard {
                        HStack {
                            Text("Temperature units").foregroundStyle(DrevosTheme.text)
                            Spacer()
                            Picker("Temperature", selection: $settings.temperatureUnit) {
                                Text("°C").tag(TemperatureUnit.celsius)
                                Text("°F").tag(TemperatureUnit.fahrenheit)
                            }.pickerStyle(.segmented).frame(width: 130)
                        }
                        Divider().overlay(DrevosTheme.border)
                        Toggle("Testing mode", isOn: $settings.testingMode).tint(DrevosTheme.orange).foregroundStyle(DrevosTheme.text)
                    }

                    SectionHeader("Notifications")
                    SettingsCard {
                        Toggle("Target temperature reached", isOn: $settings.notifyTargetReached).tint(DrevosTheme.orange).foregroundStyle(DrevosTheme.text)
                        Divider().overlay(DrevosTheme.border)
                        Toggle("Device disconnected", isOn: $settings.notifyDeviceDisconnected).tint(DrevosTheme.orange).foregroundStyle(DrevosTheme.text)
                    }

                    SectionHeader("Device")
                    SettingsCard {
                        HStack { Text("Selected smoker").foregroundStyle(DrevosTheme.text); Spacer(); Text(active.smokerId ?? "None").foregroundStyle(DrevosTheme.muted) }
                        Divider().overlay(DrevosTheme.border)
                        HStack { Text("Firmware version").foregroundStyle(DrevosTheme.text); Spacer(); Text("Not reported").foregroundStyle(DrevosTheme.muted) }
                    }

                    SectionHeader("Account")
                    SettingsCard {
                        Button("Sign out", role: .destructive) { showSignOut = true }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(14).padding(.bottom, 24)
            }
        }
        .confirmationDialog("Sign out?", isPresented: $showSignOut) {
            Button("Sign out", role: .destructive) { auth.signOut() }
            Button("Cancel", role: .cancel) { }
        }
    }
}

private struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View { Text(title.uppercased()).font(.system(size: 11, weight: .bold)).foregroundStyle(DrevosTheme.muted).padding(.top, 4) }
}

private struct SettingsCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        VStack(spacing: 13) { content }
            .font(.system(size: 13)).padding(15).frame(maxWidth: .infinity)
            .background(DrevosTheme.panel).clipShape(RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).stroke(DrevosTheme.border))
    }
}
