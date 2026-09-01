import Foundation
import FirebaseDatabase

final class HomeService {
    private let root = FirebaseConfig.root
    private var ref: DatabaseReference?
    private var handle: DatabaseHandle?

    func observe(
        smokerId: String,
        onChange: @escaping (SmokerState, CurrentRecipeRuntime) -> Void,
        onError: @escaping (String) -> Void
    ) {
        stop()
        let ref = root.child("smokers").child(smokerId)
        self.ref = ref
        handle = ref.observe(.value, with: { snapshot in
            let stateSnap = snapshot.childSnapshot(forPath: "state")
            let telemetry = snapshot.childSnapshot(forPath: "telemetry")
            let current = snapshot.childSnapshot(forPath: "current_recipe")

            let state = SmokerState(
                chamberTemperature: double(telemetry.childSnapshot(forPath: "camera_temp").value),
                productTemperature: double(telemetry.childSnapshot(forPath: "product_temp").value),
                targetChamberTemperature: double(stateSnap.childSnapshot(forPath: "target_camera_temp").value),
                targetProductTemperature: double(stateSnap.childSnapshot(forPath: "target_product_temp").value),
                heatingPower: int(stateSnap.childSnapshot(forPath: "heating_power").value),
                smokeLevel: int(stateSnap.childSnapshot(forPath: "smoke_level").value),
                heatingEnabled: stateSnap.childSnapshot(forPath: "is_heating").value as? Bool ?? false,
                dryingEnabled: stateSnap.childSnapshot(forPath: "is_drying").value as? Bool ?? false,
                convectionEnabled: stateSnap.childSnapshot(forPath: "is_convection_fan_on").value as? Bool ?? false,
                lightEnabled: stateSnap.childSnapshot(forPath: "is_light_on").value as? Bool ?? false,
                steamEnabled: stateSnap.childSnapshot(forPath: "is_steam_on").value as? Bool ?? false,
                timer: int64(stateSnap.childSnapshot(forPath: "timer").value)
            )

            let directId = (current.childSnapshot(forPath: "recipe_id").value as? String) ?? ""
            let commandId = (current.childSnapshot(forPath: "command/recipe_id").value as? String) ?? ""
            let runtime = CurrentRecipeRuntime(
                recipeId: directId.isEmpty ? commandId : directId,
                running: current.childSnapshot(forPath: "running").value as? Bool ?? false,
                stageIndex: current.childSnapshot(forPath: "stage_index").exists() ? int(current.childSnapshot(forPath: "stage_index").value) : -1,
                stageStartedAt: int64(current.childSnapshot(forPath: "stage_started_at").value),
                startedAt: int64(current.childSnapshot(forPath: "started_at").value)
            )
            DispatchQueue.main.async { onChange(state, runtime) }
        }, withCancel: { error in
            DispatchQueue.main.async { onError(error.localizedDescription) }
        })
    }

    func setState(smokerId: String, field: String, value: Any) async throws {
        try await root.child("smokers").child(smokerId).child("state").child(field).setValue(value)
    }

    func stopRecipe(smokerId: String) async throws {
        try await root.child("smokers").child(smokerId).child("current_recipe").updateChildValues([
            "command/action": "end",
            "running": false
        ])
    }

    func stop() {
        if let ref, let handle { ref.removeObserver(withHandle: handle) }
        ref = nil; handle = nil
    }
}
