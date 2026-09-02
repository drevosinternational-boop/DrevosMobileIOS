import Foundation
import FirebaseDatabase

struct RecipeStage: Identifiable, Equatable {
    var id = UUID()
    var type: String = "Smoking"
    var durationMinutes: Int = 0
    var chamberTempC: Int = 0
    var productTempC: Int = 0
    var smokeLevel: Int = 0
}

struct SmokerRecipe: Identifiable, Equatable {
    var id: String = ""
    var name: String = ""
    var description: String = ""
    var favorite = false
    var imageRevision: Int = 0
    var imageUrl: String = ""
    var imageSource: String = ""
    var imageCredit: String = ""
    var stages: [RecipeStage] = []
    var tags: [String] = []
    var updatedAt: Int64 = 0
    var version: Int = 2

    var totalDurationMinutes: Int { stages.reduce(0) { $0 + $1.durationMinutes } }
    var isPreset: Bool { id.hasPrefix("drevos_preset_") }

    static func from(snapshot: DataSnapshot) -> SmokerRecipe? {
        let id = (snapshot.childSnapshot(forPath: "id").value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? snapshot.key

        guard !id.isEmpty else { return nil }

        var stages: [RecipeStage] = []
        for case let stage as DataSnapshot in snapshot.childSnapshot(forPath: "stages").children {
            stages.append(
                RecipeStage(
                    type: (stage.childSnapshot(forPath: "type").value as? String) ?? "Smoking",
                    durationMinutes: int(stage.childSnapshot(forPath: "duration").value),
                    chamberTempC: int(stage.childSnapshot(forPath: "chamber_temp").value),
                    productTempC: int(stage.childSnapshot(forPath: "product_temp").value),
                    smokeLevel: int(stage.childSnapshot(forPath: "smoke_level").value)
                )
            )
        }

        var tags: [String] = []
        for case let tag as DataSnapshot in snapshot.childSnapshot(forPath: "tags").children {
            if let value = tag.value as? String, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                tags.append(value)
            }
        }

        return SmokerRecipe(
            id: id,
            name: (snapshot.childSnapshot(forPath: "name").value as? String) ?? "",
            description: (snapshot.childSnapshot(forPath: "description").value as? String) ?? "",
            favorite: (snapshot.childSnapshot(forPath: "favorite").value as? Bool) ?? false,
            imageRevision: int(snapshot.childSnapshot(forPath: "image_revision").value),
            imageUrl: (snapshot.childSnapshot(forPath: "image_url").value as? String) ?? "",
            imageSource: (snapshot.childSnapshot(forPath: "image_source").value as? String) ?? "",
            imageCredit: (snapshot.childSnapshot(forPath: "image_credit").value as? String) ?? "",
            stages: stages,
            tags: tags,
            updatedAt: int64(snapshot.childSnapshot(forPath: "updated_at").value),
            version: max(1, int(snapshot.childSnapshot(forPath: "version").value))
        )
    }

    func firebaseMap() -> [String: Any] {
        [
            "id": id,
            "name": name,
            "description": description,
            "image_revision": imageRevision,
            "image_url": imageUrl,
            "image_source": imageSource,
            "image_credit": imageCredit,
            "stages": stages.map {
                [
                    "type": $0.type,
                    "duration": $0.durationMinutes,
                    "chamber_temp": $0.chamberTempC,
                    "product_temp": $0.productTempC,
                    "smoke_level": $0.smokeLevel
                ] as [String: Any]
            },
            "tags": tags,
            "updated_at": updatedAt,
            "version": version
        ]
    }
}

struct CurrentRecipeRuntime: Equatable {
    var recipeId: String = ""
    var running = false
    var stageIndex: Int = -1
    var stageStartedAt: Int64 = 0
    var startedAt: Int64 = 0
}

func int(_ value: Any?) -> Int {
    if let n = value as? NSNumber { return n.intValue }
    if let s = value as? String { return Int(s) ?? 0 }
    return 0
}

func int64(_ value: Any?) -> Int64 {
    if let n = value as? NSNumber { return n.int64Value }
    if let s = value as? String { return Int64(s) ?? 0 }
    return 0
}

func double(_ value: Any?) -> Double {
    if let n = value as? NSNumber { return n.doubleValue }
    if let s = value as? String { return Double(s) ?? 0 }
    return 0
}
