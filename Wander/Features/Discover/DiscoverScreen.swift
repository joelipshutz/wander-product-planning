import SwiftUI

struct DiscoverScreen: View {
    @EnvironmentObject private var store: WanderStore
    @EnvironmentObject private var auth: AuthSessionStore
    @EnvironmentObject private var backend: WanderBackend
    @State private var query = ""
    @State private var results = DiscoverResults(places: [], profiles: [])
    @State private var contacts: [ContactMatch] = []
    @State private var selectedProfile: SelectedProfile?
    @State private var savedMessage: String?
    @State private var selectedScope: DiscoverPlaceScope = .everyone
    @FocusState private var searchFieldFocused: Bool

    private var matchedContacts: [ContactMatch] {
        contacts.filter(\.isMatchedUser)
    }

    private var contactUserIDs: Set<String> {
        Set(matchedContacts.compactMap(\.userID))
    }

    private var profileResults: [ProfileShell] {
        results.profiles.filter { !contactUserIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: WanderTheme.spacing4) {
                    header
                    searchField
                    peopleSection
                    resultsSection
                }
                .padding(WanderTheme.spacing4)
                .padding(.bottom, WanderTheme.spacing8)
            }
            .scrollDismissesKeyboard(.interactively)
            .wanderScreen()
            .task {
                contacts = await store.contactMatches()
                await refresh()
            }
            .onChange(of: query) { _, _ in
                Task { await refresh() }
            }
            .onChange(of: selectedScope) { _, _ in
                Task { await refresh() }
            }
            .sheet(item: $selectedProfile) { profile in
                ProfileDetailView(profileID: profile.id)
                    .environmentObject(store)
                    .environmentObject(auth)
                    .environmentObject(backend)
            }
            .alert("Saved to your map", isPresented: Binding(get: { savedMessage != nil }, set: { if !$0 { savedMessage = nil } })) {
                Button("OK", role: .cancel) { savedMessage = nil }
            } message: {
                Text(savedMessage ?? "")
            }
        }
    }

    private var header: some View {
        Text("discover")
            .font(.system(size: 30, weight: .black, design: .rounded))
            .lineLimit(1)
    }

    private var searchField: some View {
        HStack(spacing: WanderTheme.spacing2) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(WanderTheme.textMuted.color)
            TextField("hikes in LA, @maya, coffee...", text: $query)
                .font(.system(size: 15, weight: .medium))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($searchFieldFocused)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(WanderTheme.textFaint.color)
                }
            }
        }
        .padding(.horizontal, WanderTheme.spacing3)
        .frame(minHeight: 50)
        .background(WanderTheme.surfaceRaised.color)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(WanderTheme.borderHairline.color))
    }

    private var peopleSection: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing3) {
            SectionTitle("people")

            HStack(alignment: .top, spacing: WanderTheme.spacing3) {
                AddPersonCard {
                    query = "@"
                    searchFieldFocused = true
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: WanderTheme.spacing2) {
                        ForEach(matchedContacts) { contact in
                            ContactCard(contact: contact) {
                                if let userID = contact.userID {
                                    selectedProfile = SelectedProfile(id: userID)
                                }
                            } follow: {
                                if let userID = contact.userID {
                                    auth.requireSignIn(for: .followPeople) {
                                        Task {
                                            await store.follow(userID: userID, source: .contacts, backend: backend)
                                            await refresh()
                                        }
                                    }
                                }
                            }
                        }

                        ForEach(profileResults) { profile in
                            ProfileMiniCard(profile: profile) {
                                selectedProfile = SelectedProfile(id: profile.id)
                            } follow: {
                                auth.requireSignIn(for: .followPeople) {
                                    Task {
                                        await store.follow(userID: profile.id, source: .username, backend: backend)
                                        await refresh()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, WanderTheme.spacing1)
                }
            }
        }
    }

    private var scopeToggle: some View {
        WanderSegmentedSwitch(
            options: DiscoverPlaceScope.allCases.map { scope in
                WanderSegmentOption(id: scope.rawValue, title: scope.title)
            },
            selection: Binding(
                get: { selectedScope.rawValue },
                set: { selectedScope = DiscoverPlaceScope(rawValue: $0) ?? .everyone }
            )
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Discover place source")
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing3) {
            SectionTitle("places")
            scopeToggle

            if results.places.isEmpty {
                EmptyPanel(title: "No places here yet", action: selectedScope == .myPlaces ? "try friends or everyone" : "try another search")
            } else {
                ForEach(results.places) { visiblePlace in
                    DiscoverPlaceRow(visiblePlace: visiblePlace) {
                        auth.requireSignIn(for: .socialSave) {
                            Task {
                                let result = await store.saveVisiblePlace(visiblePlace, backend: backend)
                                savedMessage = result.syncState == .synced ? "Saved." : "Queued locally. We'll retry sync."
                            }
                        }
                    } openProfile: {
                        selectedProfile = SelectedProfile(id: visiblePlace.owner.id)
                    }
                }
            }
        }
    }

    private func refresh() async {
        results = await store.discover(query: query, scope: selectedScope, backend: backend)
    }
}

private struct SelectedProfile: Identifiable {
    let id: String
}

private struct SectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.system(size: 16, weight: .black))
    }
}

