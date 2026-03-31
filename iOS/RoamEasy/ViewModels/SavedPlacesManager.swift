import Foundation
import CoreLocation

@MainActor
class SavedPlacesManager: ObservableObject {
    @Published private(set) var savedAttractions: [Attraction] = []
    @Published var error: NetworkError?

    private let service: SavedPlacesServiceProtocol
    private var cache: SavedPlacesCacheProtocol?
    private var userId: String?
    private var snapshotService: (any ImageServiceProtocol)?
    private var placeIdMap: [String: String] = [:]

    init(
        service: SavedPlacesServiceProtocol = SavedPlacesService(),
        cache: SavedPlacesCacheProtocol? = nil
    ) {
        self.service = service
        self.cache = cache
    }

    func configure(snapshotService: some ImageServiceProtocol) {
        self.snapshotService = snapshotService
    }

    func configureCache(_ cache: SavedPlacesCacheProtocol) {
        self.cache = cache
    }

    func isSaved(_ attraction: Attraction) -> Bool {
        savedAttractions.contains { $0.name == attraction.name }
    }

    func toggle(_ attraction: Attraction) {
        if let index = savedAttractions.firstIndex(where: { $0.name == attraction.name }) {
            let removed = savedAttractions.remove(at: index)
            guard let userId else { return }
            guard let placeId = placeIdMap.removeValue(forKey: removed.name) else { return }
            Task {
                do {
                    try await service.deletePlace(userId: userId, placeId: placeId)
                    try cache?.deleteCachedPlace(placeId: placeId)
                } catch {
                    self.error = NetworkError.from(error)
                }
            }
        } else {
            savedAttractions.append(attraction)
            guard let userId else { return }
            let placeId = UUID().uuidString
            placeIdMap[attraction.name] = placeId
            let imageUrl = snapshotService?.cachedImageURL(for: attraction.id)?.absoluteString ?? ""
            let dto = SavedPlaceDTO(
                userId: userId,
                placeId: placeId,
                city: attraction.city,
                country: attraction.country,
                imageUrl: imageUrl,
                placeName: attraction.name
            )
            Task {
                do {
                    try await service.savePlace(dto)
                    try cache?.saveCachedPlace(dto)
                } catch {
                    self.error = NetworkError.from(error)
                }
            }
        }
    }

    func loadSavedPlaces(userId: String, snapshotService: some ImageServiceProtocol) async {
        self.userId = userId
        self.snapshotService = snapshotService
        error = nil

        _ = loadCachedPlaces(userId: userId, snapshotService: snapshotService)

        do {
            let places = try await service.fetchSavedPlaces(userId: userId)
            applyPlaces(places, snapshotService: snapshotService)
            try cache?.replaceCachedPlaces(places, userId: userId)
            error = nil
        } catch {
            if savedAttractions.isEmpty {
                self.error = NetworkError.from(error)
            }
        }
    }

    func clearAll() {
        savedAttractions.removeAll()
        placeIdMap.removeAll()
        userId = nil
    }

    private func loadCachedPlaces(
        userId: String,
        snapshotService: some ImageServiceProtocol
    ) -> Bool {
        guard let cache else { return false }

        do {
            let places = try cache.fetchCachedPlaces(userId: userId)
            guard !places.isEmpty else { return false }
            applyPlaces(places, snapshotService: snapshotService)
            return true
        } catch {
            self.error = NetworkError.from(error)
            return false
        }
    }

    private func applyPlaces(
        _ places: [SavedPlaceDTO],
        snapshotService: some ImageServiceProtocol
    ) {
        var attractions: [Attraction] = []
        placeIdMap.removeAll()
        for place in places {
            let attraction = Attraction(
                name: place.placeName,
                city: place.city,
                state: place.country,
                country: place.country,
                coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                category: .landmark
            )
            placeIdMap[place.placeName] = place.placeId
            if !place.imageUrl.isEmpty,
               let url = URL(string: place.imageUrl) {
                snapshotService.setImageURL(url, for: attraction.id)
            }
            attractions.append(attraction)
        }
        savedAttractions = attractions
    }
}
