import SwiftUI

struct ProfileScreen: View {
    @EnvironmentObject private var store: WanderStore
    @State private var showsSettings = false
    @State private var listMode: GraphListMode?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: WanderTheme.spacing6) {
                    ownerHeader
                    statsGrid
                    monthCard
                    draftsSection
                    recentSection
                }
                .padding(WanderTheme.spacing4)
                .padding(.bottom, WanderTheme.spacing8)
            }
            .wanderScreen()
            .sheet(isPresented: $showsSettings) {
                SettingsScreen()
                    .environmentObject(store)
            }
            .sheet(item: $listMode) { mode in
                GraphListScreen(mode: mode)
                    .environmentObject(store)
            }
        }
    }

    private var ownerHeader: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing4) {
            HStack(alignment: .top) {
                WanderAvatar(initials: store.currentUser.initials, size: 64, color: WanderTheme.terracotta.color)

                VStack(alignment: .leading, spacing: WanderTheme.spacing1) {
                    Text(store.currentUser.displayName)
                        .font(.system(size: 28, weight: .black))
                    Text("@\(store.currentUser.handle) · \(store.currentUser.homeArea ?? "Los Angeles")")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(WanderTheme.textMuted.color)
                }

                Spacer()

                Button {
                    showsSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20, weight: .bold))
                        .frame(width: 44, height: 44)
                        .background(WanderTheme.surfaceSand.color)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Settings")
            }

            Text(store.currentUser.bio ?? "always down for a detour")
                .font(.system(size: 16))
                .italic()
                .foregroundStyle(WanderTheme.textMuted.color)
        }
        .padding(WanderTheme.spacing4)
        .background(WanderTheme.surfaceBone.color)
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusLarge))
    }

    private var statsGrid: some View {
        HStack(spacing: WanderTheme.spacing3) {
            StatTile(value: "\(store.stats.been)", label: "BEEN", color: WanderTheme.terracotta.color, fill: WanderTheme.terracottaTint.color)
            StatTile(value: "\(store.stats.wanna)", label: "WANNA", color: WanderTheme.stateWarning.color, fill: WanderTheme.sunTint.color)
            Button {
                listMode = .following
            } label: {
                StatTile(value: "\(store.stats.friends)", label: "FRIENDS", color: WanderTheme.stateInfo.color, fill: WanderTheme.skyTint.color)
            }
            .buttonStyle(.plain)
        }
    }

    private var monthCard: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing3) {
            HStack {
                Text("this month")
                    .font(.system(size: 18, weight: .black))
                Spacer()
                Text("JUN '26")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(WanderTheme.textMuted.color)
            }

            HStack(alignment: .center, spacing: WanderTheme.spacing4) {
                Text("\(store.currentUserVisiblePlaces.count)")
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(WanderTheme.terracotta.color)
                Text("saved places so far. mostly coffee + a couple from friends' tips.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(WanderTheme.textMuted.color)
                Spacer()
            }
            .padding(WanderTheme.spacing4)
            .background(WanderTheme.surfaceBone.color)
            .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusLarge))
        }
    }

    private var draftsSection: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing3) {
            Text("drafts")
                .font(.system(size: 18, weight: .black))

            if store.unresolvedDrafts.isEmpty {
                SmallEmptyRow(title: "No unresolved drafts", subtitle: "link and photo shells land here")
            } else {
                ForEach(store.unresolvedDrafts) { draft in
                    HStack {
                        Image(systemName: draft.sourceType == .link ? "link" : "photo")
                            .foregroundStyle(WanderTheme.terracotta.color)
                        VStack(alignment: .leading) {
                            Text(draft.title)
                                .font(.system(size: 15, weight: .bold))
                            Text(draft.message)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(WanderTheme.textMuted.color)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(WanderTheme.spacing4)
                    .background(WanderTheme.surfaceBone.color)
                    .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusLarge))
                }
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing3) {
            HStack {
                Text("recent")
                    .font(.system(size: 18, weight: .black))
                Spacer()
                Button("following") {
                    listMode = .following
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(WanderTheme.terracotta.color)
            }

            ForEach(store.currentUserVisiblePlaces) { visiblePlace in
                ProfilePlaceRow(visiblePlace: visiblePlace)
            }
        }
    }
}

struct ProfileDetailView: View {
    @EnvironmentObject private var store: WanderStore
    let profileID: String
    @State private var showBlockConfirm = false

