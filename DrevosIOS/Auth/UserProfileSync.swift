import Foundation
import FirebaseAuth

actor UserProfileSync {
    static let shared = UserProfileSync()

    func sync(_ user: User) async {
        let uid = user.uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uid.isEmpty else { return }

        let ref = FirebaseConfig.root.child("users").child(uid)
        let now = Int64(Date().timeIntervalSince1970 * 1000.0)

        var updates: [String: Any] = ["last_login_at": now]
        if let email = user.email, !email.isEmpty { updates["email"] = email }
        if let name = user.displayName, !name.isEmpty { updates["name"] = name }
        if let photo = user.photoURL?.absoluteString, !photo.isEmpty { updates["photo_url"] = photo }

        do {
            let created = try await ref.child("created_at").getData()
            if !created.exists() { updates["created_at"] = now }
            try await ref.updateChildValues(updates)
        } catch {
            print("User profile sync failed: \(error)")
        }
    }
}
