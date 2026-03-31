import Foundation

struct SavedPlaceDTO: Codable {
    let userId: String
    let placeId: String
    let city: String
    let country: String
    let imageUrl: String
    let placeName: String
}
