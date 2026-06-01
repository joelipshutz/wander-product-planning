import MapKit
import SwiftUI

struct MapScreen: View {
    @EnvironmentObject private var store: WanderStore
    @State private var selectedPlaceID: String?
    @State private var selectedFilters: Set<MapFilter> = [.you, .social, .friends, .been, .wanna]
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 34.075, longitude: -118.285),
            span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.14)
        )
    )

    private var visiblePlaces: [VisiblePlace] {
        store.visiblePlaces(filters: filters)
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
        if selectedFilters.contains(.friends) { scopes.insert("friends") }
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
                        } label: {
                            WanderMapPin(visiblePlace: visiblePlace, isCurrentUser: visiblePlace.owner.id == store.currentUser.id)
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
                    }
                }
                .padding(.top, WanderTheme.spacing2)

                Spacer()

                if let selectedPlace {
                    PlaceSheet(visiblePlace: selectedPlace) {
                        _ = store.saveVisiblePlace(selectedPlace)
                    }
                    .padding(.horizontal, WanderTheme.spacing3)
                    .padding(.bottom, WanderTheme.spacing2)
                }
            }
        }
        .background(WanderTheme.canvasWarm.color)
        .onAppear {
            if selectedPlaceID == nil {
                selectedPlaceID = visiblePlaces.first?.id
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
}

private enum MapFilter: String, CaseIterable, Identifiable {
    case you
    case social
    case friends
    case been
    case wanna

    var id: String { rawValue }

    var title: String {
        switch self {
        case .you: "you"
        case .social: "social"
        case .friends: "friends"
        case .been: "been"
        case .wanna: "wanna"
        }
    }

    var systemImage: String {
        switch self {
        case .you: "location.circle.fill"
        case .social: "person.2.fill"
        case .friends: "person.2.badge.gearshape.fill"
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
            Text(title)
                .lineLimit(1)
        }
        .font(.system(size: 12, weight: .bold))
        .padding(.horizontal, WanderTheme.spacing3)
        .frame(height: 38)
        .background(isSelected ? WanderTheme.textInk.color : WanderTheme.surfaceSand.color)
        .foregroundStyle(isSelected ? WanderTheme.textOnAction.color : WanderTheme.textInk.color)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(WanderTheme.surfaceRaised.color.opacity(isSelected ? 0 : 0.55), lineWidth: 1))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct WanderMapPin: View {
    let visiblePlace: VisiblePlace
    let isCurrentUser: Bool

    private var pinColor: Color {
        isCurrentUser ? WanderTheme.pinYou.color : WanderTheme.pinSocial.color
    }

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 16, weight: .bold))
            .frame(width: 38, height: 38)
            .background(WanderTheme.surfaceRaised.color)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        pinColor,
                        style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round,
                            dash: visiblePlace.userPlace.status == .wannaGo ? [5, 4] : []
                        )
                    )
            )
            .shadow(color: WanderTheme.textInk.color.opacity(0.22), radius: 6, x: 0, y: 2)
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
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing2) {
            Capsule()
                .fill(WanderTheme.borderStrong.color)
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity)

            HStack(alignment: .center, spacing: WanderTheme.spacing3) {
                CategoryThumb(category: visiblePlace.place.category)

                VStack(alignment: .leading, spacing: WanderTheme.spacing1) {
                    HStack {
                        Text(visiblePlace.place.canonicalName)
                            .font(.system(size: 20, weight: .bold))
                            .lineLimit(1)
                        StatusBadge(status: visiblePlace.userPlace.status)
                    }
                    Text("\(visiblePlace.place.locality ?? "Los Angeles") · \(visiblePlace.place.category) · saved by \(visiblePlace.owner.displayName)")
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

                Button(action: onSave) {
                    Image(systemName: "plus")
                        .font(.system(size: 21, weight: .black))
                        .frame(width: 46, height: 46)
                        .background(WanderTheme.terracotta.color)
                        .foregroundStyle(WanderTheme.textOnAction.color)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Save to my map")
            }

            HStack(spacing: WanderTheme.spacing2) {
                WanderAvatar(initials: visiblePlace.owner.initials, size: 26, color: visiblePlace.owner.id == visiblePlace.userPlace.userID ? WanderTheme.pinSocial.color : WanderTheme.terracotta.color)
                Text(visiblePlace.owner.id == visiblePlace.userPlace.userID ? "\(visiblePlace.owner.displayName)'s tip" : "on your map")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(WanderTheme.textMuted.color)
                Spacer()
                Text(visiblePlace.userPlace.visibility.displayTitle)
                    .font(.system(size: 13, weight: .bold))
                    .padding(.horizontal, WanderTheme.spacing3)
                    .padding(.vertical, WanderTheme.spacing1)
                    .background(WanderTheme.surfaceSand.color)
                    .clipShape(Capsule())
            }
        }
        .padding(WanderTheme.spacing3)
        .background(WanderTheme.surfaceBone.color)
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusLarge))
        .shadow(color: WanderTheme.textInk.color.opacity(0.14), radius: 20, x: 0, y: 10)
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
