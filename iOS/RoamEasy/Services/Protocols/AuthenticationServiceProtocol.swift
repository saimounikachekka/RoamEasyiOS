import Foundation

protocol AuthenticationServiceProtocol: ObservableObject {
    var isSignedIn: Bool { get }
    var userID: String? { get }
    var userName: String? { get }
    func signIn() async -> Bool
    func signOut()
}
