import XCTest
@testable import RoamEasy

@MainActor
final class SavedPlacesManagerTests: XCTestCase {
    var sut: SavedPlacesManager!
    var mockService: MockSavedPlacesService!
    var mockImageService: MockImageService!
    var mockCache: MockSavedPlacesCache!

    override func setUp() {
        super.setUp()
        mockService = MockSavedPlacesService()
        mockImageService = MockImageService()
        mockCache = MockSavedPlacesCache()
        sut = SavedPlacesManager(service: mockService, cache: mockCache)
        sut.configure(snapshotService: mockImageService)
    }

    override func tearDown() {
        sut = nil
        mockService = nil
        mockImageService = nil
        mockCache = nil
        super.tearDown()
    }

    // MARK: - toggle

    func testToggle_addsAttraction_whenNotSaved() {
        let attraction = TestFixtures.makeAttraction()

        sut.toggle(attraction)

        XCTAssertEqual(sut.savedAttractions.count, 1)
        XCTAssertTrue(sut.isSaved(attraction))
    }

    func testToggle_removesAttraction_whenAlreadySaved() {
        let attraction = TestFixtures.makeAttraction()

        sut.toggle(attraction)
        // Toggle again with a different instance but same name
        let sameAttraction = TestFixtures.makeAttraction(name: attraction.name)
        sut.toggle(sameAttraction)

        XCTAssertEqual(sut.savedAttractions.count, 0)
        XCTAssertFalse(sut.isSaved(attraction))
    }

    func testToggle_callsSavePlace_onService() async throws {
        // Load with userId so the service call fires
        await sut.loadSavedPlaces(userId: "test-user-123", snapshotService: mockImageService)
        let attraction = TestFixtures.makeAttraction()

        sut.toggle(attraction)
        // Allow the Task inside toggle to execute
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(mockService.saveCallCount, 1)
        XCTAssertEqual(mockService.lastSavedPlace?.placeName, "Eiffel Tower")
        XCTAssertEqual(mockCache.saveCallCount, 1)
    }

    func testToggle_callsDeletePlace_onService() async throws {
        // Load first to set userId
        mockService.placesToReturn = [TestFixtures.makeSavedPlaceDTO()]
        await sut.loadSavedPlaces(userId: "test-user-123", snapshotService: mockImageService)
        XCTAssertEqual(sut.savedAttractions.count, 1)

        // Toggle to remove
        let attraction = TestFixtures.makeAttraction()
        sut.toggle(attraction)
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(mockService.deleteCallCount, 1)
        XCTAssertEqual(mockService.lastDeletedPlaceId, "place-1")
        XCTAssertEqual(mockCache.deleteCallCount, 1)
    }

    // MARK: - loadSavedPlaces

    func testLoadSavedPlaces_populatesAttractions() async {
        mockService.placesToReturn = [
            TestFixtures.makeSavedPlaceDTO(placeName: "Eiffel Tower"),
            TestFixtures.makeSavedPlaceDTO(placeId: "place-2", placeName: "Louvre Museum"),
        ]

        await sut.loadSavedPlaces(userId: "test-user-123", snapshotService: mockImageService)

        XCTAssertEqual(sut.savedAttractions.count, 2)
        XCTAssertEqual(sut.savedAttractions[0].name, "Eiffel Tower")
        XCTAssertEqual(sut.savedAttractions[1].name, "Louvre Museum")
        XCTAssertEqual(mockCache.replaceCallCount, 1)
    }

    func testLoadSavedPlaces_usesCachedPlaces_whenNetworkFails() async {
        mockCache.cachedPlaces = [TestFixtures.makeSavedPlaceDTO(placeName: "Cached Place")]
        mockService.errorToThrow = NetworkError.noConnection

        await sut.loadSavedPlaces(userId: "test-user-123", snapshotService: mockImageService)

        XCTAssertEqual(sut.savedAttractions.count, 1)
        XCTAssertEqual(sut.savedAttractions.first?.name, "Cached Place")
        XCTAssertNil(sut.error)
    }

    func testLoadSavedPlaces_setsError_onFailure() async {
        mockService.errorToThrow = NetworkError.noConnection

        await sut.loadSavedPlaces(userId: "test-user-123", snapshotService: mockImageService)

        XCTAssertNotNil(sut.error)
    }

    func testLoadSavedPlaces_setsImageURLs_fromDTO() async {
        mockService.placesToReturn = [
            TestFixtures.makeSavedPlaceDTO(imageUrl: "https://example.com/tower.jpg"),
        ]

        await sut.loadSavedPlaces(userId: "test-user-123", snapshotService: mockImageService)

        XCTAssertEqual(mockImageService.setURLCallCount, 1)
    }

    // MARK: - clearAll

    func testClearAll_removesEverything() async {
        mockService.placesToReturn = [TestFixtures.makeSavedPlaceDTO()]
        await sut.loadSavedPlaces(userId: "test-user-123", snapshotService: mockImageService)
        XCTAssertFalse(sut.savedAttractions.isEmpty)

        sut.clearAll()

        XCTAssertTrue(sut.savedAttractions.isEmpty)
    }

    // MARK: - isSaved

    func testIsSaved_matchesByName() {
        let attraction1 = TestFixtures.makeAttraction(name: "Statue of Liberty")
        sut.toggle(attraction1)

        // Different Attraction instance, same name
        let attraction2 = TestFixtures.makeAttraction(name: "Statue of Liberty")
        XCTAssertTrue(sut.isSaved(attraction2))
    }
}
