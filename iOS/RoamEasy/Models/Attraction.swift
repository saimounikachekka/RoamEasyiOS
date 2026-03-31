import Foundation
import CoreLocation
import SwiftUI

struct Attraction: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let city: String
    let state: String
    let country: String
    let coordinate: CLLocationCoordinate2D
    let category: AttractionCategory

    var locationLabel: String {
        "\(city), \(state)"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Attraction, rhs: Attraction) -> Bool {
        lhs.id == rhs.id
    }
}

enum AttractionCategory: String, CaseIterable {
    case landmark = "Landmarks"
    case park = "Parks"
    case museum = "Museums"
    case entertainment = "Entertainment"

    var icon: String {
        switch self {
        case .landmark: return "building.columns.fill"
        case .park: return "leaf.fill"
        case .museum: return "building.fill"
        case .entertainment: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .landmark: return .orange
        case .park: return .green
        case .museum: return .purple
        case .entertainment: return .blue
        }
    }

    var searchQuery: String {
        switch self {
        case .landmark: return "landmarks"
        case .park: return "parks"
        case .museum: return "museums"
        case .entertainment: return "attractions entertainment"
        }
    }
}
