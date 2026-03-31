import SwiftUI
import MapKit
import SwiftData

struct ContentView: View {
    @ObservedObject var authManager: AuthenticationManager
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var selectedTab = AppTab.search
    @State private var showSignIn = false
    @FocusState private var searchFocused: Bool

    @StateObject private var locationManager = LocationManager()
    @StateObject private var attractionsVM = AttractionsViewModel()
    @StateObject private var snapshotService = MapSnapshotService()
    @StateObject private var searchCompleter = SearchCompleterService()
    @StateObject private var savedPlacesManager = SavedPlacesManager()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var dataReady = false

    var body: some View {
        MainTabView(selectedTab: $selectedTab) {
            searchContent
        } exploreTab: {
            ExploreView(
                searchQuery: searchText,
                locationManager: locationManager,
                viewModel: attractionsVM,
                snapshotService: snapshotService,
                savedPlacesManager: savedPlacesManager,
                authManager: authManager,
                cameraPosition: $cameraPosition,
                dataReady: $dataReady
            )
        } savedTab: {
            SavedView(
                savedPlacesManager: savedPlacesManager,
                snapshotService: snapshotService,
                authManager: authManager
            )
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showSignIn) {
            SignInView(authManager: authManager) {}
        }
        .task {
            savedPlacesManager.configure(snapshotService: snapshotService)
            savedPlacesManager.configureCache(SwiftDataSavedPlacesCache(context: modelContext))
            if let userId = authManager.userID {
                await savedPlacesManager.loadSavedPlaces(userId: userId, snapshotService: snapshotService)
            }
        }
        .onChange(of: authManager.isSignedIn) { _, isSignedIn in
            if isSignedIn, let userId = authManager.userID {
                Task {
                    await savedPlacesManager.loadSavedPlaces(userId: userId, snapshotService: snapshotService)
                }
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .search {
                searchText = ""
                searchCompleter.clear()
                searchFocused = false
            }
        }
    }

    // MARK: - Search Content

    private var searchContent: some View {
        ZStack(alignment: .top) {
            Image("hero")
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
                .onTapGesture {
                    searchFocused = false
                    searchCompleter.clear()
                }

            VStack(spacing: 0) {
                HeaderBar(
                    isSignedIn: authManager.isSignedIn,
                    signInAction: { showSignIn = true },
                    signOutAction: {
                        savedPlacesManager.clearAll()
                        authManager.signOut()
                    }
                )

                VStack(spacing: 0) {
                    Spacer()

                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color(.secondaryLabel))
                        TextField("Where are you headed?", text: $searchText)
                            .font(.body)
                            .focused($searchFocused)
                            .submitLabel(.search)
                            .onSubmit {
                                navigateToExplore(query: searchText)
                            }
                            .onChange(of: searchText) { _, newValue in
                                searchCompleter.update(query: newValue)
                            }

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                searchCompleter.clear()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color(.tertiaryLabel))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: searchCompleter.suggestions.isEmpty ? 24 : 16))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .padding(.horizontal, 32)
                    .accessibilityLabel("Search destinations")

                    // Autocomplete suggestions
                    if !searchCompleter.suggestions.isEmpty && searchFocused {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(searchCompleter.suggestions.prefix(6), id: \.self) { suggestion in
                                    Button {
                                        searchText = [suggestion.title, suggestion.subtitle]
                                            .filter { !$0.isEmpty }
                                            .joined(separator: ", ")
                                        searchFocused = false
                                        searchCompleter.clear()
                                        navigateToExplore(query: searchText)
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: "mappin.circle.fill")
                                                .foregroundStyle(.red)
                                                .font(.title3)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(suggestion.title)
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                    .foregroundStyle(Color(.label))
                                                if !suggestion.subtitle.isEmpty {
                                                    Text(suggestion.subtitle)
                                                        .font(.caption)
                                                        .foregroundStyle(Color(.secondaryLabel))
                                                }
                                            }
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .contentShape(Rectangle())
                                    }
                                    Divider().padding(.leading, 52)
                                }
                            }
                        }
                        .frame(maxHeight: 260)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 6, y: 4)
                        .padding(.horizontal, 32)
                        .padding(.top, 4)
                    }

                    Spacer()
                }
                .frame(maxHeight: .infinity)
            }
        }
    }

    // MARK: - Navigation

    private func navigateToExplore(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        searchText = trimmed
        searchCompleter.clear()
        searchFocused = false
        attractionsVM.attractions = []
        attractionsVM.cityName = ""
        dataReady = false
        cameraPosition = .automatic
        selectedTab = .explore
    }
}

#Preview {
    ContentView(authManager: AuthenticationManager())
        .modelContainer(for: CachedSavedPlace.self, inMemory: true)
}
