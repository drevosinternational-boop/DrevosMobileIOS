import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case home = "Main"
    case recipes = "Recipes"
    case instructions = "Instruction"
    case settings = "Settings"
    case devices = "Devices"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .home: return "house"
        case .recipes: return "square.fill"
        case .instructions: return "questionmark"
        case .settings: return "gearshape.fill"
        case .devices: return "rectangle.3.group"
        }
    }
}
