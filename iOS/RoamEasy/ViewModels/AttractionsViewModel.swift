import MapKit

@MainActor
final class AttractionsViewModel: ObservableObject {
    @Published var attractions: [Attraction] = []
    @Published var isLoading = false
    @Published var cityName: String = ""
    @Published var error: NetworkError?

    func searchNearby(coordinate: CLLocationCoordinate2D, radiusMeters: Double = 15_000) async {
        isLoading = true
        defer { isLoading = false }

        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        if let placemarks = try? await geocoder.reverseGeocodeLocation(location),
           let placemark = placemarks.first {
            cityName = placemark.locality ?? placemark.administrativeArea ?? ""
        }

        var allAttractions: [Attraction] = []
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: radiusMeters * 2,
            longitudinalMeters: radiusMeters * 2
        )

        for category in AttractionCategory.allCases {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = category.searchQuery
            request.region = region
            if #available(iOS 18.0, *) {
                request.regionPriority = .required
            }
            request.resultTypes = .pointOfInterest

            do {
                let search = MKLocalSearch(request: request)
                let response = try await search.start()

                let centerLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                let results = response.mapItems.compactMap { item -> Attraction? in
                    guard let name = item.name else { return nil }
                    if allAttractions.contains(where: { $0.name == name }) { return nil }
                    let itemLocation = CLLocation(latitude: item.placemark.coordinate.latitude, longitude: item.placemark.coordinate.longitude)
                    guard itemLocation.distance(from: centerLocation) <= radiusMeters else { return nil }
                    let placemark = item.placemark
                    let city = placemark.locality ?? placemark.subAdministrativeArea ?? "Unknown"
                    let state = placemark.administrativeArea ?? placemark.country ?? ""
                    let country = placemark.country ?? ""
                    return Attraction(
                        name: name,
                        city: city,
                        state: state,
                        country: country,
                        coordinate: item.placemark.coordinate,
                        category: category
                    )
                }
                allAttractions.append(contentsOf: results)
            } catch {
                print("Search for '\(category.searchQuery)' failed: \(error.localizedDescription)")
            }
        }

        attractions = allAttractions
    }

    func searchForCity(_ query: String) async {
        guard !query.isEmpty else { return }
        isLoading = true

        let geocodeRequest = MKLocalSearch.Request()
        geocodeRequest.naturalLanguageQuery = query
        geocodeRequest.resultTypes = .address

        do {
            let geocodeSearch = MKLocalSearch(request: geocodeRequest)
            let geocodeResponse = try await geocodeSearch.start()
            guard let firstResult = geocodeResponse.mapItems.first else {
                isLoading = false
                return
            }

            // Estimate radius from the bounding region span
            let span = geocodeResponse.boundingRegion.span
            let spanMeters = max(
                span.latitudeDelta * 111_000,
                span.longitudeDelta * 111_000 * cos(firstResult.placemark.coordinate.latitude * .pi / 180)
            )
            // Use half the span as radius, clamped between 15km and 500km
            let radius = min(max(spanMeters / 2, 15_000), 500_000)

            await searchNearby(coordinate: firstResult.placemark.coordinate, radiusMeters: radius)
        } catch {
            print("Geocode failed: \(error.localizedDescription)")
            isLoading = false
        }
    }
}
