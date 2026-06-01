import SwiftUI

struct MapScreen: View {
    @EnvironmentObject private var store: InMemoryWanderStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your people know places")
                        .font(.largeTitle.weight(.bold))
                    Text("Coffee, hikes, dinner saves, and the little notes that make a pin useful.")
                        .font(.body)
                }

                HStack {
                    WanderChip(title: "You", isSelected: true)
                    WanderChip(title: "Following")
                    WanderChip(title: "Friends")
                }

                VStack(spacing: 12) {
                    ForEach(store.visiblePlaces()) { visiblePlace in
                        PlaceRow(visiblePlace: visiblePlace)
                    }
                }
            }
            .padding(20)
        }
        .wanderScreen()
    }
}

private struct PlaceRow: View {
    let visiblePlace: VisiblePlace

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(visiblePlace.owner.id == "user_joe" ? WanderTheme.terracotta : WanderTheme.sky)
                .frame(width: 14, height: 14)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 5) {
                Text(visiblePlace.place.canonicalName)
                    .font(.headline)
                Text("\(visiblePlace.place.category) · \(visiblePlace.userPlace.status.rawValue.replacingOccurrences(of: "_", with: " ")) · @\(visiblePlace.owner.handle)")
                    .font(.subheadline)
                    .foregroundStyle(WanderTheme.espresso.opacity(0.72))
                if let note = visiblePlace.userPlace.note {
                    Text(note)
                        .font(.footnote)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(WanderTheme.sand.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.cornerRadius))
    }
}
