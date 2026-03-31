import SwiftUI
import MapKit

struct MapSection: View {
    let attractions: [Attraction]
    @Binding var cameraPosition: MapCameraPosition
    @Binding var selectedAttraction: Attraction?

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition, selection: $selectedAttraction) {
                ForEach(attractions) { attraction in
                    Annotation(attraction.name, coordinate: attraction.coordinate) {
                        Image(systemName: attraction.category.icon)
                            .font(.caption)
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(attraction.category.color)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .tag(attraction)
                }
                UserAnnotation()
            }
            .mapControls {
                MapCompass()
                MapUserLocationButton()
            }

            VStack(spacing: 8) {
                ForEach(AttractionCategory.allCases, id: \.self) { category in
                    Image(systemName: category.icon)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(category.color)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.trailing, 12)
            .padding(.top, 12)
        }
        .frame(maxHeight: .infinity)
    }
}
