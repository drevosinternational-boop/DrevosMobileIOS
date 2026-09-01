import SwiftUI

struct ConnectionPanel: View {
    @ObservedObject var monitor = ConnectionMonitor.shared

    private var title: String {
        switch monitor.status {
        case .checking: return "Checking connection"
        case .connected: return "Smoker connected"
        case .unstable: return "Connection problem"
        case .smokerOffline: return "Smoker is offline"
        case .phoneOffline: return "No internet connection"
        }
    }

    private var description: String {
        switch monitor.status {
        case .checking:
            return "Checking the selected smoker's latest presence heartbeat."
        case .connected:
            return "Your smoker is connected and ready."
        case .unstable:
            return "Communication is temporarily delayed. The smoker is not marked offline unless a current Firebase connection confirms that its heartbeat is stale."
        case .smokerOffline:
            return "The smoker stopped sending presence/last_seen. Check power and the smoker's internet connection."
        case .phoneOffline:
            return "Your iPhone has no usable internet connection. Check Wi-Fi or mobile data."
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            if monitor.status == .checking {
                ProgressView().tint(DrevosTheme.orange).scaleEffect(1.2)
            } else {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 42, weight: .regular))
                    .foregroundStyle(DrevosTheme.orange)
            }
            Text(title).font(.system(size: 20, weight: .semibold)).foregroundStyle(DrevosTheme.text)
            Text(description).font(.system(size: 13)).foregroundStyle(DrevosTheme.muted).multilineTextAlignment(.center)

            if let age = monitor.ageSeconds, monitor.status == .unstable || monitor.status == .smokerOffline {
                Text(lastSeen(age)).font(.system(size: 12, weight: .medium)).foregroundStyle(DrevosTheme.text)
            }

            Button("Try again") { monitor.retry() }
                .fontWeight(.semibold).foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 46)
                .background(DrevosTheme.orange).clipShape(Capsule())
        }
        .padding(24)
        .background(DrevosTheme.panel2)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(DrevosTheme.border))
        .padding(.horizontal, 20)
    }

    private func lastSeen(_ seconds: Int64) -> String {
        if seconds < 2 { return "Last seen: just now" }
        if seconds < 60 { return "Last seen: \(seconds) seconds ago" }
        if seconds < 3600 { return "Last seen: \(seconds / 60) min ago" }
        if seconds < 86400 { return "Last seen: \(seconds / 3600) hr ago" }
        return "Last seen: \(seconds / 86400) days ago"
    }
}
