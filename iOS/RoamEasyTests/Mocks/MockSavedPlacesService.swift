import Foundation
@testable import RoamEasy

final class MockSavedPlacesService: SavedPlacesServiceProtocol {
    var fetchCallCount = 0
    var saveCallCount = 0
    var deleteCallCount = 0

    var lastSavedPlace: SavedPlaceDTO?
    var lastDeletedUserId: String?
    var lastDeletedPlaceId: String?
    var lastFetchUserId: String?

    var placesToReturn: [SavedPlaceDTO] = []
    var errorToThrow: Error?

    func fetchSavedPlaces(userId: String) async throws -> [SavedPlaceDTO] {
        fetchCallCount += 1
        lastFetchUserId = userId
        if let error = errorToThrow { throw error }
        return placesToReturn
    }

    func savePlace(_ place: SavedPlaceDTO) async throws {
        saveCallCount += 1
        lastSavedPlace = place
        if let error = errorToThrow { throw error }
    }

    func deletePlace(userId: String, placeId: String) async throws {
        deleteCallCount += 1
        lastDeletedUserId = userId
        lastDeletedPlaceId = placeId
        if let error = errorToThrow { throw error }
    }
}
