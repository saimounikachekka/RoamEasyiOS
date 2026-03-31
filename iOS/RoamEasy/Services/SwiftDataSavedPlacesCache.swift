import Foundation
import SwiftData

final class SwiftDataSavedPlacesCache: SavedPlacesCacheProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchCachedPlaces(userId: String) throws -> [SavedPlaceDTO] {
        let descriptor = FetchDescriptor<CachedSavedPlace>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\.cachedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map { $0.toDTO() }
    }

    func replaceCachedPlaces(_ places: [SavedPlaceDTO], userId: String) throws {
        let descriptor = FetchDescriptor<CachedSavedPlace>(
            predicate: #Predicate { $0.userId == userId }
        )
        let existingPlaces = try context.fetch(descriptor)
        for place in existingPlaces {
            context.delete(place)
        }

        for place in places {
            context.insert(CachedSavedPlace(
                placeId: place.placeId,
                userId: place.userId,
                city: place.city,
                country: place.country,
                imageUrl: place.imageUrl,
                placeName: place.placeName
            ))
        }

        try context.save()
    }

    func saveCachedPlace(_ place: SavedPlaceDTO) throws {
        if let existingPlace = try cachedPlace(placeId: place.placeId) {
            existingPlace.userId = place.userId
            existingPlace.city = place.city
            existingPlace.country = place.country
            existingPlace.imageUrl = place.imageUrl
            existingPlace.placeName = place.placeName
            existingPlace.cachedAt = .now
        } else {
            context.insert(CachedSavedPlace(
                placeId: place.placeId,
                userId: place.userId,
                city: place.city,
                country: place.country,
                imageUrl: place.imageUrl,
                placeName: place.placeName
            ))
        }

        try context.save()
    }

    func deleteCachedPlace(placeId: String) throws {
        guard let existingPlace = try cachedPlace(placeId: placeId) else { return }
        context.delete(existingPlace)
        try context.save()
    }

    private func cachedPlace(placeId: String) throws -> CachedSavedPlace? {
        let descriptor = FetchDescriptor<CachedSavedPlace>(
            predicate: #Predicate { $0.placeId == placeId }
        )
        return try context.fetch(descriptor).first
    }
}
