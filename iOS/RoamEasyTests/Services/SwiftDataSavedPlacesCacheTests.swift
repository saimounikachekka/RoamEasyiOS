import XCTest
import SwiftData
@testable import RoamEasy

final class SwiftDataSavedPlacesCacheTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var sut: SwiftDataSavedPlacesCache!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let schema = Schema([CachedSavedPlace.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [configuration])
        context = ModelContext(container)
        sut = SwiftDataSavedPlacesCache(context: context)
    }

    override func tearDownWithError() throws {
        sut = nil
        context = nil
        container = nil
        try super.tearDownWithError()
    }

    func testFetchCachedPlaces_returnsOnlyRequestedUserPlaces() throws {
        try sut.saveCachedPlace(TestFixtures.makeSavedPlaceDTO(userId: "user-1", placeId: "place-1"))
        try sut.saveCachedPlace(TestFixtures.makeSavedPlaceDTO(userId: "user-2", placeId: "place-2"))

        let places = try sut.fetchCachedPlaces(userId: "user-1")

        XCTAssertEqual(places.count, 1)
        XCTAssertEqual(places.first?.userId, "user-1")
        XCTAssertEqual(places.first?.placeId, "place-1")
    }

    func testReplaceCachedPlaces_replacesExistingPlacesForUser() throws {
        try sut.saveCachedPlace(TestFixtures.makeSavedPlaceDTO(userId: "user-1", placeId: "old-place"))
        try sut.saveCachedPlace(TestFixtures.makeSavedPlaceDTO(userId: "user-2", placeId: "other-user-place"))

        let replacementPlaces = [
            TestFixtures.makeSavedPlaceDTO(userId: "user-1", placeId: "new-place-1", placeName: "First"),
            TestFixtures.makeSavedPlaceDTO(userId: "user-1", placeId: "new-place-2", placeName: "Second")
        ]

        try sut.replaceCachedPlaces(replacementPlaces, userId: "user-1")

        let userOnePlaces = try sut.fetchCachedPlaces(userId: "user-1")
        let userTwoPlaces = try sut.fetchCachedPlaces(userId: "user-2")

        XCTAssertEqual(userOnePlaces.map(\.placeId).sorted(), ["new-place-1", "new-place-2"])
        XCTAssertEqual(userTwoPlaces.map(\.placeId), ["other-user-place"])
    }

    func testSaveCachedPlace_updatesExistingPlaceWithSamePlaceId() throws {
        try sut.saveCachedPlace(TestFixtures.makeSavedPlaceDTO(
            userId: "user-1",
            placeId: "place-1",
            city: "Paris",
            placeName: "Old Name"
        ))

        try sut.saveCachedPlace(TestFixtures.makeSavedPlaceDTO(
            userId: "user-1",
            placeId: "place-1",
            city: "Lyon",
            placeName: "New Name"
        ))

        let places = try sut.fetchCachedPlaces(userId: "user-1")

        XCTAssertEqual(places.count, 1)
        XCTAssertEqual(places.first?.placeName, "New Name")
        XCTAssertEqual(places.first?.city, "Lyon")
    }

    func testDeleteCachedPlace_removesPlace() throws {
        try sut.saveCachedPlace(TestFixtures.makeSavedPlaceDTO(userId: "user-1", placeId: "place-1"))

        try sut.deleteCachedPlace(placeId: "place-1")

        let places = try sut.fetchCachedPlaces(userId: "user-1")
        XCTAssertTrue(places.isEmpty)
    }
}
