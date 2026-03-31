import SwiftUI
import GoogleSignIn
import SwiftData

@main
struct RoamEasyApp: App {
    @StateObject private var authManager = AuthenticationManager()

    var body: some Scene {
        WindowGroup {
            ContentView(authManager: authManager)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .onAppear {
                    authManager.restorePreviousSignIn()
                }
        }
        .modelContainer(for: CachedSavedPlace.self)
    }
}
