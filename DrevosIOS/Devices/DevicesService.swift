import Foundation
import FirebaseAuth
import FirebaseDatabase

final class DevicesService {
    private let root = FirebaseConfig.root
    private var handle: DatabaseHandle?
    private var ref: DatabaseReference?
    private var authHandle: AuthStateDidChangeListenerHandle?

    func observe(
        onChange: @escaping ([DeviceItem]) -> Void,
        onError: @escaping (String) -> Void
    ) {
        stop()

        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            self.detachDatabaseObserver()

            guard let uid = user?.uid, !uid.isEmpty else {
                DispatchQueue.main.async { onChange([]) }
                return
            }

            let ref = self.root.child("users").child(uid).child("devices")
            self.ref = ref
            self.handle = ref.observe(.value, with: { snapshot in
                var devices: [DeviceItem] = []
                for case let child as DataSnapshot in snapshot.children {
                    let id = child.key.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !id.isEmpty else { continue }

                    if id.allSatisfy({ $0.isNumber }), let legacy = child.value as? String {
                        let legacyId = legacy.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !legacyId.isEmpty { devices.append(DeviceItem(id: legacyId, name: legacyId)) }
                        continue
                    }

                    let alias = (child.childSnapshot(forPath: "alias").value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    devices.append(DeviceItem(id: id, name: alias.isEmpty ? id : alias))
                }
                DispatchQueue.main.async { onChange(devices) }
            }, withCancel: { error in
                DispatchQueue.main.async { onError(error.localizedDescription) }
            })
        }
    }

    func addDevice(id rawId: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw DevicesError.signedOut }
        let id = rawId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { throw DevicesError.message("Enter a smoker ID") }

        let membership = root.child("users").child(uid).child("devices").child(id)
        let existing = try await membership.getData()
        if existing.exists() { throw DevicesError.message("This smoker is already connected") }

        let smoker = try await root.child("smokers").child(id).getData()
        guard smoker.exists() else { throw DevicesError.message("Smoker ID not found") }

        let name = ((smoker.childSnapshot(forPath: "name").value as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Int64(Date().timeIntervalSince1970 * 1000.0)
        try await membership.setValue([
            "alias": name.isEmpty ? id : name,
            "linked_at": now
        ])
    }

    func renameDevice(id: String, name rawName: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw DevicesError.signedOut }
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw DevicesError.message("Device name cannot be empty") }
        try await root.child("users").child(uid).child("devices").child(id).child("alias").setValue(name)
    }

    func removeDevice(id: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw DevicesError.signedOut }
        try await root.child("users").child(uid).child("devices").child(id).removeValue()
    }

    func stop() {
        detachDatabaseObserver()
        if let authHandle { Auth.auth().removeStateDidChangeListener(authHandle) }
        authHandle = nil
    }

    private func detachDatabaseObserver() {
        if let ref, let handle { ref.removeObserver(withHandle: handle) }
        ref = nil
        handle = nil
    }
}

enum DevicesError: LocalizedError {
    case signedOut
    case message(String)

    var errorDescription: String? {
        switch self {
        case .signedOut: return "Sign in again."
        case .message(let text): return text
        }
    }
}
