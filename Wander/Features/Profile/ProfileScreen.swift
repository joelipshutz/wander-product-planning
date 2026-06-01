import SwiftUI

struct ProfileScreen: View {
    @EnvironmentObject private var store: InMemoryWanderStore
    @State private var selectedProfileID: String?

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
                    StatPill(value: "\(store.userPlaceCount(for: .been, userID: store.currentUser.id))", label: "been")
                    StatPill(value: "\(store.userPlaceCount(for: .wannaGo, userID: store.currentUser.id))", label: "wanna")
                    StatPill(value: "\(store.followingProfiles().count)", label: "following")
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Following")
                        .font(.headline)
                    ForEach(store.followingProfiles()) { profile in
                        SocialProfileRow(profile: profile, actionTitle: "Block") {
                            Task { try? await store.block(userID: profile.id) }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Following you")
                        .font(.headline)
                    ForEach(store.followerProfiles()) { profile in
                        SocialProfileRow(profile: profile, actionTitle: "View") {
                            selectedProfileID = profile.id
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Saved")
                        .font(.headline)
                    ForEach(store.userPlaces.filter { $0.userID == store.currentUser.id }) { userPlace in
                        if let place = store.place(for: userPlace.placeID) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(place.canonicalName)
                                    .font(.headline)
                                Text("\(userPlace.status.rawValue.replacingOccurrences(of: "_", with: " ")) · \(userPlace.visibility.rawValue)")
                                    .font(.subheadline)
                                    .foregroundStyle(WanderTheme.espresso.opacity(0.7))
                            }
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
        .sheet(item: selectedProfileBinding) { profile in
            PublicProfileSheet(profile: profile)
                .environmentObject(store)
        }
    }

    private var selectedProfileBinding: Binding<LocalProfile?> {
        Binding(
            get: { selectedProfileID.flatMap { store.profile(for: $0) } },
            set: { selectedProfileID = $0?.id }
        )
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

private struct SocialProfileRow: View {
    let profile: LocalProfile
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.displayName)
                    .font(.headline)
                Text("@\(profile.handle)")
                    .font(.subheadline)
                    .foregroundStyle(WanderTheme.espresso.opacity(0.7))
            }
            Spacer()
            Button(actionTitle, action: action)
                .buttonStyle(.bordered)
                .tint(actionTitle == "Block" ? WanderTheme.clay : WanderTheme.terracotta)
        }
        .padding(16)
        .background(WanderTheme.sand.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.cornerRadius))
    }
}

private struct PublicProfileSheet: View {
    @EnvironmentObject private var store: InMemoryWanderStore
    let profile: LocalProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(profile.displayName)
                .font(.largeTitle.weight(.bold))
            Text("@\(profile.handle)")
                .font(.headline)
                .foregroundStyle(WanderTheme.espresso.opacity(0.7))
            if let bio = profile.bio {
                Text(bio)
            }
            HStack {
                Button("Follow") {
                    Task { try? await store.follow(userID: profile.id) }
                }
                .buttonStyle(.borderedProminent)
                .tint(WanderTheme.terracotta)
                Button("Block") {
                    Task { try? await store.block(userID: profile.id) }
                }
                .buttonStyle(.bordered)
                .tint(WanderTheme.clay)
            }
            Spacer()
        }
        .padding(24)
        .wanderScreen()
    }
}
