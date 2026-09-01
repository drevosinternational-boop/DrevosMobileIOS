import SwiftUI

struct RecipeEditorView: View {
    @ObservedObject var model: RecipesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var draft: SmokerRecipe
    @State private var stageIndex = 0
    @State private var tagsText: String
    @State private var saving = false

    init(model: RecipesViewModel, recipe: SmokerRecipe?) {
        self.model = model
        var initial = recipe ?? SmokerRecipe(stages: [RecipeStage()])
        if initial.isPreset {
            initial.id = ""
            initial.favorite = false
            initial.updatedAt = 0
        }
        if initial.stages.isEmpty { initial.stages = [RecipeStage()] }
        _draft = State(initialValue: initial)
        _tagsText = State(initialValue: initial.tags.joined(separator: ", "))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Recipe") {
                    TextField("Recipe name", text: $draft.name)
                    TextField("Description", text: $draft.description, axis: .vertical).lineLimit(3...6)
                    TextField("Tags, comma separated", text: $tagsText)
                }

                Section("Stages") {
                    Picker("Stage", selection: $stageIndex) {
                        ForEach(draft.stages.indices, id: \.self) { i in Text("\(i + 1)").tag(i) }
                    }.pickerStyle(.segmented)

                    if draft.stages.indices.contains(stageIndex) {
                        StageEditor(stage: $draft.stages[stageIndex])
                    }

                    HStack {
                        Button("+ Add stage") { draft.stages.append(RecipeStage()); stageIndex = draft.stages.count - 1 }
                        Spacer()
                        Button("Delete stage", role: .destructive) {
                            guard draft.stages.count > 1 else { return }
                            draft.stages.remove(at: stageIndex)
                            stageIndex = min(stageIndex, draft.stages.count - 1)
                        }.disabled(draft.stages.count <= 1)
                    }
                }

                if !draft.id.isEmpty {
                    Section {
                        Button("Delete recipe", role: .destructive) {
                            Task { if await model.delete(draft) { dismiss() } }
                        }
                    }
                }
            }
            .navigationTitle(draft.id.isEmpty ? "New recipe" : "Edit recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saving ? "Saving…" : "Save") {
                        guard !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                            model.errorMessage = "Recipe name is required."; return
                        }
                        saving = true
                        draft.tags = tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                        Task {
                            if let saved = await model.save(draft) {
                                model.selectedId = saved.id
                                dismiss()
                            }
                            saving = false
                        }
                    }.disabled(saving)
                }
            }
        }
    }
}

private struct StageEditor: View {
    @Binding var stage: RecipeStage
    private let types = ["Drying", "Smoking", "Hold", "Steam", "Cooking"]

    var body: some View {
        Picker("Type", selection: $stage.type) { ForEach(types, id: \.self) { Text($0) } }
        Stepper("Duration: \(stage.durationMinutes) min", value: $stage.durationMinutes, in: 0...1440, step: 5)
        Stepper("Chamber: \(stage.chamberTempC)°C", value: $stage.chamberTempC, in: 0...120)
        Stepper("Product: \(stage.productTempC)°C", value: $stage.productTempC, in: 0...100)
        VStack(alignment: .leading) {
            Text("Smoke: \(stage.smokeLevel)%")
            Slider(value: Binding(get: { Double(stage.smokeLevel) }, set: { stage.smokeLevel = Int($0.rounded()) }), in: 0...100, step: 1).tint(DrevosTheme.orange)
        }
    }
}
