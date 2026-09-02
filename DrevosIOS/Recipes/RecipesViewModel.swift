import Foundation
import Combine

@MainActor
final class RecipesViewModel: ObservableObject {
    @Published var recipes: [SmokerRecipe] = []
    @Published var selectedId: String?
    @Published var query = ""
    @Published var favoritesOnly = false
    @Published var visibleCount = 20
    @Published var isLoading = true
    @Published var isWorking = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?

    let service = RecipeService()

    init() {
        service.observe { [weak self] recipes in
            self?.recipes = recipes
            self?.isLoading = false
            if let selected = self?.selectedId, !recipes.contains(where: { $0.id == selected }) { self?.selectedId = nil }
        } onError: { [weak self] error in
            self?.errorMessage = error; self?.isLoading = false
        }
    }

    deinit { service.stop() }

    var filtered: [SmokerRecipe] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return recipes.filter { recipe in
            if favoritesOnly && !recipe.favorite { return false }
            if q.isEmpty { return true }
            return recipe.name.lowercased().contains(q)
                || recipe.description.lowercased().contains(q)
                || recipe.tags.joined(separator: " ").lowercased().contains(q)
        }
    }

    var visible: [SmokerRecipe] { Array(filtered.prefix(visibleCount)) }

    func toggleFavorite(_ recipe: SmokerRecipe) {
        Task {
            do { try await self.service.setFavorite(recipeId: recipe.id, favorite: !recipe.favorite) }
            catch { self.errorMessage = error.localizedDescription }
        }
    }

    func start(_ recipe: SmokerRecipe) {
        isWorking = true; errorMessage = nil
        Task {
            do { try await self.service.start(recipe); self.infoMessage = "Recipe started" }
            catch { self.errorMessage = error.localizedDescription }
            self.isWorking = false
        }
    }

    func loadMore() { visibleCount += 20 }

    func save(_ recipe: SmokerRecipe) async -> SmokerRecipe? {
        do { return try await service.save(recipe) }
        catch { errorMessage = error.localizedDescription; return nil }
    }

    func delete(_ recipe: SmokerRecipe) async -> Bool {
        do { try await service.delete(recipe); return true }
        catch { errorMessage = error.localizedDescription; return false }
    }
}
