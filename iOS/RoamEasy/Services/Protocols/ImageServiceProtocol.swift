import Foundation

protocol ImageServiceProtocol: AnyObject {
    func imageURL(for attraction: Attraction) async -> URL?
    func setImageURL(_ url: URL, for id: UUID)
    func cachedImageURL(for id: UUID) -> URL?
}
