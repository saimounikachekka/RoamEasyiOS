import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse(statusCode: Int)
    case decodingFailed(underlying: Error)
    case noConnection
    case unexpected(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL was invalid."
        case .invalidResponse(let statusCode):
            return "Server returned an unexpected response (status \(statusCode))."
        case .decodingFailed:
            return "Failed to process the server response."
        case .noConnection:
            return "No internet connection. Please try again later."
        case .unexpected:
            return "Something went wrong. Please try again."
        }
    }

    /// Wraps any error into a NetworkError, preserving it if already one.
    static func from(_ error: Error) -> NetworkError {
        if let networkError = error as? NetworkError {
            return networkError
        }
        if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
            return .noConnection
        }
        return .unexpected(underlying: error)
    }
}
