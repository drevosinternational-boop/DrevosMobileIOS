import SwiftUI

struct RecipesView: View {
    @StateObject private var model = RecipesViewModel()
    @State private var details: SmokerRecipe?
    @State private var editorRecipe: SmokerRecipe?
    @State private var showEditor = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            DrevosTheme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 12) {
                Text("Recipes").font(.system(size: 27, weight: .semibold)).foregroundStyle(DrevosTheme.text)
                Text("\(model.recipes.count) saved recipes").font(.system(size: 12)).foregroundStyle(DrevosTheme.muted)

                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(DrevosTheme.muted)
                    TextField("Search recipes, meat, fish...", text: $model.query).foregroundStyle(DrevosTheme.text)
                }
                .padding(.horizontal, 14).frame(height: 46).background(DrevosTheme.panel).clipShape(RoundedRectangle(cornerRadius: 13)).overlay(RoundedRectangle(cornerRadius: 13).stroke(DrevosTheme.border))

                HStack {
                    FilterPill(title: "All", active: !model.favoritesOnly) { model.favoritesOnly = false }
                    FilterPill(title: "Favorites", active: model.favoritesOnly) { model.favoritesOnly = true }
                }

                if let error = model.errorMessage { Text(error).font(.caption).foregroundStyle(.red) }
                if let info = model.infoMessage { Text(info).font(.caption).foregroundStyle(.green) }

                if model.isLoading {
                    Spacer(); ProgressView().tint(DrevosTheme.orange).frame(maxWidth: .infinity); Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(model.visible) { recipe in
                                RecipeCard(
                                    recipe: recipe,
                                    selected: model.selectedId == recipe.id,
                                    select: { model.selectedId = recipe.id },
                                    open: { details = recipe },
                                    favorite: { model.toggleFavorite(recipe) },
                                    start: { model.start(recipe) }
                                )
                            }
                            if model.visible.count < model.filtered.count {
                                Button("Load 20 more recipes") { model.loadMore() }
                                    .foregroundStyle(DrevosTheme.text).frame(maxWidth: .infinity).frame(height: 42)
                                    .background(DrevosTheme.panel).clipShape(Capsule()).overlay(Capsule().stroke(DrevosTheme.border))
                            }
                        }
                        .padding(.bottom, 80)
                    }
                }
            }
            .padding(.horizontal, 12).padding(.top, 12)

            Button {
                editorRecipe = nil; showEditor = true
            } label: {
                Image(systemName: "plus").font(.system(size: 24, weight: .medium)).foregroundStyle(.white).frame(width: 56, height: 56).background(DrevosTheme.orange).clipShape(Circle())
            }
            .padding(.trailing, 18).padding(.bottom, 18)
        }
        .sheet(item: $details) { recipe in
            RecipeDetailsView(model: model, recipe: recipe, edit: {
                details = nil
                editorRecipe = recipe
                showEditor = true
            })
        }
        .sheet(isPresented: $showEditor) { RecipeEditorView(model: model, recipe: editorRecipe) }
    }
}

private struct RecipeCard: View {
    let recipe: SmokerRecipe; let selected: Bool; let select: () -> Void; let open: () -> Void; let favorite: () -> Void; let start: () -> Void
    var body: some View {
        HStack(spacing: 10) {
            RecipeImage(recipe: recipe).frame(width: 105, height: selected ? 126 : 108)
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text("\(recipe.stages.count) stages · \(duration(recipe.totalDurationMinutes))").font(.system(size: 9)).foregroundStyle(DrevosTheme.muted)
                    Spacer()
                    Button(action: favorite) { Image(systemName: recipe.favorite ? "star.fill" : "star").foregroundStyle(DrevosTheme.orange) }
                }
                Text(recipe.name.isEmpty ? "Unnamed Recipe" : recipe.name).font(.system(size: 15, weight: .semibold)).foregroundStyle(DrevosTheme.text).lineLimit(2)
                Text(recipe.tags.first ?? "Recipe").font(.system(size: 10)).foregroundStyle(DrevosTheme.muted)
                Spacer()
                HStack(spacing: 8) {
                    Button("Detail", action: open)
                        .font(.system(size: 12, weight: .medium)).foregroundStyle(selected ? .black : DrevosTheme.text)
                        .frame(maxWidth: .infinity).frame(height: 34).background(selected ? Color.white : DrevosTheme.panel2).clipShape(Capsule()).overlay(Capsule().stroke(DrevosTheme.border))
                    if selected {
                        Button("▶ Start", action: start).font(.system(size: 12, weight: .semibold)).foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 34).background(DrevosTheme.orange).clipShape(Capsule())
                    }
                }
            }.padding(.vertical, 7).padding(.trailing, 7)
        }
        .padding(6).frame(maxWidth: .infinity).frame(height: selected ? 140 : 122)
        .background(selected ? DrevosTheme.selected : DrevosTheme.panel).clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? DrevosTheme.orange : DrevosTheme.border, lineWidth: selected ? 1.5 : 1))
        .contentShape(Rectangle()).onTapGesture(perform: select)
    }

    private func duration(_ minutes: Int) -> String { "\(minutes / 60) hr \(minutes % 60) min" }
}

private struct RecipeImage: View {
    let recipe: SmokerRecipe
    var body: some View {
        AsyncImage(url: URL(string: recipe.imageUrl)) { phase in
            switch phase {
            case .success(let image): image.resizable().scaledToFill()
            default:
                ZStack { LinearGradient(colors: [Color(hex: 0x333333), .black], startPoint: .topLeading, endPoint: .bottomTrailing); Text(initials).font(.system(size: 24, weight: .medium)).foregroundStyle(.white) }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 11)).clipped()
    }
    private var initials: String { recipe.name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined() }
}

private struct FilterPill: View {
    let title: String; let active: Bool; let action: () -> Void
    var body: some View {
        Button(title, action: action).font(.system(size: 11, weight: .semibold)).foregroundStyle(.white).padding(.horizontal, 14).frame(height: 30).background(active ? DrevosTheme.orange : DrevosTheme.panel2).clipShape(Capsule()).overlay(Capsule().stroke(active ? DrevosTheme.orange : DrevosTheme.border))
    }
}

private struct RecipeDetailsView: View {
    @ObservedObject var model: RecipesViewModel
    let recipe: SmokerRecipe; let edit: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    RecipeImage(recipe: recipe).frame(maxWidth: .infinity).frame(height: 220)
                    Text(recipe.name).font(.title2).fontWeight(.semibold)
                    Text(recipe.description).foregroundStyle(.secondary)
                    ForEach(Array(recipe.stages.enumerated()), id: \.offset) { index, stage in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Stage \(index + 1) · \(stage.type)").fontWeight(.semibold)
                            Text("\(stage.durationMinutes) min · chamber \(stage.chamberTempC)°C · product \(stage.productTempC)°C · smoke \(stage.smokeLevel)%").font(.caption).foregroundStyle(.secondary)
                        }.padding(12).frame(maxWidth: .infinity, alignment: .leading).background(Color.white.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    HStack {
                        Button("Edit", action: edit).frame(maxWidth: .infinity).buttonStyle(.bordered)
                        Button("▶ Start") { model.start(recipe); dismiss() }.frame(maxWidth: .infinity).buttonStyle(.borderedProminent).tint(DrevosTheme.orange)
                    }
                }.padding()
            }
            .navigationTitle("Recipe")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button { model.toggleFavorite(recipe) } label: { Image(systemName: recipe.favorite ? "star.fill" : "star") } }
                ToolbarItem(placement: .topBarTrailing) { Button("Close") { dismiss() } }
            }
        }
    }
}
