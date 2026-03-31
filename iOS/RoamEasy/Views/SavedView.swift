import SwiftUI

struct SavedView: View {
    @ObservedObject var savedPlacesManager: SavedPlacesManager
    let snapshotService: MapSnapshotService
    @ObservedObject var authManager: AuthenticationManager
    @State private var showSignIn = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        VStack(spacing: 0) {
            HeaderBar(
                isSignedIn: authManager.isSignedIn,
                signInAction: { showSignIn = true },
                signOutAction: {
                    savedPlacesManager.clearAll()
                    authManager.signOut()
                }
            )
            .zIndex(1)

            if savedPlacesManager.savedAttractions.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "bookmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No saved places yet")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Tap the bookmark icon on any attraction to save it here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(savedPlacesManager.savedAttractions) { attraction in
                            AttractionCard(
                                attraction: attraction,
                                snapshotService: snapshotService,
                                isSaved: true,
                                onSave: {
                                    savedPlacesManager.toggle(attraction)
                                }
                            )
                        }
                    }
                    .padding(16)
                }
                .background(Color(.systemBackground))
            }
        }
        .sheet(isPresented: $showSignIn) {
            SignInView(authManager: authManager) {}
        }
    }
}