    private var state: ProfileViewState? {
        store.profileState(for: profileID)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let state {
                    VStack(alignment: .leading, spacing: WanderTheme.spacing6) {
                        profileHeader(state: state)

                        if state.isBlocked {
                            AccessChangedPanel(title: "This profile isn't available", subtitle: "Blocked profiles stay out of search, lists, and map results.")
                        } else if state.visiblePlaces.isEmpty && state.shell.relationship == .nonFollower {
                            AccessChangedPanel(title: "Follow to see shared places", subtitle: "You'll only see places this person shares with followers.")
                        } else {
                            ForEach(state.visiblePlaces) { visiblePlace in
                                ProfilePlaceRow(visiblePlace: visiblePlace)
                            }
                        }
                    }
                    .padding(WanderTheme.spacing4)
                }
            }
            .wanderScreen()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Block this person?", isPresented: $showBlockConfirm, titleVisibility: .visible) {
                Button("Block", role: .destructive) {
                    store.block(userID: profileID)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You won't see each other's profiles, places, or search results.")
            }
        }
    }

    private func profileHeader(state: ProfileViewState) -> some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing4) {
            HStack(alignment: .top) {
                WanderAvatar(initials: initials(for: state.shell.displayName), size: 64, color: WanderTheme.pinSocial.color)

                VStack(alignment: .leading, spacing: WanderTheme.spacing1) {
                    Text(state.shell.displayName)
                        .font(.system(size: 26, weight: .black))
                        .lineLimit(1)
                    Text("@\(state.shell.handle) · \(state.shell.relationship.displayTitle)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(WanderTheme.textMuted.color)
                }

                Spacer()

                Menu {
                    Button("Block", role: .destructive) {
                        showBlockConfirm = true
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: 44, height: 44)
                        .background(WanderTheme.surfaceSand.color)
                        .clipShape(Circle())
                }
            }

            if let bio = state.shell.bio {
                Text(bio)
                    .font(.system(size: 15))
                    .italic()
                    .foregroundStyle(WanderTheme.textMuted.color)
            }

            HStack {
                if state.shell.relationship == .nonFollower && !state.isBlocked {
                    WanderPrimaryButton(title: "follow", systemImage: "person.badge.plus") {
                        store.follow(userID: state.shell.id)
                    }
                } else if state.shell.relationship != .owner && !state.isBlocked {
                    Button {
                        store.unfollow(userID: state.shell.id)
                    } label: {
                        Text(state.shell.relationship == .mutual ? "friend" : "following")
                            .font(.system(size: 15, weight: .bold))
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(WanderTheme.surfaceSand.color)
                            .foregroundStyle(WanderTheme.textInk.color)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(WanderTheme.spacing4)
        .background(WanderTheme.surfaceBone.color)
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusLarge))
    }

    private func initials(for name: String) -> String {
        name
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
    }
}

private enum GraphListMode: String, Identifiable {
    case followers
    case following

    var id: String { rawValue }
}

private struct GraphListScreen: View {
    @EnvironmentObject private var store: WanderStore
    let mode: GraphListMode

    private var profiles: [LocalProfile] {
        switch mode {
        case .followers:
            return store.followers(of: store.currentUser.id)
        case .following:
            return store.following(of: store.currentUser.id)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(profiles, id: \.id) { profile in
                    HStack {
                        WanderAvatar(initials: profile.initials, size: 40, color: WanderTheme.pinSocial.color)
                        VStack(alignment: .leading) {
                            Text(profile.displayName)
                                .font(.system(size: 15, weight: .bold))
                            Text("@\(profile.handle) · \(store.relationship(to: profile.id).displayTitle)")
                                .font(.system(size: 13))
                                .foregroundStyle(WanderTheme.textMuted.color)
                        }
                        Spacer()
                        Button(store.relationship(to: profile.id) == .nonFollower ? "follow" : "unfollow") {
                            store.relationship(to: profile.id) == .nonFollower ? store.follow(userID: profile.id) : store.unfollow(userID: profile.id)
                        }
                        .font(.system(size: 13, weight: .bold))
                    }
                    .listRowBackground(WanderTheme.surfaceBone.color)
                }
            }
            .scrollContentBackground(.hidden)
            .wanderScreen()
            .navigationTitle(mode.rawValue.capitalized)
        }
    }
}

private struct StatTile: View {
    let value: String
    let label: String
    let color: Color
    let fill: Color

    var body: some View {
        VStack(spacing: WanderTheme.spacing1) {
            Text(value)
                .font(.system(size: 30, weight: .black))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(WanderTheme.textMuted.color)
        }
        .frame(maxWidth: .infinity, minHeight: 82)
        .background(fill)
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusLarge))
    }
}

private struct ProfilePlaceRow: View {
    let visiblePlace: VisiblePlace

    var body: some View {
        HStack(spacing: WanderTheme.spacing3) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(WanderTheme.terracotta.color)
                .frame(width: 44, height: 44)
                .background(WanderTheme.terracottaTint.color)
                .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusSmall))
            VStack(alignment: .leading, spacing: WanderTheme.spacing1) {
                Text(visiblePlace.place.canonicalName)
                    .font(.system(size: 16, weight: .bold))
                Text("\(visiblePlace.place.locality ?? "Los Angeles") · \(visiblePlace.userPlace.status.displayTitle)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(WanderTheme.textMuted.color)
            }
            Spacer()
            Text(visiblePlace.userPlace.visibility.displayTitle)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(WanderTheme.textMuted.color)
        }
        .padding(WanderTheme.spacing4)
        .background(WanderTheme.surfaceBone.color)
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusLarge))
    }

    private var icon: String {
        switch visiblePlace.place.category {
        case "coffee": "cup.and.saucer.fill"
        case "hike": "figure.hiking"
        case "restaurant": "fork.knife"
        default: "mappin"
        }
    }
}

private struct SmallEmptyRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing1) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
            Text(subtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(WanderTheme.textMuted.color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(WanderTheme.spacing4)
        .background(WanderTheme.surfaceBone.color)
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusLarge))
    }
}

private struct AccessChangedPanel: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing2) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
            Text(subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(WanderTheme.textMuted.color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(WanderTheme.spacing4)
        .background(WanderTheme.surfaceSand.color)
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusLarge))
    }
}
