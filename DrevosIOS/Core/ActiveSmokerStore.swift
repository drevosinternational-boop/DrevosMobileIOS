import Foundation
import FirebaseAuth

@MainActor
final class ActiveSmokerStore: ObservableObject {
    static let shared = ActiveSmokerStore()

    @Published private(set) var smokerId: String?

    private var authHandle: AuthStateDidChangeListenerHandle?
    private var uid: String?

    private init() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.switchUser(user?.uid)
            }
        }
        switchUser(Auth.auth().currentUser?.uid)
    }

    deinit {
        if let authHandle { Auth.auth().removeStateDidChangeListener(authHandle) }
    }

    func select(_ id: String?) {
        let clean = id?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = (clean?.isEmpty == false) ? clean : nil
        smokerId = normalized

        guard let uid else { return }
        let key = preferenceKey(uid)
        if let normalized {
            UserDefaults.standard.set(normalized, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    func reconcile(_ ids: [String]) {
        let clean = ids.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        if let smokerId, clean.contains(smokerId) { return }
        select(clean.first)
    }

    func requireSmokerId() throws -> String {
        guard let smokerId, !smokerId.isEmpty else {
            throw NSError(domain: "Drevos", code: 1001, userInfo: [NSLocalizedDescriptionKey: "No smoker is selected. Choose a smoker on the Devices page."])
        }
        return smokerId
    }

    private func switchUser(_ newUid: String?) {
        let normalized = newUid?.trimmingCharacters(in: .whitespacesAndNewlines)
        uid = (normalized?.isEmpty == false) ? normalized : nil
        guard let uid else {
            smokerId = nil
            return
        }
        smokerId = UserDefaults.standard.string(forKey: preferenceKey(uid))
    }

    private func preferenceKey(_ uid: String) -> String { "active_smoker_id_\(uid)" }
}
