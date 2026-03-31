import Foundation

class SavedPlacesService: SavedPlacesServiceProtocol {
    private let baseURL: String
    private let session: URLSession

    init(baseURL: String = AppConfiguration.apiBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func fetchSavedPlaces(userId: String) async throws -> [SavedPlaceDTO] {
        guard let encoded = userId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/ios/saved-places?userId=\(encoded)") else {
            throw NetworkError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse(statusCode: -1)
        }
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse(statusCode: httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode([SavedPlaceDTO].self, from: data)
        } catch {
            throw NetworkError.decodingFailed(underlying: error)
        }
    }

    func savePlace(_ place: SavedPlaceDTO) async throws {
        guard let url = URL(string: "\(baseURL)/ios/saved-places") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(place)

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }
    }

    func deletePlace(userId: String, placeId: String) async throws {
        guard let url = URL(string: "\(baseURL)/ios/saved-places") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["userId": userId, "placeId": placeId]
        request.httpBody = try JSONEncoder().encode(body)

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }
    }
}
