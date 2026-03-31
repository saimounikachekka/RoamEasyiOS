import SwiftUI

struct AttractionCard: View {
    let attraction: Attraction
    let snapshotService: any ImageServiceProtocol
    var isSaved: Bool = false
    var onSave: (() -> Void)?

    @State private var imageURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Attraction photo
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    default:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.systemGray5))
                    }
                }
                .frame(width: 160, height: 110)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Bookmark button
                Button {
                    onSave?()
                } label: {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(5)
                        .background(.black.opacity(0.4))
                        .clipShape(Circle())
                }
                .padding(6)
                .accessibilityLabel("Save \(attraction.name)")
            }

            // Name
            Text(attraction.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)

            // City, State
            Text(attraction.locationLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: 160)
        .task {
            imageURL = await snapshotService.imageURL(for: attraction)
        }
    }

    private var placeholder: some View {
        Image(systemName: "photo.fill")
            .font(.title2)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGray5))
    }
}
