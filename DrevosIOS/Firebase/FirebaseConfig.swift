import Foundation
import FirebaseDatabase

// Same Firebase Realtime Database used by the Android application.
enum FirebaseConfig {
    static let databaseURL = "https://drevos-9827e-default-rtdb.europe-west1.firebasedatabase.app"

    static var root: DatabaseReference {
        Database.database(url: databaseURL).reference()
    }
}
