import XCTest
@testable import RoamEasy

final class SavedPlacesServiceTests: XCTestCase {
    var sut: SavedPlacesService!
    var session: URLSession!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
        sut = SavedPlacesService(baseURL: "https://test.example.com", session: session)
    }

    override func tearDown() {
        sut = nil
        session = nil
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    // MARK: - fetchSavedPlaces

    func testFetchSavedPlaces_decodesCorrectly() async throws {
        let json = """
        [
            {
                "userId": "user-1",
                "placeId": "place-1",
                "city": "Paris",
                "country": "France",
                "imageUrl": "https://example.com/img.jpg",
                "placeName": "Eiffel Tower"
            }
        ]
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, json)
        }

        let places = try await sut.fetchSavedPlaces(userId: "user-1")

        XCTAssertEqual(places.count, 1)
        XCTAssertEqual(places[0].placeName, "Eiffel Tower")
        XCTAssertEqual(places[0].city, "Paris")
        XCTAssertEqual(places[0].placeId, "place-1")
    }

    func testFetchSavedPlaces_throwsOnServerError() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        do {
            _ = try await sut.fetchSavedPlaces(userId: "user-1")
            XCTFail("Expected error to be thrown")
        } catch let error as NetworkError {
            if case .invalidResponse(let statusCode) = error {
                XCTAssertEqual(statusCode, 500)
            } else {
                XCTFail("Expected invalidResponse, got \(error)")
            }
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }

    func testSavePlace_sendsCorrectHTTPMethod() async throws {
        var capturedRequest: URLRequest?

        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let dto = SavedPlaceDTO(
            userId: "user-1",
            placeId: "place-1",
            city: "Paris",
            country: "France",
            imageUrl: "",
            placeName: "Eiffel Tower"
        )

        try await sut.savePlace(dto)

        XCTAssertEqual(capturedRequest?.httpMethod, "POST")
        XCTAssertEqual(capturedRequest?.url?.path, "/ios/saved-places")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func testDeletePlace_sendsCorrectHTTPMethod() async throws {
        var capturedRequest: URLRequest?

        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        try await sut.deletePlace(userId: "user-1", placeId: "place-1")

        XCTAssertEqual(capturedRequest?.httpMethod, "DELETE")
    }
}
