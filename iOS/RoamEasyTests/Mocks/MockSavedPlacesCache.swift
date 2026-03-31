import Foundation
@testable import RoamEasy

final class MockSavedPlacesCache: SavedPlacesCacheProtocol {
    var fetchCallCount = 0
    var replaceCallCount = 0
    var saveCallCount = 0
    var deleteCallCount = 0

    var cachedPlaces: [SavedPlaceDTO] = []
    var lastReplacedPlaces: [SavedPlaceDTO] = []
    var lastSavedPlace: SavedPlaceDTO?
    var lastDeletedPlaceId: String?
    var fetchError: Error?
    var writeError: Error?

    func fetchCachedPlaces(userId: String) throws -> [SavedPlaceDTO] {
        fetchCallCount += 1
        if let fetchError { throw fetchError }
        return cachedPlaces.filter { $0.userId == userId }
    }

    func replaceCachedPlaces(_ places: [SavedPlaceDTO], userId: String) throws {
        replaceCallCount += 1
        if let writeError { throw writeError }
        lastReplacedPlaces = places
        cachedPlaces.removeAll { $0.userId == userId }
        cachedPlaces.append(contentsOf: places)
    }

    func saveCachedPlace(_ place: SavedPlaceDTO) throws {
        saveCallCount += 1
        if let writeError { throw writeError }
        lastSavedPlace = place
        cachedPlaces.removeAll { $0.placeId == place.placeId }
        cachedPlaces.append(place)
    }

    func deleteCachedPlace(placeId: String) throws {
        deleteCallCount += 1
        if let writeError { throw writeError }
        lastDeletedPlaceId = placeId
        cachedPlaces.removeAll { $0.placeId == placeId }
    }
}
