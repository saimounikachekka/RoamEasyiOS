import SwiftUI

struct AttractionsCarousel: View {
    let attractions: [Attraction]
    let snapshotService: MapSnapshotService
    let isSaved: (Attraction) -> Bool
    let onSave: (Attraction) -> Void
    let onSelect: (Attraction) -> Void

    @State private var scrollIndex = 0
    private let cardsPerPage = 2

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if attractions.isEmpty {
                Text("No attractions found nearby.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(Array(attractions.enumerated()), id: \.element.id) { index, attraction in
                                AttractionCard(
                                    attraction: attraction,
                                    snapshotService: snapshotService,
                                    isSaved: isSaved(attraction),
                                    onSave: { onSave(attraction) }
                                )
                                .id(index)
                                .onTapGesture {
                                    onSelect(attraction)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .onChange(of: scrollIndex) { _, newIndex in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(newIndex, anchor: .leading)
                        }
                    }
                }
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
        .onChange(of: attractions) { _, _ in
            scrollIndex = 0
        }
    }

    private var header: some View {
        HStack {
            Text("Top Attractions")
                .font(.title3)
                .fontWeight(.bold)
            Spacer()
            if !attractions.isEmpty {
                HStack(spacing: 12) {
                    Button {
                        guard scrollIndex > 0 else { return }
                        scrollIndex -= cardsPerPage
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(scrollIndex > 0 ? .blue : .gray.opacity(0.4))
                    }
                    .disabled(scrollIndex <= 0)

                    Button {
                        guard scrollIndex + cardsPerPage < attractions.count else { return }
                        scrollIndex += cardsPerPage
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(
                                scrollIndex + cardsPerPage < attractions.count ? .blue : .gray.opacity(0.4)
                            )
                    }
                    .disabled(scrollIndex + cardsPerPage >= attractions.count)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}
