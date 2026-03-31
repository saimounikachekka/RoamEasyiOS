import SwiftUI
import MapKit

struct ExploreView: View {
    var searchQuery: String
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var viewModel: AttractionsViewModel
    @ObservedObject var snapshotService: MapSnapshotService
    @ObservedObject var savedPlacesManager: SavedPlacesManager
    @ObservedObject var authManager: AuthenticationManager
    @Binding var cameraPosition: MapCameraPosition
    @Binding var dataReady: Bool

    @State private var selectedAttraction: Attraction?
    @State private var showSignIn = false
    @State private var pendingSaveAttraction: Attraction?

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

            if !dataReady {
                loadingState
            } else {
                MapSection(
                    attractions: viewModel.attractions,
                    cameraPosition: $cameraPosition,
                    selectedAttraction: $selectedAttraction
                )
                AttractionsCarousel(
                    attractions: viewModel.attractions,
                    snapshotService: snapshotService,
                    isSaved: { savedPlacesManager.isSaved($0) },
                    onSave: handleSaveTapped,
                    onSelect: focusOnAttraction
                )
            }
        }
        .sheet(isPresented: $showSignIn) {
            SignInView(authManager: authManager) {
                if let userId = authManager.userID {
                    Task {
                        await savedPlacesManager.loadSavedPlaces(userId: userId, snapshotService: snapshotService)
                        if let attraction = pendingSaveAttraction {
                            savedPlacesManager.toggle(attraction)
                            pendingSaveAttraction = nil
                        }
                    }
                }
            }
        }
        .task(id: searchQuery) {
            guard !dataReady else { return }

            if !searchQuery.isEmpty {
                await viewModel.searchForCity(searchQuery)
                fitCamera()
                dataReady = true
            } else {
                let status = locationManager.authorizationStatus
                if status == .notDetermined {
                    locationManager.requestPermission()
                } else if status == .authorizedWhenInUse || status == .authorizedAlways {
                    locationManager.requestLocation()
                    if let existing = locationManager.userLocation, viewModel.attractions.isEmpty {
                        await loadAttractions(coordinate: existing.coordinate)
                    }
                }
            }
        }
        .onChange(of: locationManager.authorizationStatus) { _, newStatus in
            if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                locationManager.requestLocation()
            }
        }
        .onChange(of: locationManager.userLocation) { oldLocation, newLocation in
            guard let eqCoord = newLocation else { return }
            let shouldReload: Bool
            if viewModel.attractions.isEmpty {
                shouldReload = true
            } else if let old = oldLocation {
                let oldLoc = CLLocation(latitude: old.latitude, longitude: old.longitude)
                let newLoc = CLLocation(latitude: eqCoord.latitude, longitude: eqCoord.longitude)
                shouldReload = oldLoc.distance(from: newLoc) > 5_000
            } else {
                shouldReload = true
            }
            guard shouldReload else { return }
            Task {
                dataReady = false
                await loadAttractions(coordinate: eqCoord.coordinate)
            }
        }
    }

    private var loadingState: some View {
        VStack {
            Spacer()
            ProgressView("Finding attractions...")
                .font(.subheadline)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private func loadAttractions(coordinate: CLLocationCoordinate2D) async {
        await viewModel.searchNearby(coordinate: coordinate)
        fitCamera()
        dataReady = true
    }

    private func handleSaveTapped(_ attraction: Attraction) {
        if savedPlacesManager.isSaved(attraction) || authManager.isSignedIn {
            savedPlacesManager.toggle(attraction)
        } else {
            pendingSaveAttraction = attraction
            showSignIn = true
        }
    }

    private func focusOnAttraction(_ attraction: Attraction) {
        withAnimation {
            selectedAttraction = attraction
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: attraction.coordinate,
                    latitudinalMeters: 2_000,
                    longitudinalMeters: 2_000
                )
            )
        }
    }

    private func fitCamera() {
        guard !viewModel.attractions.isEmpty else { return }
        let coordinates = viewModel.attractions.map(\.coordinate)
        let lats = coordinates.map(\.latitude)
        let lons = coordinates.map(\.longitude)
        guard
            let minLat = lats.min(),
            let maxLat = lats.max(),
            let minLon = lons.min(),
            let maxLon = lons.max()
        else {
            return
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.4, 0.02),
            longitudeDelta: max((maxLon - minLon) * 1.4, 0.02)
        )
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}

#Preview {
    ExploreView(
        searchQuery: "",
        locationManager: LocationManager(),
        viewModel: AttractionsViewModel(),
        snapshotService: MapSnapshotService(),
        savedPlacesManager: SavedPlacesManager(),
        authManager: AuthenticationManager(),
        cameraPosition: .constant(.automatic),
        dataReady: .constant(true)
    )
}
