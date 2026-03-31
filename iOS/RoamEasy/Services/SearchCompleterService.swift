import MapKit

@MainActor
final class SearchCompleterService: NSObject, ObservableObject {
    @Published var suggestions: [MKLocalSearchCompletion] = []

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    func update(query: String) {
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            suggestions = []
        } else {
            completer.queryFragment = query
        }
    }

    func clear() {
        suggestions = []
        completer.queryFragment = ""
    }

    /// Returns true if the title represents a city, region, or country (not a street address).
    nonisolated static func isCityOrCountry(title: String) -> Bool {
        guard !title.isEmpty else { return false }
        // Street addresses start with a number (e.g. "123 Main St")
        if title.first?.isNumber ?? false { return false }
        return true
    }
}

extension SearchCompleterService: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results.filter { completion in
            SearchCompleterService.isCityOrCountry(title: completion.title)
        }
        Task { @MainActor in
            self.suggestions = results
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error.localizedDescription)")
    }
}
