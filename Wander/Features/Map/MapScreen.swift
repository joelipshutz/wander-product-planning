import MapKit
import SwiftUI

struct MapScreen: View {
    @EnvironmentObject private var store: WanderStore
    @State private var selectedPlaceID: String?
    @State private var isPlaceSheetExpanded: Bool
    @State private var selectedFilters: Set<MapFilter> = [.you, .social, .been, .wanna]
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 34.075, longitude: -118.285),
            span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.14)
        )
    )

    private let initialPlaceQuery: String?

    init(
        initialPlaceQuery: String? = Self.resolvedInitialMapPlaceQuery(),
        startsExpanded: Bool = ProcessInfo.processInfo.arguments.contains("-WanderMapSheetExpanded")
    ) {
        self.initialPlaceQuery = initialPlaceQuery
        _isPlaceSheetExpanded = State(initialValue: startsExpanded)
    }

    private var visiblePlaces: [VisiblePlace] {
        store.visiblePlaces(filters: filters)
    }

    private var visiblePlaceIDs: [String] {
        visiblePlaces.map(\.id)
    }

    private var filters: PlaceFilters {
        var filters = PlaceFilters()

        if selectedFilters.contains(.been) && !selectedFilters.contains(.wanna) {
            filters.statuses = [.been]
        } else if selectedFilters.contains(.wanna) && !selectedFilters.contains(.been) {
            filters.statuses = [.wannaGo]
        }

        var scopes: Set<String> = []
        if selectedFilters.contains(.you) { scopes.insert("you") }
        if selectedFilters.contains(.social) { scopes.insert("social") }
        filters.ownerScopes = scopes

        return filters
    }

    private var selectedPlace: VisiblePlace? {
        visiblePlaces.first { $0.id == selectedPlaceID } ?? visiblePlaces.first
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $position) {
                ForEach(visiblePlaces) { visiblePlace in
                    Annotation(
                        visiblePlace.place.canonicalName,
                        coordinate: CLLocationCoordinate2D(latitude: visiblePlace.place.latitude, longitude: visiblePlace.place.longitude)
                    ) {
                        Button {
                            selectedPlaceID = visiblePlace.id
                            isPlaceSheetExpanded = false
                        } label: {
                            MapPlaceMarker(
                                visiblePlace: visiblePlace,
                                isCurrentUser: visiblePlace.owner.id == store.currentUser.id,
                                isSelected: selectedPlaceID == visiblePlace.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat, emphasis: .muted))
            .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: WanderTheme.spacing2) {
                    SearchBar(title: "search a place, vibe, or username...")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: WanderTheme.spacing1) {
                            ForEach(MapFilter.allCases) { filter in
                                Button {
                                    toggle(filter)
                                } label: {
                                    MapFilterChip(title: filter.title, systemImage: filter.systemImage, isSelected: selectedFilters.contains(filter))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, WanderTheme.spacing3)
                        .padding(.vertical, WanderTheme.spacing1)
                    }
                    .frame(height: 48)
                }
                .padding(.top, WanderTheme.spacing2)

                Spacer()

                if let selectedPlace {
                    PlaceSheet(
                        visiblePlace: selectedPlace,
                        savers: savers(for: selectedPlace),
                        currentUserID: store.currentUser.id,
                        isExpanded: $isPlaceSheetExpanded
                    ) {
                        _ = store.saveVisiblePlace(selectedPlace)
                    }
                    .padding(.horizontal, WanderTheme.spacing3)
                    .padding(.bottom, WanderTheme.spacing2)
                }
            }
        }
        .background(WanderTheme.canvasWarm.color)
        .onAppear {
            resolveInitialSelection()
        }
        .onChange(of: visiblePlaceIDs) { _, ids in
            if let current = selectedPlaceID, !ids.contains(current) {
                selectedPlaceID = ids.first
                isPlaceSheetExpanded = false
            }
        }
    }

    private func toggle(_ filter: MapFilter) {
        if selectedFilters.contains(filter) {
            selectedFilters.remove(filter)
        } else {
            selectedFilters.insert(filter)
        }
    }

    private func resolveInitialSelection() {
        guard selectedPlaceID == nil else { return }

        if let initialPlaceQuery {
            let normalized = initialPlaceQuery.lowercased()
            selectedPlaceID = visiblePlaces.first { visiblePlace in
                visiblePlace.id.lowercased().contains(normalized)
                    || visiblePlace.place.id.lowercased().contains(normalized)
                    || visiblePlace.place.canonicalName.lowercased().contains(normalized)
            }?.id
        }

        if selectedPlaceID == nil {
            selectedPlaceID = visiblePlaces.first?.id
        }
    }

    private func savers(for selectedPlace: VisiblePlace) -> [LocalProfile] {
        var seen = Set<String>()
        return visiblePlaces
            .filter { $0.place.id == selectedPlace.place.id }
            .map(\.owner)
            .filter { profile in
                guard !seen.contains(profile.id) else { return false }
                seen.insert(profile.id)
                return true
            }
    }

    private static func resolvedInitialMapPlaceQuery(from arguments: [String] = ProcessInfo.processInfo.arguments) -> String? {
        guard let flagIndex = arguments.firstIndex(of: "-WanderMapPlace") else {
            return nil
        }

        let valueIndex = arguments.index(after: flagIndex)
        guard arguments.indices.contains(valueIndex) else {
            return nil
        }

        return arguments[valueIndex]
    }
}

