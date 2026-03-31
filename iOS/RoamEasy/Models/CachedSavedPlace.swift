import Foundation
import SwiftData

@Model
final class CachedSavedPlace {
    @Attribute(.unique) var placeId: String
    var userId: String
    var city: String
    var country: String
    var imageUrl: String
    var placeName: String
    var cachedAt: Date

    init(
        placeId: String,
        userId: String,
        city: String,
        country: String,
        imageUrl: String,
        placeName: String,
        cachedAt: Date = .now
    ) {
        self.placeId = placeId
        self.userId = userId
        self.city = city
        self.country = country
        self.imageUrl = imageUrl
        self.placeName = placeName
        self.cachedAt = cachedAt
    }

    func toDTO() -> SavedPlaceDTO {
        SavedPlaceDTO(
            userId: userId,
            placeId: placeId,
            city: city,
            country: country,
            imageUrl: imageUrl,
            placeName: placeName
        )
    }
}
