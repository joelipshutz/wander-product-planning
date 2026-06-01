import SwiftUI

struct MapScreen: View {
    let fixtures: WanderFixtures

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
                    ForEach(fixtures.userPlaces) { userPlace in
                        if let place = fixtures.places.first(where: { $0.id == userPlace.placeID }) {
                            PlaceRow(place: place, userPlace: userPlace)
                        }
                    }
                }
            }
            .padding(20)
        }
        .wanderScreen()
    }
}

private struct PlaceRow: View {
    let place: LocalPlace
    let userPlace: LocalUserPlace

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(userPlace.userID == "user_joe" ? WanderTheme.terracotta : WanderTheme.sky)
                .frame(width: 14, height: 14)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 5) {
                Text(place.canonicalName)
                    .font(.headline)
                Text("\(place.category) · \(userPlace.status.rawValue.replacingOccurrences(of: "_", with: " "))")
                    .font(.subheadline)
                    .foregroundStyle(WanderTheme.espresso.opacity(0.72))
                if let note = userPlace.note {
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
