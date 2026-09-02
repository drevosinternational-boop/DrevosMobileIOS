import Foundation
import Combine
import UIKit
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

@MainActor
final class AuthSession: ObservableObject {
    static let shared = AuthSession()

    @Published private(set) var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?

    private var handle: AuthStateDidChangeListenerHandle?

    private init() {
        user = Auth.auth().currentUser
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
                if let user { await UserProfileSync.shared.sync(user) }
            }
        }
    }

    deinit {
        if let handle { Auth.auth().removeStateDidChangeListener(handle) }
    }

    func signIn(email: String, password: String) {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Enter email and password."
            return
        }

        isLoading = true
        errorMessage = nil
        Task {
            do {
                _ = try await Auth.auth().signIn(withEmail: email, password: password)
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }

    func signInWithGoogle() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                guard let clientID = FirebaseApp.app()?.options.clientID else {
                    throw AuthError.configuration("Firebase iOS client ID is missing.")
                }
                GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

                guard let presenter = UIApplication.shared.drevosTopViewController else {
                    throw AuthError.configuration("Could not open Google Sign-In.")
                }

                let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
                guard let idToken = result.user.idToken?.tokenString else {
                    throw AuthError.configuration("Google did not return an ID token.")
                }

                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: result.user.accessToken.tokenString
                )
                _ = try await Auth.auth().signIn(with: credential)
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }

    func resetPassword(email: String) {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else {
            errorMessage = "Enter your email first."
            return
        }
        Task {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: email)
                self.infoMessage = "Password reset email sent."
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func signOut() {
        do {
            GIDSignIn.sharedInstance.signOut()
            try Auth.auth().signOut()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}

enum AuthError: LocalizedError {
    case configuration(String)
    var errorDescription: String? {
        switch self { case .configuration(let message): return message }
    }
}

private extension UIApplication {
    var drevosTopViewController: UIViewController? {
        let scenes = connectedScenes.compactMap { $0 as? UIWindowScene }
        let root = scenes.flatMap(\.windows).first(where: { $0.isKeyWindow })?.rootViewController
        return root?.drevosTopMost
    }
}

private extension UIViewController {
    var drevosTopMost: UIViewController {
        if let presentedViewController { return presentedViewController.drevosTopMost }
        if let nav = self as? UINavigationController { return nav.visibleViewController?.drevosTopMost ?? nav }
        if let tab = self as? UITabBarController { return tab.selectedViewController?.drevosTopMost ?? tab }
        return self
    }
}
