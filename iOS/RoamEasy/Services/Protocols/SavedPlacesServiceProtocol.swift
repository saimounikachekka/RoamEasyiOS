import Foundation

protocol SavedPlacesServiceProtocol {
    func fetchSavedPlaces(userId: String) async throws -> [SavedPlaceDTO]
    func savePlace(_ place: SavedPlaceDTO) async throws
    func deletePlace(userId: String, placeId: String) async throws
}
