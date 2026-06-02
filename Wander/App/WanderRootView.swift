import SwiftUI

@MainActor
struct WanderRootView: View {
    @EnvironmentObject private var auth: AuthSessionStore
    @State private var selectedTab: WanderTab
    @State private var initialPresentation: WanderInitialPresentation?
    @StateObject private var store: WanderStore

    init(initialTab: WanderTab? = nil, initialPresentation: WanderInitialPresentation? = nil) {
        _selectedTab = State(initialValue: initialTab ?? Self.resolvedInitialTab())
        _initialPresentation = State(initialValue: initialPresentation ?? Self.resolvedInitialPresentation())
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
        .sheet(item: $auth.activeGate) { request in
            AuthGateSheet(request: request)
                .environmentObject(auth)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $auth.isPresentingNativeAuth) {
            ClerkNativeAuthView()
                .environmentObject(auth)
        }
        .sheet(item: $initialPresentation) { presentation in
            switch presentation {
            case .settings:
                SettingsScreen()
                    .environmentObject(store)
                    .environmentObject(auth)
            }
        }
        .task {
            await auth.refreshSession()
        }
        .onChange(of: auth.isPresentingNativeAuth) { _, isPresenting in
            guard !isPresenting else { return }
            Task { await auth.refreshSession() }
        }
    }

    static func resolvedInitialTab(from arguments: [String] = ProcessInfo.processInfo.arguments) -> WanderTab {
        guard let flagIndex = arguments.firstIndex(of: "-WanderInitialTab") else {
            return .map
        }

        let valueIndex = arguments.index(after: flagIndex)
        guard arguments.indices.contains(valueIndex) else {
            return .map
        }

        return WanderTab(rawValue: arguments[valueIndex]) ?? .map
    }

    static func resolvedInitialPresentation(from arguments: [String] = ProcessInfo.processInfo.arguments) -> WanderInitialPresentation? {
        arguments.contains("-WanderOpenSettings") ? .settings : nil
    }
}

enum WanderInitialPresentation: String, Identifiable {
    case settings

    var id: String { rawValue }
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