private struct EmptyPanel: View {
    let title: String
    let action: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: WanderTheme.spacing1) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                Text(action)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(WanderTheme.textMuted.color)
            }
            Spacer()
        }
        .padding(WanderTheme.spacing4)
        .background(WanderTheme.surfaceBone.color)
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusLarge))
    }
}

private struct AddPersonCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: WanderTheme.spacing2) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 17, weight: .bold))
                    .frame(width: 36, height: 36)
                    .background(WanderTheme.terracotta.color)
                    .foregroundStyle(WanderTheme.textOnAction.color)
                    .clipShape(Circle())

                Text("add")
                    .font(.system(size: 14, weight: .bold))
                Text("username")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WanderTheme.textMuted.color)
                    .lineLimit(1)

                Spacer()

                Text("find")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(WanderTheme.terracotta.color)
            }
            .frame(width: 82, height: 116, alignment: .leading)
            .padding(WanderTheme.spacing3)
            .background(WanderTheme.surfaceSand.color)
            .foregroundStyle(WanderTheme.textInk.color)
            .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusLarge))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add a person by username")
    }
}

private struct ContactCard: View {
    let contact: ContactMatch
    let open: () -> Void
    let follow: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing2) {
            WanderAvatar(initials: initials, size: 36, color: WanderTheme.avatarRyan.color)
            VStack(alignment: .leading, spacing: WanderTheme.spacing1) {
                Text(contact.displayName)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
                Text(contact.handle.map { "@\($0)" } ?? "on Wander")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WanderTheme.textMuted.color)
                    .lineLimit(1)
            }
            Spacer()
            Button(contact.isAlreadyFollowing ? "view" : "follow") {
                contact.isAlreadyFollowing ? open() : follow()
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(WanderTheme.terracotta.color)
        }
        .frame(width: 122, height: 116, alignment: .leading)
        .padding(WanderTheme.spacing3)
        .background(WanderTheme.surfaceBone.color)
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusLarge))
        .onTapGesture {
            open()
        }
    }

    private var initials: String {
        contact.displayName
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
    }
}

private struct ProfileMiniCard: View {
    let profile: ProfileShell
    let open: () -> Void
    let follow: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing2) {
            WanderAvatar(initials: String(profile.displayName.prefix(2)).uppercased(), size: 36, color: WanderTheme.pinSocial.color)
            Text(profile.displayName)
                .font(.system(size: 14, weight: .bold))
                .lineLimit(1)
            Text("@\(profile.handle) · \(profile.relationship.displayTitle)")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(WanderTheme.textMuted.color)
                .lineLimit(1)
            Spacer()
            Button(profile.relationship == .nonFollower ? "follow" : "view") {
                profile.relationship == .nonFollower ? follow() : open()
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(WanderTheme.terracotta.color)
        }
        .frame(width: 122, height: 116, alignment: .leading)
        .padding(WanderTheme.spacing3)
        .background(WanderTheme.surfaceBone.color)
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusLarge))
        .onTapGesture(perform: open)
    }
}

private struct DiscoverPlaceRow: View {
    let visiblePlace: VisiblePlace
    let save: () -> Void
    let openProfile: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: WanderTheme.spacing3) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(WanderTheme.terracotta.color)
                .frame(width: 42, height: 42)
                .background(WanderTheme.terracottaTint.color)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: WanderTheme.spacing1) {
                Text(visiblePlace.place.canonicalName)
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(1)
                Button(action: openProfile) {
                    Text("\(visiblePlace.owner.displayName) saved it · \(visiblePlace.userPlace.status.displayTitle)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(WanderTheme.textMuted.color)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
                if let note = visiblePlace.userPlace.note {
                    Text(note)
                        .font(.system(size: 12))
                        .foregroundStyle(WanderTheme.textMuted.color)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button(action: save) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .black))
                    .frame(width: 38, height: 38)
                    .background(WanderTheme.terracotta.color)
                    .foregroundStyle(WanderTheme.textOnAction.color)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Save \(visiblePlace.place.canonicalName) to my map")
        }
        .padding(WanderTheme.spacing3)
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
