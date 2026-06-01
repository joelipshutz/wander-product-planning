import SwiftUI

struct DiscoverScreen: View {
    let fixtures: WanderFixtures
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
                ForEach(fixtures.profiles.filter { $0.id != fixtures.currentUser.id }) { profile in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(profile.displayName)
                                .font(.headline)
                            Text("@\(profile.handle)")
                                .font(.subheadline)
                                .foregroundStyle(WanderTheme.espresso.opacity(0.7))
                        }
                        Spacer()
                        WanderChip(title: "Follow")
                    }
                    .padding(16)
                    .background(WanderTheme.sand.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: WanderTheme.cornerRadius))
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
