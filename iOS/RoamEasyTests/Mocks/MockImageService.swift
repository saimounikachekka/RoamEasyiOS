import Foundation
@testable import RoamEasy

final class MockImageService: ImageServiceProtocol {
    var urlToReturn: URL?
    var imageURLCallCount = 0
    var setURLCallCount = 0
    var cachedURLCallCount = 0

    private var cache: [UUID: URL] = [:]

    func imageURL(for attraction: Attraction) async -> URL? {
        imageURLCallCount += 1
        return urlToReturn
    }

    func setImageURL(_ url: URL, for id: UUID) {
        setURLCallCount += 1
        cache[id] = url
    }

    func cachedImageURL(for id: UUID) -> URL? {
        cachedURLCallCount += 1
        return cache[id]
    }
}
