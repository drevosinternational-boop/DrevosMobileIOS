import Foundation
import FirebaseAuth
import FirebaseDatabase

final class RecipeService {
    private let root = FirebaseConfig.root

    private var standardRef: DatabaseReference?
    private var standardHandle: DatabaseHandle?
    private var savedRef: DatabaseReference?
    private var savedHandle: DatabaseHandle?
    private var favoritesRef: DatabaseReference?
    private var favoritesHandle: DatabaseHandle?
    private var authHandle: AuthStateDidChangeListenerHandle?

    private var standard: [SmokerRecipe] = []
    private var saved: [SmokerRecipe] = []
    private var favorites: Set<String> = []
    private var onChange: (([SmokerRecipe]) -> Void)?
    private var onError: ((String) -> Void)?

    func observe(
        onChange: @escaping ([SmokerRecipe]) -> Void,
        onError: @escaping (String) -> Void
    ) {
        stop()
        self.onChange = onChange
        self.onError = onError

        let standardRef = root.child("standard_recipes")
        self.standardRef = standardRef
        standardHandle = standardRef.observe(.value, with: { [weak self] snapshot in
            self?.standard = Self.parseRecipeList(snapshot)
            self?.emit()
        }, withCancel: { [weak self] error in self?.fail(error) })

        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.attachUser(user?.uid)
        }
    }

    func stop() {
        if let standardRef, let standardHandle { standardRef.removeObserver(withHandle: standardHandle) }
        detachUser()
        if let authHandle { Auth.auth().removeStateDidChangeListener(authHandle) }
        standardRef = nil; standardHandle = nil; authHandle = nil
        onChange = nil; onError = nil
    }

    func save(_ recipe: SmokerRecipe) async throws -> SmokerRecipe {
        guard let uid = Auth.auth().currentUser?.uid else { throw RecipeError.message("Sign in again.") }
        let supplied = recipe.id.trimmingCharacters(in: .whitespacesAndNewlines)
        let id = supplied.isEmpty || supplied.hasPrefix("drevos_preset_") ? UUID().uuidString.lowercased() : supplied

        var normalized = recipe
        normalized.id = id
        normalized.favorite = false
        normalized.updatedAt = Int64(Date().timeIntervalSince1970 * 1000.0)
        normalized.version = max(2, normalized.version)

        try await root.child("users").child(uid).child("recipes").child("saved").child(id).setValue(normalized.firebaseMap())
        return normalized
    }

    func delete(_ recipe: SmokerRecipe) async throws {
        guard !recipe.isPreset else { throw RecipeError.message("Drevos presets cannot be deleted. Edit a preset to create a personal copy instead.") }
        guard let uid = Auth.auth().currentUser?.uid else { throw RecipeError.message("Sign in again.") }
        try await root.child("users").child(uid).child("recipes").child("saved").child(recipe.id).removeValue()
        try await setFavorite(recipeId: recipe.id, favorite: false)
    }

    func setFavorite(recipeId: String, favorite: Bool) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw RecipeError.message("Sign in again.") }
        let ref = root.child("users").child(uid).child("recipes").child("favorites")
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.runTransactionBlock({ currentData in
                var ids: [String] = []
                if let array = currentData.value as? [Any] {
                    ids = array.compactMap { $0 as? String }.filter { !$0.isEmpty }
                } else if let dictionary = currentData.value as? [String: Any] {
                    ids = dictionary.values.compactMap { $0 as? String }.filter { !$0.isEmpty }
                }
                var set = Set(ids)
                if favorite { set.insert(recipeId) } else { set.remove(recipeId) }
                currentData.value = Array(set).sorted()
                return TransactionResult.success(withValue: currentData)
            }, andCompletionBlock: { error, committed, _ in
                if let error { continuation.resume(throwing: error) }
                else if !committed { continuation.resume(throwing: RecipeError.message("Favorite update was not committed.")) }
                else { continuation.resume(returning: ()) }
            })
        }
    }

    func start(_ recipe: SmokerRecipe) async throws {
        let smokerId = try await MainActor.run {
            try ActiveSmokerStore.shared.requireSmokerId()
        }

        let controlState = await MainActor.run {
            (
                testingMode: AppSettings.shared.testingMode,
                canControl: ConnectionMonitor.shared.canControl(smokerId: smokerId)
            )
        }
        if controlState.testingMode { return }
        guard controlState.canControl else {
            throw RecipeError.message("Smoker connection is not ready.")
        }

        let current = root.child("smokers").child(smokerId).child("current_recipe")
        let runningSnapshot = try await current.child("running").getData()
        if runningSnapshot.value as? Bool == true {
            try await current.updateChildValues(["command/action": "end", "running": false])
            try await Task.sleep(nanoseconds: 500_000_000)
        }

        // The controller still expects the recipe under the selected smoker while executing.
        try await root.child("smokers").child(smokerId).child("saved_recipes").setValue([
            recipe.id: recipe.firebaseMap()
        ])

        try await current.updateChildValues([
            "command/action": "start",
            "command/recipe_id": recipe.id,
            "running": true
        ])
    }

    private func attachUser(_ uid: String?) {
        detachUser()
        saved = []; favorites = []; emit()
        guard let uid, !uid.isEmpty else { return }

        let savedRef = root.child("users").child(uid).child("recipes").child("saved")
        self.savedRef = savedRef
        savedHandle = savedRef.observe(.value, with: { [weak self] snapshot in
            self?.saved = Self.parseRecipeList(snapshot)
            self?.emit()
        }, withCancel: { [weak self] error in self?.fail(error) })

        let favoritesRef = root.child("users").child(uid).child("recipes").child("favorites")
        self.favoritesRef = favoritesRef
        favoritesHandle = favoritesRef.observe(.value, with: { [weak self] snapshot in
            var ids = Set<String>()
            for case let child as DataSnapshot in snapshot.children {
                if let id = child.value as? String, !id.isEmpty { ids.insert(id) }
            }
            self?.favorites = ids
            self?.emit()
        }, withCancel: { [weak self] error in self?.fail(error) })
    }

    private func detachUser() {
        if let savedRef, let savedHandle { savedRef.removeObserver(withHandle: savedHandle) }
        if let favoritesRef, let favoritesHandle { favoritesRef.removeObserver(withHandle: favoritesHandle) }
        savedRef = nil; savedHandle = nil; favoritesRef = nil; favoritesHandle = nil
    }

    private func emit() {
        let favoriteIds = favorites
        var byId: [String: SmokerRecipe] = [:]
        for var recipe in standard + saved {
            recipe.favorite = favoriteIds.contains(recipe.id)
            byId[recipe.id] = recipe
        }
        let result = byId.values.sorted {
            if $0.favorite != $1.favorite { return $0.favorite && !$1.favorite }
            if $0.updatedAt != $1.updatedAt { return $0.updatedAt > $1.updatedAt }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        DispatchQueue.main.async { [weak self] in self?.onChange?(result) }
    }

    private func fail(_ error: Error) {
        DispatchQueue.main.async { [weak self] in self?.onError?(error.localizedDescription) }
    }

    private static func parseRecipeList(_ snapshot: DataSnapshot) -> [SmokerRecipe] {
        var recipes: [SmokerRecipe] = []
        for case let child as DataSnapshot in snapshot.children {
            if let recipe = SmokerRecipe.from(snapshot: child) { recipes.append(recipe) }
        }
        return recipes
    }
}

enum RecipeError: LocalizedError {
    case message(String)
    var errorDescription: String? { switch self { case .message(let text): return text } }
}
