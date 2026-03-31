import SwiftUI

@MainActor
final class MapSnapshotService: ObservableObject, ImageServiceProtocol {
    private(set) var cache: [UUID: URL] = [:]

    func setImageURL(_ url: URL, for id: UUID) {
        cache[id] = url
    }

    func cachedImageURL(for id: UUID) -> URL? {
        cache[id]
    }

    func imageURL(for attraction: Attraction) async -> URL? {
        if let cached = cache[attraction.id] {
            return cached
        }

        let query = attraction.name
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://en.wikipedia.org/api/rest_v1/page/summary/\(query)"

        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                // Fallback: try search API
                return await searchWikipedia(query: attraction.name, id: attraction.id)
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let thumbnail = json["thumbnail"] as? [String: Any],
               let source = thumbnail["source"] as? String,
               let imageURL = URL(string: source) {
                cache[attraction.id] = imageURL
                return imageURL
            }

            return await searchWikipedia(query: attraction.name, id: attraction.id)
        } catch {
            return nil
        }
    }

    private func searchWikipedia(query: String, id: UUID) async -> URL? {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let searchURL = "https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=\(encoded)&format=json&srlimit=1"

        guard let url = URL(string: searchURL) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let queryResult = json["query"] as? [String: Any],
                  let search = queryResult["search"] as? [[String: Any]],
                  let first = search.first,
                  let title = first["title"] as? String else { return nil }

            let titleEncoded = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let summaryURL = "https://en.wikipedia.org/api/rest_v1/page/summary/\(titleEncoded)"

            guard let summaryUrl = URL(string: summaryURL) else { return nil }
            let (summaryData, _) = try await URLSession.shared.data(from: summaryUrl)

            if let summaryJson = try? JSONSerialization.jsonObject(with: summaryData) as? [String: Any],
               let thumbnail = summaryJson["thumbnail"] as? [String: Any],
               let source = thumbnail["source"] as? String,
               let imageURL = URL(string: source) {
                cache[id] = imageURL
                return imageURL
            }
        } catch {
            print("Wikipedia search failed: \(error.localizedDescription)")
        }

        return nil
    }
}
