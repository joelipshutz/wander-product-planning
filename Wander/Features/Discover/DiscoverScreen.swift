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
                Text("People")
                    .font(.headline)
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
            Button("Follow") {
                Task { try? await store.follow(userID: profile.id) }
            }
            .buttonStyle(.borderedProminent)
            .tint(WanderTheme.terracotta)
        }
        .padding(16)
        .background(WanderTheme.sand.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.cornerRadius))
    }
}
