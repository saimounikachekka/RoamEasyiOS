import Foundation

protocol SavedPlacesCacheProtocol {
    func fetchCachedPlaces(userId: String) throws -> [SavedPlaceDTO]
    func replaceCachedPlaces(_ places: [SavedPlaceDTO], userId: String) throws
    func saveCachedPlace(_ place: SavedPlaceDTO) throws
    func deleteCachedPlace(placeId: String) throws
}
