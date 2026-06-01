import SwiftUI

@MainActor
struct WanderRootView: View {
    @State private var selectedTab: WanderTab = .map
    @StateObject private var store: WanderStore

    init() {
        _store = StateObject(wrappedValue: WanderStore(fixtures: WanderFixtures.seed()))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            MapScreen()
                .tabItem { Label(WanderTab.map.title, systemImage: WanderTab.map.systemImage) }
                .tag(WanderTab.map)

            AddScreen()
                .tabItem { Label(WanderTab.add.title, systemImage: WanderTab.add.systemImage) }
                .tag(WanderTab.add)

            DiscoverScreen()
                .tabItem { Label(WanderTab.discover.title, systemImage: WanderTab.discover.systemImage) }
                .tag(WanderTab.discover)

            ProfileScreen()
                .tabItem { Label(WanderTab.profile.title, systemImage: WanderTab.profile.systemImage) }
                .tag(WanderTab.profile)
        }
        .tint(WanderTheme.terracotta.color)
        .environmentObject(store)
    }
}

enum WanderTab: String, CaseIterable, Hashable {
    case map
    case add
    case discover
    case profile

    var title: String {
        switch self {
        case .map: "Map"
        case .add: "Add"
        case .discover: "Discover"
        case .profile: "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .map: "map"
        case .add: "plus.circle.fill"
        case .discover: "sparkle.magnifyingglass"
        case .profile: "person.crop.circle"
        }
    }
}
