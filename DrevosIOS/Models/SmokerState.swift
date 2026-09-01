import Foundation

struct SmokerState: Equatable {
    var chamberTemperature: Double = 0
    var productTemperature: Double = 0
    var targetChamberTemperature: Double = 0
    var targetProductTemperature: Double = 0
    var heatingPower: Int = 0
    var smokeLevel: Int = 0
    var heatingEnabled = false
    var dryingEnabled = false
    var convectionEnabled = false
    var lightEnabled = false
    var steamEnabled = false
    var timer: Int64 = 0
}
