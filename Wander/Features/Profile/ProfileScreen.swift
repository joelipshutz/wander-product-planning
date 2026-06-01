import SwiftUI

struct ProfileScreen: View {
    @EnvironmentObject private var store: InMemoryWanderStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.currentUser.displayName)
                            .font(.largeTitle.weight(.bold))
                        Text("@\(store.currentUser.handle)")
                            .font(.headline)
                            .foregroundStyle(WanderTheme.espresso.opacity(0.72))
                        if let bio = store.currentUser.bio {
                            Text(bio)
                                .font(.body)
                        }
                    }
                    Spacer()
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                }

                HStack {
                    StatPill(value: "18", label: "been")
                    StatPill(value: "9", label: "wanna")
                    StatPill(value: "6", label: "friends")
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Saved")
                        .font(.headline)
                    ForEach(store.userPlaces.filter { $0.userID == store.currentUser.id }) { userPlace in
                        if let place = store.place(for: userPlace.placeID) {
                            Text(place.canonicalName)
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(WanderTheme.sand.opacity(0.35))
                                .clipShape(RoundedRectangle(cornerRadius: WanderTheme.cornerRadius))
                        }
                    }
                }
            }
            .padding(20)
        }
        .wanderScreen()
    }
}

private struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack {
            Text(value)
                .font(.title2.weight(.bold))
            Text(label)
                .font(.caption.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(WanderTheme.sand.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.cornerRadius))
    }
}