private enum MapFilter: String, CaseIterable, Identifiable {
    case you
    case social
    case been
    case wanna

    var id: String { rawValue }

    var title: String {
        switch self {
        case .you: "you"
        case .social: "social"
        case .been: "been"
        case .wanna: "wanna"
        }
    }

    var systemImage: String {
        switch self {
        case .you: "location.circle.fill"
        case .social: "person.2.fill"
        case .been: "checkmark.circle.fill"
        case .wanna: "circle.dashed"
        }
    }
}

private struct SearchBar: View {
    let title: String

    var body: some View {
        HStack(spacing: WanderTheme.spacing2) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(WanderTheme.textMuted.color)
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(WanderTheme.textFaint.color)
                .lineLimit(1)
            Spacer()
            WanderAvatar(initials: "JL", size: 28, color: WanderTheme.avatarSofia.color)
        }
        .padding(.horizontal, WanderTheme.spacing3)
        .frame(height: 46)
        .background(WanderTheme.surfaceRaised.color)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(WanderTheme.borderHairline.color))
        .shadow(color: WanderTheme.textInk.color.opacity(0.08), radius: 10, x: 0, y: 5)
        .padding(.horizontal, WanderTheme.spacing3)
    }
}

private struct MapFilterChip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: WanderTheme.spacing1) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(isSelected ? WanderTheme.terracotta.color : WanderTheme.textInk.color)
            Text(title)
                .lineLimit(1)
        }
        .font(.system(size: 12, weight: .bold))
        .padding(.horizontal, WanderTheme.spacing3)
        .frame(height: 38)
        .background(WanderTheme.surfaceSand.color)
        .foregroundStyle(WanderTheme.textInk.color)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    isSelected ? WanderTheme.terracotta.color : WanderTheme.surfaceRaised.color.opacity(0.55),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .shadow(color: WanderTheme.textInk.color.opacity(isSelected ? 0.12 : 0), radius: 8, x: 0, y: 3)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct MapPlaceMarker: View {
    let visiblePlace: VisiblePlace
    let isCurrentUser: Bool
    let isSelected: Bool

    var body: some View {
        VStack(spacing: WanderTheme.spacing1) {
            WanderMapPin(visiblePlace: visiblePlace, isCurrentUser: isCurrentUser, isSelected: isSelected)
            MapPlaceLabel(title: visiblePlace.place.canonicalName, isSelected: isSelected)
        }
        .scaleEffect(isSelected ? 1.08 : 1)
        .animation(.spring(response: 0.24, dampingFraction: 0.78), value: isSelected)
    }
}

private struct MapPlaceLabel: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.system(size: isSelected ? 12 : 11, weight: .black))
            .lineLimit(1)
            .padding(.horizontal, WanderTheme.spacing2)
            .frame(maxWidth: isSelected ? 150 : 118)
            .frame(height: isSelected ? 24 : 22)
            .background((isSelected ? WanderTheme.surfaceRaised : WanderTheme.surfaceBone).color.opacity(isSelected ? 0.96 : 0.88))
            .foregroundStyle(isSelected ? WanderTheme.textInk.color : WanderTheme.textMuted.color)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isSelected ? WanderTheme.terracotta.color : WanderTheme.borderHairline.color.opacity(0.75), lineWidth: isSelected ? 1.5 : 1))
            .shadow(color: WanderTheme.textInk.color.opacity(isSelected ? 0.16 : 0.08), radius: isSelected ? 8 : 4, x: 0, y: 2)
    }
}

