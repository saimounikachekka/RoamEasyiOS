import Foundation
import CoreLocation
@testable import RoamEasy

enum TestFixtures {
    static func makeAttraction(
        name: String = "Eiffel Tower",
        city: String = "Paris",
        state: String = "Île-de-France",
        country: String = "France",
        latitude: Double = 48.8584,
        longitude: Double = 2.2945,
        category: AttractionCategory = .landmark
    ) -> Attraction {
        Attraction(
            name: name,
            city: city,
            state: state,
            country: country,
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            category: category
        )
    }

    static func makeSavedPlaceDTO(
        userId: String = "test-user-123",
        placeId: String = "place-1",
        city: String = "Paris",
        country: String = "France",
        imageUrl: String = "https://example.com/image.jpg",
        placeName: String = "Eiffel Tower"
    ) -> SavedPlaceDTO {
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
