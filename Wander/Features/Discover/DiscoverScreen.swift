import SwiftUI

struct DiscoverScreen: View {
    @EnvironmentObject private var store: InMemoryWanderStore
    @State private var query = "hikes in LA"
    @State private var parsedFilters = DiscoverFilters(query: "hikes in LA", categories: ["hike"])
    private let parser = CheapFixtureFilterParser()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Discover")
                .font(.largeTitle.weight(.bold))

            TextField("hikes in LA", text: $query)
                .textFieldStyle(.plain)
                .padding(16)
                .background(WanderTheme.sand.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: WanderTheme.cornerRadius))
                .onSubmit {
                    Task { await parseQuery() }
                }

            HStack {
                ForEach(Array(parsedFilters.categories).sorted(), id: \.self) { category in
                    WanderChip(title: category, isSelected: true)
                }
                if parsedFilters.categories.isEmpty {
                    WanderChip(title: "smart filters", isSelected: true)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Places")
                    .font(.headline)
                ForEach(store.visiblePlaces(for: parsedFilters)) { visiblePlace in
                    DiscoverPlaceRow(visiblePlace: visiblePlace)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Find people")
                    .font(.headline)
                ForEach(store.contactsMatchingAppUsers()) { contact in
                    ContactRow(contact: contact)
                }
                ForEach(store.profiles.filter { $0.id != store.currentUser.id }) { profile in
                    ProfileSearchRow(profile: profile)
                }
            }

            Spacer()
        }
        .padding(20)
        .wanderScreen()
    }

    private func parseQuery() async {
        let schema = DiscoverFilterSchema(
            allowedCategories: ["coffee", "hike", "restaurant", "bar", "park", "wellness"],
            allowedStatuses: [.been, .wannaGo]
        )
        parsedFilters = (try? await parser.parse(query: query, schema: schema)) ?? DiscoverFilters(query: query)
    }
}

private struct ProfileSearchRow: View {
    @EnvironmentObject private var store: InMemoryWanderStore
    let profile: LocalProfile

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(profile.displayName)
                    .font(.headline)
                Text("@\(profile.handle)")
                    .font(.subheadline)
                    .foregroundStyle(WanderTheme.espresso.opacity(0.7))
            }
            Spacer()
            Button(actionTitle) {
                Task {
                    if await isFollowing {
                        try? await store.unfollow(userID: profile.id)
                    } else {
                        try? await store.follow(userID: profile.id)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(WanderTheme.terracotta)
        }
        .padding(16)
        .background(WanderTheme.sand.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.cornerRadius))
    }

    private var isFollowing: Bool {
        get async {
            (try? await store.relationship(to: profile.id)) != .nonFollower
        }
    }

    private var actionTitle: String {
        let followingIDs = Set(store.followingProfiles().map(\.id))
        return followingIDs.contains(profile.id) ? "Following" : "Follow"
    }
}

private struct DiscoverPlaceRow: View {
    let visiblePlace: VisiblePlace

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: visiblePlace.userPlace.status == .been ? "mappin.circle.fill" : "mappin.and.ellipse")
                .foregroundStyle(visiblePlace.owner.id == "user_joe" ? WanderTheme.terracotta : WanderTheme.sky)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(visiblePlace.place.canonicalName)
                    .font(.headline)
                Text("@\(visiblePlace.owner.handle) · \(visiblePlace.place.category)")
                    .font(.subheadline)
                    .foregroundStyle(WanderTheme.espresso.opacity(0.7))
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

private struct ContactRow: View {
    @EnvironmentObject private var store: InMemoryWanderStore
    let contact: ContactMatch

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.displayName)
                    .font(.headline)
                Text(contact.handle.map { "@\($0)" } ?? "invite later")
                    .font(.subheadline)
                    .foregroundStyle(WanderTheme.espresso.opacity(0.7))
            }
            Spacer()
            if let userID = contact.userID {
                Button("Follow") {
                    Task { try? await store.follow(userID: userID) }
                }
                .buttonStyle(.borderedProminent)
                .tint(WanderTheme.terracotta)
            } else {
                WanderChip(title: "Planned", isSelected: false)
            }
        }
        .padding(16)
        .background(WanderTheme.sand.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.cornerRadius))
    }
}