private struct WanderMapPin: View {
    let visiblePlace: VisiblePlace
    let isCurrentUser: Bool
    let isSelected: Bool

    private var pinColor: Color {
        isCurrentUser ? WanderTheme.pinYou.color : WanderTheme.pinSocial.color
    }

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: isSelected ? 17 : 16, weight: .bold))
            .frame(width: isSelected ? 42 : 38, height: isSelected ? 42 : 38)
            .background(WanderTheme.surfaceRaised.color)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        pinColor,
                        style: StrokeStyle(
                            lineWidth: isSelected ? 4 : 3,
                            lineCap: .round,
                            dash: visiblePlace.userPlace.status == .wannaGo ? [5, 4] : []
                        )
                    )
            )
            .overlay(
                Circle()
                    .stroke(WanderTheme.textInk.color.opacity(isSelected ? 0.2 : 0), lineWidth: 1)
                    .padding(-4)
            )
            .shadow(color: WanderTheme.textInk.color.opacity(0.22), radius: isSelected ? 9 : 6, x: 0, y: 2)
            .accessibilityLabel("\(isCurrentUser ? "Your" : "Social") \(visiblePlace.userPlace.status.displayTitle) \(visiblePlace.place.category), \(visiblePlace.place.canonicalName)")
    }

    private var symbol: String {
        switch visiblePlace.place.category {
        case "coffee": "cup.and.saucer.fill"
        case "hike": "figure.hiking"
        case "restaurant": "fork.knife"
        case "bar": "wineglass.fill"
        default: "mappin"
        }
    }
}

private struct PlaceSheet: View {
    let visiblePlace: VisiblePlace
    let savers: [LocalProfile]
    let currentUserID: String
    @Binding var isExpanded: Bool
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing3) {
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                    isExpanded.toggle()
                }
            } label: {
                Capsule()
                    .fill(WanderTheme.borderStrong.color)
                    .frame(width: 42, height: 5)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, WanderTheme.spacing1)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isExpanded ? "Collapse place details" : "Expand place details")

            if isExpanded {
                expandedContent
            } else {
                compactContent
            }
        }
        .padding(WanderTheme.spacing3)
        .background(WanderTheme.surfaceBone.color)
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusSheet))
        .shadow(color: WanderTheme.textInk.color.opacity(0.14), radius: 20, x: 0, y: 10)
    }

    private var compactContent: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing3) {
            HStack(alignment: .center, spacing: WanderTheme.spacing3) {
                CategoryThumb(category: visiblePlace.place.category)

                VStack(alignment: .leading, spacing: WanderTheme.spacing1) {
                    HStack {
                        Text(visiblePlace.place.canonicalName)
                            .font(.system(size: 20, weight: .bold))
                            .lineLimit(1)
                        StatusBadge(status: visiblePlace.userPlace.status)
                    }
                    Text("\(visiblePlace.place.locality ?? "Los Angeles") · \(visiblePlace.place.category)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(WanderTheme.textMuted.color)
                        .lineLimit(1)
                    if let note = visiblePlace.userPlace.note {
                        Text("\"\(note)\"")
                            .font(.system(size: 13))
                            .italic()
                            .foregroundStyle(WanderTheme.textMuted.color)
                            .lineLimit(2)
                    }
                }

                Spacer()

                saveButton(size: 46, iconSize: 21)
            }

            SocialProofRow(savers: savers, currentUserID: currentUserID, visibility: visiblePlace.userPlace.visibility)
        }
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing4) {
            HStack(alignment: .top, spacing: WanderTheme.spacing3) {
                CategoryThumb(category: visiblePlace.place.category)
                VStack(alignment: .leading, spacing: WanderTheme.spacing1) {
                    Text(visiblePlace.place.canonicalName)
                        .font(.system(size: 24, weight: .black))
                        .lineLimit(2)
                    Text("\(visiblePlace.place.locality ?? "Los Angeles") · \(visiblePlace.place.category)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(WanderTheme.textMuted.color)
                    StatusBadge(status: visiblePlace.userPlace.status)
                }
                Spacer()
                saveButton(size: 48, iconSize: 22)
            }

            SocialProofRow(savers: savers, currentUserID: currentUserID, visibility: visiblePlace.userPlace.visibility)

            if let note = visiblePlace.userPlace.note {
                VStack(alignment: .leading, spacing: WanderTheme.spacing1) {
                    Text("note")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(WanderTheme.textMuted.color)
                    Text(note)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(WanderTheme.textInk.color)
                }
                .padding(WanderTheme.spacing3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(WanderTheme.surfaceSand.color)
                .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusLarge))
            }

            HStack(spacing: WanderTheme.spacing2) {
                PlaceFactPill(title: visiblePlace.userPlace.status.displayTitle, systemImage: visiblePlace.userPlace.status == .been ? "checkmark.circle.fill" : "circle.dashed")
                PlaceFactPill(title: visiblePlace.userPlace.visibility.displayTitle, systemImage: "eye.fill")
                PlaceFactPill(title: visiblePlace.userPlace.sourceType.replacingOccurrences(of: "_", with: " "), systemImage: "tray.full.fill")
            }
        }
    }

    private func saveButton(size: CGFloat, iconSize: CGFloat) -> some View {
        Button(action: onSave) {
            Image(systemName: "plus")
                .font(.system(size: iconSize, weight: .black))
                .frame(width: size, height: size)
                .background(WanderTheme.terracotta.color)
                .foregroundStyle(WanderTheme.textOnAction.color)
                .clipShape(Circle())
        }
        .accessibilityLabel("Save to my map")
    }
}

