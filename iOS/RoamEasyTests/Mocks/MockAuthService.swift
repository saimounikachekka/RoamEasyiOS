import Foundation
@testable import RoamEasy

final class MockAuthService: AuthenticationServiceProtocol {
    var isSignedIn: Bool = false
    var userID: String? = "test-user-123"
    var userName: String? = "Test User"

    var signInCallCount = 0
    var signOutCallCount = 0
    var signInResult = true

    func signIn() async -> Bool {
        signInCallCount += 1
        return signInResult
    }

    func signOut() {
        signOutCallCount += 1
        isSignedIn = false
        userID = nil
        userName = nil
    }
}
