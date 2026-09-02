import Foundation
import Combine

@MainActor
final class DevicesViewModel: ObservableObject {
    @Published var devices: [DeviceItem] = []
    @Published var isLoading = true
    @Published var isWorking = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?

    let active = ActiveSmokerStore.shared
    private let service = DevicesService()

    init() {
        service.observe { [weak self] devices in
            guard let self else { return }
            self.devices = devices
            self.isLoading = false
            self.errorMessage = nil
            self.active.reconcile(devices.map(\.id))
        } onError: { [weak self] error in
            self?.isLoading = false
            self?.isWorking = false
            self?.errorMessage = error
        }
    }

    deinit { service.stop() }

    func select(_ id: String) { active.select(id) }

    func add(_ id: String) async -> Bool {
        await perform(success: "Smoker connected") { [self] in try await self.service.addDevice(id: id) }
    }

    func rename(_ device: DeviceItem, to name: String) async -> Bool {
        await perform(success: "Device name updated") { [self] in try await self.service.renameDevice(id: device.id, name: name) }
    }

    func remove(_ device: DeviceItem) async -> Bool {
        await perform(success: "Smoker removed from this account") { [self] in try await self.service.removeDevice(id: device.id) }
    }

    func clearMessage() { errorMessage = nil; infoMessage = nil }

    private func perform(success: String, operation: @escaping () async throws -> Void) async -> Bool {
        isWorking = true
        errorMessage = nil
        infoMessage = nil
        do {
            try await operation()
            isWorking = false
            infoMessage = success
            return true
        } catch {
            isWorking = false
            errorMessage = error.localizedDescription
            return false
        }
    }
}
