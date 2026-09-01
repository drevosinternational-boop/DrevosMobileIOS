import SwiftUI

struct HomeView: View {
    @StateObject private var model = HomeViewModel()
    @ObservedObject private var active = ActiveSmokerStore.shared
    @ObservedObject private var connection = ConnectionMonitor.shared
    @ObservedObject private var settings = AppSettings.shared
    @State private var chamberSheet = false
    @State private var productSheet = false
    @State private var smokeSheet = false

    var body: some View {
        ZStack {
            DrevosTheme.background.ignoresSafeArea()
            if active.smokerId == nil {
                ConnectionPanel()
            } else if !settings.testingMode && connection.status != .connected {
                ConnectionPanel()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Main").font(.system(size: 24, weight: .semibold)).foregroundStyle(DrevosTheme.text)
                            Spacer()
                            if let id = active.smokerId { Text(id).font(.caption).foregroundStyle(DrevosTheme.muted) }
                        }

                        if let error = model.errorMessage {
                            Text(error).font(.caption).foregroundStyle(.red).frame(maxWidth: .infinity, alignment: .leading)
                        }

                        HStack(spacing: 12) {
                            TemperatureCard(title: "CHAMBER", value: display(model.state.chamberTemperature), target: display(model.state.targetChamberTemperature), unit: settings.temperatureUnit.symbol) { chamberSheet = true }
                            TemperatureCard(title: "PRODUCT", value: display(model.state.productTemperature), target: display(model.state.targetProductTemperature), unit: settings.temperatureUnit.symbol) { productSheet = true }
                        }

                        if model.runtime.running {
                            CurrentRecipeCard(runtime: model.runtime, stop: model.stopRecipe)
                        }

                        HStack(spacing: 10) {
                            ControlCard(title: "HEAT", active: model.state.heatingEnabled, value: "\(model.state.heatingPower)%", action: model.toggleHeating)
                            ControlCard(title: "DRYING", active: model.state.dryingEnabled, value: model.state.dryingEnabled ? "ON" : "OFF", action: model.toggleDrying)
                        }
                        HStack(spacing: 10) {
                            ControlCard(title: "LED", active: model.state.lightEnabled, value: model.state.lightEnabled ? "ON" : "OFF", action: model.toggleLight)
                            ControlCard(title: "CONVECTION", active: model.state.convectionEnabled, value: model.state.convectionEnabled ? "ON" : "OFF", action: model.toggleConvection)
                        }

                        Button { smokeSheet = true } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("SMOKE").font(.system(size: 14, weight: .bold))
                                    Text("\(model.state.smokeLevel)%").font(.system(size: 22, weight: .semibold))
                                }
                                Spacer()
                                Text("SET").font(.system(size: 12, weight: .bold)).padding(.horizontal, 15).padding(.vertical, 8).background(Color.white).foregroundStyle(Color.black).clipShape(Capsule())
                            }
                            .foregroundStyle(DrevosTheme.text).padding(16).frame(maxWidth: .infinity)
                            .background(model.state.smokeLevel > 0 ? DrevosTheme.selected : DrevosTheme.panel)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(model.state.smokeLevel > 0 ? DrevosTheme.orange : DrevosTheme.border))
                        }
                    }
                    .padding(14)
                }
            }
        }
        .sheet(isPresented: $chamberSheet) {
            TemperatureSetter(title: "Chamber temperature", initial: display(model.state.targetChamberTemperature), unit: settings.temperatureUnit.symbol, range: settings.temperatureUnit == .celsius ? 0...120 : 32...248) { model.setTargetChamber($0) }
        }
        .sheet(isPresented: $productSheet) {
            TemperatureSetter(title: "Product temperature", initial: display(model.state.targetProductTemperature), unit: settings.temperatureUnit.symbol, range: settings.temperatureUnit == .celsius ? 0...100 : 32...212) { model.setTargetProduct($0) }
        }
        .sheet(isPresented: $smokeSheet) {
            SmokeSetter(initial: model.state.smokeLevel, save: model.setSmoke)
        }
    }

    private func display(_ value: Double) -> Int { settings.displayTemperature(fromFirebase: value) }
}

private struct TemperatureCard: View {
    let title: String; let value: Int; let target: Int; let unit: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title).font(.caption).fontWeight(.bold).foregroundStyle(DrevosTheme.muted)
                Text("\(value)\(unit)").font(.system(size: 31, weight: .semibold)).foregroundStyle(DrevosTheme.text)
                Text("SET TO  \(target)\(unit)").font(.caption).foregroundStyle(DrevosTheme.orange)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(16)
            .background(DrevosTheme.panel).clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(DrevosTheme.border))
        }
    }
}

private struct ControlCard: View {
    let title: String; let active: Bool; let value: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.system(size: 13, weight: .bold))
                Text(value).font(.system(size: 20, weight: .semibold))
            }
            .foregroundStyle(DrevosTheme.text).frame(maxWidth: .infinity, alignment: .leading).padding(16).frame(height: 82)
            .background(active ? DrevosTheme.selected : DrevosTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(active ? DrevosTheme.orange : DrevosTheme.border))
        }
    }
}

private struct CurrentRecipeCard: View {
    let runtime: CurrentRecipeRuntime; let stop: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Text("Current Recipe").fontWeight(.semibold); Spacer(); Button("Stop", role: .destructive, action: stop) }
            Text(runtime.recipeId.isEmpty ? "Running recipe" : runtime.recipeId).foregroundStyle(DrevosTheme.muted)
            if runtime.stageIndex >= 0 { Text("STAGE \(runtime.stageIndex + 1)").font(.caption).foregroundStyle(DrevosTheme.orange) }
        }
        .foregroundStyle(DrevosTheme.text).padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(DrevosTheme.panel).clipShape(RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).stroke(DrevosTheme.border))
    }
}

private struct TemperatureSetter: View {
    let title: String; let initial: Int; let unit: String; let range: ClosedRange<Int>; let save: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var value: Double
    init(title: String, initial: Int, unit: String, range: ClosedRange<Int>, save: @escaping (Int) -> Void) {
        self.title = title; self.initial = initial; self.unit = unit; self.range = range; self.save = save
        _value = State(initialValue: Double(initial))
    }
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("\(Int(value.rounded()))\(unit)").font(.system(size: 44, weight: .semibold))
                Slider(value: $value, in: Double(range.lowerBound)...Double(range.upperBound), step: 1).tint(DrevosTheme.orange)
                Spacer()
            }.padding(24).navigationTitle(title).toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save(Int(value.rounded())); dismiss() } }
            }
        }.presentationDetents([.medium])
    }
}

private struct SmokeSetter: View {
    let initial: Int; let save: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var value: Double
    init(initial: Int, save: @escaping (Int) -> Void) { self.initial = initial; self.save = save; _value = State(initialValue: Double(initial)) }
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("\(Int(value.rounded()))%").font(.system(size: 44, weight: .semibold))
                Slider(value: $value, in: 0...100, step: 1).tint(DrevosTheme.orange)
                Spacer()
            }.padding(24).navigationTitle("Smoke level").toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save(Int(value.rounded())); dismiss() } }
            }
        }.presentationDetents([.medium])
    }
}
