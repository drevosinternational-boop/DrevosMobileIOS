import Foundation

enum TemperatureUnit: String, CaseIterable, Identifiable {
    case celsius = "C"
    case fahrenheit = "F"

    var id: String { rawValue }
    var symbol: String { self == .celsius ? "°C" : "°F" }
}

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var temperatureUnit: TemperatureUnit {
        didSet { defaults.set(temperatureUnit.rawValue, forKey: "temperature_unit") }
    }

    @Published var testingMode: Bool {
        didSet { defaults.set(testingMode, forKey: "testing_mode") }
    }

    @Published var notifyDeviceDisconnected: Bool {
        didSet { defaults.set(notifyDeviceDisconnected, forKey: "notify_device_disconnected") }
    }

    @Published var notifyTargetReached: Bool {
        didSet { defaults.set(notifyTargetReached, forKey: "notify_target_reached") }
    }

    private let defaults = UserDefaults.standard

    private init() {
        temperatureUnit = TemperatureUnit(rawValue: defaults.string(forKey: "temperature_unit") ?? "C") ?? .celsius
        testingMode = defaults.bool(forKey: "testing_mode")
        notifyDeviceDisconnected = defaults.object(forKey: "notify_device_disconnected") as? Bool ?? true
        notifyTargetReached = defaults.object(forKey: "notify_target_reached") as? Bool ?? true
    }

    // Mirrors the current Android app's temperature conversion behavior.
    func displayTemperature(fromFirebase value: Double) -> Int {
        switch temperatureUnit {
        case .fahrenheit:
            return Int(value.rounded())
        case .celsius:
            return Int(((value - 32.0) * 5.0 / 9.0).rounded())
        }
    }

    func firebaseTemperature(fromDisplay value: Double) -> Int {
        switch temperatureUnit {
        case .fahrenheit:
            return Int(value.rounded())
        case .celsius:
            return Int((value * 9.0 / 5.0 + 32.0).rounded())
        }
    }
}