private struct SocialProofRow: View {
    let savers: [LocalProfile]
    let currentUserID: String
    let visibility: PlaceVisibility

    var body: some View {
        HStack(spacing: WanderTheme.spacing2) {
            Facepile(profiles: savers, currentUserID: currentUserID)
            Text(proofText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(WanderTheme.textMuted.color)
                .lineLimit(1)
            Spacer()
            Text(visibility.displayTitle)
                .font(.system(size: 13, weight: .bold))
                .padding(.horizontal, WanderTheme.spacing3)
                .padding(.vertical, WanderTheme.spacing1)
                .background(WanderTheme.surfaceSand.color)
                .clipShape(Capsule())
        }
    }

    private var proofText: String {
        guard let first = savers.first else { return "saved on Wander" }
        let name = first.id == currentUserID ? "you" : first.displayName
        guard savers.count > 1 else { return "\(name) saved it" }
        return "\(name) +\(savers.count - 1) others saved it"
    }
}

private struct Facepile: View {
    let profiles: [LocalProfile]
    let currentUserID: String

    var body: some View {
        HStack(spacing: -8) {
            ForEach(Array(profiles.prefix(3).enumerated()), id: \.element.id) { index, profile in
                WanderAvatar(initials: profile.initials, size: 26, color: color(for: profile))
                    .zIndex(Double(3 - index))
            }
        }
        .frame(minWidth: profiles.isEmpty ? 0 : 26 + CGFloat(max(0, min(profiles.count, 3) - 1)) * 18, alignment: .leading)
    }

    private func color(for profile: LocalProfile) -> Color {
        if profile.id == currentUserID { return WanderTheme.terracotta.color }
        return profile.handle == "ryan" ? WanderTheme.avatarRyan.color : WanderTheme.pinSocial.color
    }
}

private struct PlaceFactPill: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: WanderTheme.spacing1) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .bold))
            Text(title)
                .lineLimit(1)
        }
        .font(.system(size: 12, weight: .bold))
        .padding(.horizontal, WanderTheme.spacing3)
        .frame(height: 34)
        .background(WanderTheme.surfaceSand.color)
        .clipShape(Capsule())
    }
}

private struct CategoryThumb: View {
    let category: String

    var body: some View {
        Image(systemName: imageName)
            .font(.system(size: 19, weight: .bold))
            .foregroundStyle(WanderTheme.terracotta.color)
            .frame(width: 46, height: 46)
            .background(WanderTheme.terracottaTint.color)
            .clipShape(Circle())
    }

    private var imageName: String {
        switch category {
        case "coffee": "cup.and.saucer.fill"
        case "hike": "figure.hiking"
        case "restaurant": "fork.knife"
        case "bar": "wineglass.fill"
        default: "mappin"
        }
    }
}

private struct StatusBadge: View {
    let status: PlaceStatus

    var body: some View {
        Text(status == .been ? "been" : "wanna")
            .font(.system(size: 12, weight: .bold))
            .padding(.horizontal, WanderTheme.spacing2)
            .padding(.vertical, WanderTheme.spacing1)
            .background(status == .been ? WanderTheme.stateSuccess.color.opacity(0.16) : WanderTheme.sunTint.color)
            .foregroundStyle(status == .been ? WanderTheme.stateSuccess.color : WanderTheme.textInk.color)
            .clipShape(Capsule())
    }
}
