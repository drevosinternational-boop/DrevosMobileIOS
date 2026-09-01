import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var state = SmokerState()
    @Published var runtime = CurrentRecipeRuntime()
    @Published var errorMessage: String?

    private let service = HomeService()
    private let active = ActiveSmokerStore.shared
    private let settings = AppSettings.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        active.$smokerId.sink { [weak self] id in self?.switchSmoker(id) }.store(in: &cancellables)
        switchSmoker(active.smokerId)
    }

    deinit { service.stop() }

    func toggleHeating() { set(field: "is_heating", value: !state.heatingEnabled) { state.heatingEnabled = $0 as? Bool ?? state.heatingEnabled } }
    func toggleDrying() { set(field: "is_drying", value: !state.dryingEnabled) { state.dryingEnabled = $0 as? Bool ?? state.dryingEnabled } }
    func toggleConvection() { set(field: "is_convection_fan_on", value: !state.convectionEnabled) { state.convectionEnabled = $0 as? Bool ?? state.convectionEnabled } }
    func toggleLight() { set(field: "is_light_on", value: !state.lightEnabled) { state.lightEnabled = $0 as? Bool ?? state.lightEnabled } }
    func setSmoke(_ level: Int) { set(field: "smoke_level", value: min(100, max(0, level))) { state.smokeLevel = $0 as? Int ?? state.smokeLevel } }
    func setTargetChamber(_ display: Int) { set(field: "target_camera_temp", value: settings.firebaseTemperature(fromDisplay: Double(display))) { state.targetChamberTemperature = Double($0 as? Int ?? Int(state.targetChamberTemperature)) } }
    func setTargetProduct(_ display: Int) { set(field: "target_product_temp", value: settings.firebaseTemperature(fromDisplay: Double(display))) { state.targetProductTemperature = Double($0 as? Int ?? Int(state.targetProductTemperature)) } }

    func stopRecipe() {
        guard let id = active.smokerId else { return }
        Task {
            do { try await service.stopRecipe(smokerId: id) }
            catch { errorMessage = error.localizedDescription }
        }
    }

    private func switchSmoker(_ id: String?) {
        service.stop()
        ConnectionMonitor.shared.start(smokerId: id)
        state = SmokerState(); runtime = CurrentRecipeRuntime(); errorMessage = nil
        guard let id else { return }
        service.observe(smokerId: id) { [weak self] state, runtime in
            self?.state = state; self?.runtime = runtime
        } onError: { [weak self] error in self?.errorMessage = error }
    }

    private func set(field: String, value: Any, localUpdate: @escaping (Any) -> Void) {
        if settings.testingMode {
            localUpdate(value)
            objectWillChange.send()
            return
        }
        guard let id = active.smokerId else { errorMessage = "No smoker selected"; return }
        guard ConnectionMonitor.shared.canControl(smokerId: id) else { errorMessage = "Smoker connection is not ready."; return }
        Task {
            do { try await service.setState(smokerId: id, field: field, value: value) }
            catch { errorMessage = error.localizedDescription }
        }
    }
}
