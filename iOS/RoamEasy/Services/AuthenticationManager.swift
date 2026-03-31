import Foundation
import GoogleSignIn

@MainActor
class AuthenticationManager: ObservableObject, AuthenticationServiceProtocol {
    @Published var currentUser: GIDGoogleUser?

    var isSignedIn: Bool {
        currentUser != nil
    }

    var userName: String? {
        currentUser?.profile?.name
    }

    var userEmail: String? {
        currentUser?.profile?.email
    }

    var userID: String? {
        currentUser?.userID
    }

    func restorePreviousSignIn() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            Task { @MainActor in
                if let user, error == nil {
                    self?.currentUser = user
                }
            }
        }
    }

    func signIn() async -> Bool {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return false
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            currentUser = result.user
            return true
        } catch {
            print("Google Sign-In error: \(error.localizedDescription)")
            return false
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        currentUser = nil
    }
}
