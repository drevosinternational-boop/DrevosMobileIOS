import Foundation
import Network
import FirebaseDatabase

@MainActor
final class ConnectionMonitor: ObservableObject {
    static let shared = ConnectionMonitor()

    enum Status: Equatable {
        case checking
        case connected
        case unstable
        case smokerOffline
        case phoneOffline
    }

    @Published private(set) var status: Status = .checking
    @Published private(set) var lastSeenAt: Int64 = 0
    @Published private(set) var ageSeconds: Int64?
    @Published private(set) var smokerId: String?

    private let root = FirebaseConfig.root
    private let pathMonitor = NWPathMonitor()
    private let pathQueue = DispatchQueue(label: "drevos.network.path")

    private var phoneOnline = true
    private var firebaseConnected: Bool?
    private var infoRef: DatabaseReference?
    private var infoHandle: DatabaseHandle?
    private var heartbeatRef: DatabaseReference?
    private var heartbeatHandle: DatabaseHandle?
    private var timer: Timer?

    private init() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.phoneOnline = path.status == .satisfied
                self?.recompute()
            }
        }
        pathMonitor.start(queue: pathQueue)
    }

    func start(smokerId: String?) {
        stopFirebaseObservers()
        self.smokerId = smokerId
        lastSeenAt = 0
        ageSeconds = nil
        firebaseConnected = nil
        status = .checking

        guard let smokerId, !smokerId.isEmpty else { return }

        let info = Database.database(url: FirebaseConfig.databaseURL).reference(withPath: ".info/connected")
        infoRef = info
        infoHandle = info.observe(.value) { [weak self] snapshot in
            Task { @MainActor in
                self?.firebaseConnected = snapshot.value as? Bool ?? false
                self?.recompute()
            }
        }

        let heartbeat = root.child("smokers").child(smokerId).child("presence").child("last_seen")
        heartbeatRef = heartbeat
        heartbeatHandle = heartbeat.observe(.value) { [weak self] snapshot in
            Task { @MainActor in
                self?.lastSeenAt = int64(snapshot.value)
                self?.recompute()
            }
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.recompute() }
        }
    }

    func retry() {
        start(smokerId: smokerId)
    }

    var canControl: Bool { status == .connected }

    func canControl(smokerId: String) -> Bool {
        self.smokerId == smokerId && status == .connected
    }

    private func recompute() {
        guard smokerId != nil else {
            status = .checking
            ageSeconds = nil
            return
        }

        if !phoneOnline {
            status = .phoneOffline
            ageSeconds = age(for: lastSeenAt)
            return
        }

        guard let firebaseConnected else {
            status = .checking
            ageSeconds = age(for: lastSeenAt)
            return
        }

        guard firebaseConnected else {
            // Firebase reconnecting is not proof that the physical smoker is offline.
            status = .unstable
            ageSeconds = age(for: lastSeenAt)
            return
        }

        guard lastSeenAt > 0 else {
            status = .checking
            ageSeconds = nil
            return
        }

        let ageMs = max(0, Int64(Date().timeIntervalSince1970 * 1000.0) - lastSeenAt)
        ageSeconds = ageMs / 1000
        if ageMs <= 15_000 {
            status = .connected
        } else if ageMs <= 30_000 {
            status = .unstable
        } else {
            status = .smokerOffline
        }
    }

    private func age(for timestamp: Int64) -> Int64? {
        guard timestamp > 0 else { return nil }
        return max(0, Int64(Date().timeIntervalSince1970 * 1000.0) - timestamp) / 1000
    }

    private func stopFirebaseObservers() {
        if let infoRef, let infoHandle { infoRef.removeObserver(withHandle: infoHandle) }
        if let heartbeatRef, let heartbeatHandle { heartbeatRef.removeObserver(withHandle: heartbeatHandle) }
        infoRef = nil; infoHandle = nil; heartbeatRef = nil; heartbeatHandle = nil
        timer?.invalidate(); timer = nil
    }
}
