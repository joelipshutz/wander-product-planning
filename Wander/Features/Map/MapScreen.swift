import MapKit
import SwiftUI
import UIKit

struct MapScreen: View {
    @EnvironmentObject private var store: WanderStore
    @EnvironmentObject private var auth: AuthSessionStore
    @EnvironmentObject private var backend: WanderBackend
    @State private var selectedPlaceID: String?
    @State private var selectedSearchCandidateID: String?
    @State private var isPlaceSheetExpanded: Bool
    @State private var mapQuery = ""
    @State private var mapSearchMessage: String?
    @State private var mapSearchCandidates: [PlaceCandidate] = []
    @State private var typeaheadSuggestions: [MapSearchSuggestion] = []
    @State private var isLoadingTypeahead = false
    @State private var typeaheadTask: Task<Void, Never>?
    @State private var suppressedTypeaheadQuery: String?
    @State private var isSearchingMapKit = false
    @State private var selectedFilters: Set<MapFilter> = [.you, .social, .been, .wanna]
    @State private var currentSearchRegion = Self.defaultRegion
    @State private var position: MapCameraPosition = .region(Self.defaultRegion)
    @State private var isRecenteringOnUser = false

    private static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.075, longitude: -118.285),
        span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.14)
    )
    private static let recenterCameraDistance: CLLocationDistance = 1_500

    private let initialPlaceQuery: String?

    private var baseVisiblePlaces: [VisiblePlace] {
        store.visiblePlaces(filters: filters)
    }

    init(
        initialPlaceQuery: String? = Self.resolvedInitialMapPlaceQuery(),
        startsExpanded: Bool = ProcessInfo.processInfo.arguments.contains("-WanderMapSheetExpanded")
    ) {
        self.initialPlaceQuery = initialPlaceQuery
        _isPlaceSheetExpanded = State(initialValue: startsExpanded)
    }

    private var visiblePlaces: [VisiblePlace] {
        let places = baseVisiblePlaces
        let normalizedQuery = mapQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedQuery.isEmpty else { return places }

        return places.filter { visiblePlace in
            visiblePlace.place.canonicalName.lowercased().contains(normalizedQuery)
                || visiblePlace.place.category.lowercased().contains(normalizedQuery)
                || (visiblePlace.place.locality?.lowercased().contains(normalizedQuery) ?? false)
                || visiblePlace.owner.displayName.lowercased().contains(normalizedQuery)
                || visiblePlace.owner.handle.lowercased().contains(normalizedQuery)
                || (visiblePlace.userPlace.note?.lowercased().contains(normalizedQuery) ?? false)
                || (visiblePlace.userPlace.ratingSignal?.lowercased().contains(normalizedQuery) ?? false)
        }
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

    private var selectedSearchCandidate: PlaceCandidate? {
        guard let selectedSearchCandidateID else { return nil }
        return mapSearchCandidates.first { $0.id == selectedSearchCandidateID }
    }

    private var mappableSearchCandidates: [PlaceCandidate] {
        mapSearchCandidates.filter { $0.latitude != nil && $0.longitude != nil }
    }

    private var currentViewport: MapViewport {
        MapViewport(minLatitude: 33.95, minLongitude: -118.45, maxLatitude: 34.2, maxLongitude: -118.12)
    }

    private var shouldShowTypeahead: Bool {
        let normalized = Self.normalized(mapQuery)
        return normalized.count >= 2
            && suppressedTypeaheadQuery != normalized
            && (isLoadingTypeahead || !typeaheadSuggestions.isEmpty)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $position) {
                UserAnnotation()

                ForEach(visiblePlaces) { visiblePlace in
                    Annotation(
                        visiblePlace.place.canonicalName,
                        coordinate: CLLocationCoordinate2D(latitude: visiblePlace.place.latitude, longitude: visiblePlace.place.longitude)
                    ) {
                        Button {
                            selectedPlaceID = visiblePlace.id
                            selectedSearchCandidateID = nil
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

                ForEach(mappableSearchCandidates) { candidate in
                    if let latitude = candidate.latitude,
                       let longitude = candidate.longitude {
                        Annotation(
                            candidate.name,
                            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        ) {
                            Button {
                                selectedSearchCandidateID = candidate.id
                                selectedPlaceID = nil
                                isPlaceSheetExpanded = false
                            } label: {
                                SearchResultMarker(candidate: candidate, isSelected: selectedSearchCandidateID == candidate.id)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat, emphasis: .muted))
            .ignoresSafeArea()
            .onMapCameraChange(frequency: .onEnd) { context in
                currentSearchRegion = context.region
            }

            VStack(spacing: 0) {
                VStack(spacing: WanderTheme.spacing2) {
                    SearchBar(
                        query: $mapQuery,
                        userInitials: store.currentUser.initials,
                        onSubmit: submitMapSearch
                    )
                    if shouldShowTypeahead {
                        MapTypeaheadList(
                            suggestions: typeaheadSuggestions,
                            isLoading: isLoadingTypeahead,
                            onSelect: selectTypeaheadSuggestion
                        )
                        .padding(.horizontal, WanderTheme.spacing3)
                    } else if let mapSearchMessage {
                        MapSearchMessage(text: mapSearchMessage)
                            .padding(.horizontal, WanderTheme.spacing3)
                    }
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

                HStack {
                    Spacer()
                    RecenterButton(isLoading: isRecenteringOnUser) {
                        recenterOnUser()
                    }
                    .padding(.trailing, WanderTheme.spacing3)
                    .padding(.bottom, WanderTheme.spacing2)
                }

                if let selectedSearchCandidate {
                    SearchCandidateSheet(candidate: selectedSearchCandidate) {
                        auth.requireSignIn(for: .syncPlace) {
                            Task {
                                let result = await store.saveCandidate(
                                    selectedSearchCandidate,
                                    status: .wannaGo,
                                    visibility: store.defaultVisibility,
                                    note: nil,
                                    sourceType: .manual,
                                    backend: backend
                                )
                                selectedSearchCandidateID = nil
                                selectedPlaceID = result.userPlaceID
                                mapSearchCandidates.removeAll { $0.id == selectedSearchCandidate.id }
                                mapSearchMessage = "Added to your map."
                            }
                        }
                    }
                    .padding(.horizontal, WanderTheme.spacing3)
                    .padding(.bottom, WanderTheme.spacing2)
                } else if let selectedPlace {
                    PlaceSheet(
                        visiblePlace: selectedPlace,
                        saves: saveSummaries(for: selectedPlace),
                        currentUserID: store.currentUser.id,
                        action: action(for: selectedPlace),
                        isExpanded: $isPlaceSheetExpanded
                    ) {
                        performAction(for: selectedPlace)
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
        .task {
            await store.refreshRemoteVisiblePlaces(in: currentViewport, backend: backend)
        }
        .onChange(of: auth.isSignedIn) { _, isSignedIn in
            guard isSignedIn else { return }
            Task {
                await store.refreshRemoteVisiblePlaces(in: currentViewport, backend: backend)
            }
        }
        .onChange(of: visiblePlaceIDs) { _, ids in
            if let current = selectedPlaceID, !ids.contains(current) {
                selectedPlaceID = ids.first
                isPlaceSheetExpanded = false
            }
        }
        .onChange(of: mapQuery) { _, _ in
            handleMapQueryChange()
            if let firstVisibleID = visiblePlaceIDs.first, !visiblePlaceIDs.contains(selectedPlaceID ?? "") {
                selectedPlaceID = firstVisibleID
                isPlaceSheetExpanded = false
            }
        }
        .onDisappear {
            typeaheadTask?.cancel()
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
        saveSummaries(for: selectedPlace).map(\.visiblePlace.owner)
    }

    private func saveSummaries(for selectedPlace: VisiblePlace) -> [PlaceSaveSummary] {
        var seen = Set<String>()
        let summaries = visiblePlaces
            .filter { $0.place.id == selectedPlace.place.id }
            .filter { visiblePlace in
                guard !seen.contains(visiblePlace.userPlace.id) else { return false }
                seen.insert(visiblePlace.userPlace.id)
                return true
            }
            .map { visiblePlace in
                PlaceSaveSummary(visiblePlace: visiblePlace, attributes: store.attributes(for: visiblePlace.userPlace.id))
            }

        return summaries.sorted { lhs, rhs in
            if lhs.visiblePlace.owner.id == store.currentUser.id { return true }
            if rhs.visiblePlace.owner.id == store.currentUser.id { return false }
            if lhs.visiblePlace.id == selectedPlace.id { return true }
            if rhs.visiblePlace.id == selectedPlace.id { return false }
            return lhs.visiblePlace.owner.displayName.localizedCaseInsensitiveCompare(rhs.visiblePlace.owner.displayName) == .orderedAscending
        }
    }

    private func submitMapSearch() {
        dismissKeyboard()
        suppressedTypeaheadQuery = Self.normalized(mapQuery)
        typeaheadTask?.cancel()
        typeaheadSuggestions = []
        isLoadingTypeahead = false
        Task {
            await runMapSearch()
        }
    }

    @MainActor
    private func runMapSearch() async {
        let query = mapQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            mapSearchMessage = nil
            mapSearchCandidates = []
            selectedSearchCandidateID = nil
            return
        }

        isSearchingMapKit = true
        defer { isSearchingMapKit = false }

        do {
            let candidates = try await mapKitCandidates(for: query)
            mapSearchCandidates = candidates.filter { !isAlreadyVisible(candidate: $0) }

            if let firstVisibleID = visiblePlaceIDs.first {
                selectedPlaceID = firstVisibleID
                selectedSearchCandidateID = nil
                mapSearchMessage = mapSearchCandidates.isEmpty ? nil : "Also showing unsaved map results."
            } else if let firstCandidate = mapSearchCandidates.first {
                selectedPlaceID = nil
                selectedSearchCandidateID = firstCandidate.id
                center(on: firstCandidate)
                mapSearchMessage = "Map result. Tap + to add it."
            } else {
                selectedPlaceID = nil
                selectedSearchCandidateID = nil
                mapSearchMessage = "No saved places or map results found."
            }
        } catch {
            mapSearchCandidates = []
            mapSearchMessage = visiblePlaces.isEmpty
                ? "No saved places match yet. Try a more specific search."
                : nil
        }
    }

    private func mapKitCandidates(for query: String, limit: Int = 8) async throws -> [PlaceCandidate] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = currentSearchRegion
        request.resultTypes = [.pointOfInterest, .address]

        let response = try await MKLocalSearch(request: request).start()
        var seen = Set<String>()
        return response.mapItems.compactMap { item in
            guard let name = item.name?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty,
                  CLLocationCoordinate2DIsValid(item.placemark.coordinate)
            else { return nil }

            let sourceID = mapKitSourceID(for: item, name: name)
            guard !seen.contains(sourceID) else { return nil }
            seen.insert(sourceID)

            return PlaceCandidate(
                id: sourceID,
                name: name,
                category: category(for: item),
                address: address(for: item.placemark),
                locality: item.placemark.locality,
                region: item.placemark.administrativeArea,
                country: item.placemark.country,
                latitude: item.placemark.coordinate.latitude,
                longitude: item.placemark.coordinate.longitude,
                sourceProvider: "mapkit",
                sourceProviderPlaceID: sourceID,
                confidence: item.pointOfInterestCategory == nil ? 0.72 : 0.86
            )
        }
        .prefix(limit)
        .map { $0 }
    }

    private func action(for visiblePlace: VisiblePlace) -> PlaceSheetAction {
        if visiblePlace.owner.id == store.currentUser.id {
            return .edit
        }

        return isSavedByCurrentUser(visiblePlace) ? .none : .add
    }

    private func performAction(for visiblePlace: VisiblePlace) {
        switch action(for: visiblePlace) {
        case .add:
            auth.requireSignIn(for: .socialSave) {
                Task {
                    _ = await store.saveVisiblePlace(visiblePlace, backend: backend)
                    mapSearchMessage = "Added to your map."
                }
            }
        case .edit:
            if visiblePlace.userPlace.status == .wannaGo {
                Task {
                    _ = await store.saveCandidate(
                        PlaceCandidate(
                            id: visiblePlace.place.id,
                            name: visiblePlace.place.canonicalName,
                            category: visiblePlace.place.category,
                            address: visiblePlace.place.address,
                            locality: visiblePlace.place.locality,
                            region: visiblePlace.place.region,
                            country: visiblePlace.place.country,
                            latitude: visiblePlace.place.latitude,
                            longitude: visiblePlace.place.longitude,
                            sourceProvider: visiblePlace.place.sourceProvider,
                            sourceProviderPlaceID: visiblePlace.place.sourceProviderPlaceID,
                            confidence: visiblePlace.place.confidence ?? 1
                        ),
                        status: .been,
                        visibility: visiblePlace.userPlace.visibility,
                        note: visiblePlace.userPlace.note,
                        sourceType: .manual,
                        backend: auth.isSignedIn ? backend : nil
                    )
                    mapSearchMessage = "Marked as been."
                }
            } else {
                mapSearchMessage = "Editing saved places is coming next."
            }
        case .none:
            break
        }
    }

    private func isSavedByCurrentUser(_ visiblePlace: VisiblePlace) -> Bool {
        store.currentUserVisiblePlaces.contains { mine in
            mine.place.id == visiblePlace.place.id
                || mine.place.canonicalName.caseInsensitiveCompare(visiblePlace.place.canonicalName) == .orderedSame
        }
    }

    private func isAlreadyVisible(candidate: PlaceCandidate) -> Bool {
        baseVisiblePlaces.contains { visiblePlace in
            visiblePlace.place.sourceProviderPlaceID == candidate.sourceProviderPlaceID
                || visiblePlace.place.canonicalName.caseInsensitiveCompare(candidate.name) == .orderedSame
        }
    }

    private func handleMapQueryChange() {
        let normalized = Self.normalized(mapQuery)
        mapSearchMessage = nil

        if normalized == suppressedTypeaheadQuery {
            typeaheadTask?.cancel()
            typeaheadSuggestions = []
            isLoadingTypeahead = false
            return
        }

        suppressedTypeaheadQuery = nil
        mapSearchCandidates = []
        selectedSearchCandidateID = nil
        scheduleTypeahead(for: mapQuery)
    }

    private func scheduleTypeahead(for query: String) {
        typeaheadTask?.cancel()
        let normalized = Self.normalized(query)

        guard normalized.count >= 2 else {
            typeaheadSuggestions = []
            isLoadingTypeahead = false
            return
        }

        typeaheadSuggestions = savedTypeaheadSuggestions(for: query)
        isLoadingTypeahead = true

        typeaheadTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 280_000_000)
            guard !Task.isCancelled else { return }

            let candidates = (try? await mapKitCandidates(for: query, limit: 6)) ?? []
            guard !Task.isCancelled, Self.normalized(mapQuery) == normalized else { return }

            let savedSuggestions = savedTypeaheadSuggestions(for: query)
            let seenTitles = Set(savedSuggestions.map { Self.normalized($0.title) })
            let mapSuggestions = candidates
                .filter { !isAlreadyVisible(candidate: $0) }
                .filter { !seenTitles.contains(Self.normalized($0.name)) }
                .prefix(max(0, 6 - savedSuggestions.count))
                .map(MapSearchSuggestion.mapKit)

            typeaheadSuggestions = Array((savedSuggestions + mapSuggestions).prefix(6))
            isLoadingTypeahead = false
        }
    }

    private func savedTypeaheadSuggestions(for query: String) -> [MapSearchSuggestion] {
        let normalized = Self.normalized(query)
        guard !normalized.isEmpty else { return [] }

        var seenPlaceIDs = Set<String>()
        return baseVisiblePlaces
            .filter { visiblePlace in
                matchesTypeahead(visiblePlace, normalizedQuery: normalized)
            }
            .sorted { lhs, rhs in
                let lhsIsMine = lhs.owner.id == store.currentUser.id
                let rhsIsMine = rhs.owner.id == store.currentUser.id
                if lhsIsMine != rhsIsMine { return lhsIsMine }
                return lhs.place.canonicalName.localizedCaseInsensitiveCompare(rhs.place.canonicalName) == .orderedAscending
            }
            .compactMap { visiblePlace in
                let placeID = visiblePlace.place.id
                guard !seenPlaceIDs.contains(placeID) else { return nil }
                seenPlaceIDs.insert(placeID)
                return MapSearchSuggestion.saved(visiblePlace)
            }
            .prefix(3)
            .map { $0 }
    }

    private func matchesTypeahead(_ visiblePlace: VisiblePlace, normalizedQuery: String) -> Bool {
        [
            visiblePlace.place.canonicalName,
            visiblePlace.place.category,
            visiblePlace.place.locality,
            visiblePlace.owner.displayName,
            "@\(visiblePlace.owner.handle)",
            visiblePlace.userPlace.note,
            visiblePlace.userPlace.ratingSignal
        ]
        .compactMap { $0 }
        .contains { Self.normalized($0).contains(normalizedQuery) }
    }

    private func selectTypeaheadSuggestion(_ suggestion: MapSearchSuggestion) {
        dismissKeyboard()
        typeaheadTask?.cancel()
        isLoadingTypeahead = false
        typeaheadSuggestions = []
        suppressedTypeaheadQuery = Self.normalized(suggestion.title)
        mapQuery = suggestion.title
        mapSearchMessage = nil

        switch suggestion.source {
        case .saved(let visiblePlace):
            selectedPlaceID = visiblePlace.id
            selectedSearchCandidateID = nil
            mapSearchCandidates = []
            center(on: visiblePlace)
        case .mapKit(let candidate):
            selectedPlaceID = nil
            selectedSearchCandidateID = candidate.id
            mapSearchCandidates = isAlreadyVisible(candidate: candidate) ? [] : [candidate]
            center(on: candidate)
            mapSearchMessage = "Map result. Tap + to add it."
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func center(on candidate: PlaceCandidate) {
        guard let latitude = candidate.latitude,
              let longitude = candidate.longitude
        else { return }

        position = .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.035, longitudeDelta: 0.04)
            )
        )
    }

    private func center(on visiblePlace: VisiblePlace) {
        position = .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: visiblePlace.place.latitude, longitude: visiblePlace.place.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.035, longitudeDelta: 0.04)
            )
        )
    }

    private func recenterOnUser() {
        guard !isRecenteringOnUser else { return }

        isRecenteringOnUser = true
        Task {
            let coordinate = await currentUserCoordinate()
            await MainActor.run {
                isRecenteringOnUser = false
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    if let coordinate {
                        let center = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
                        position = .camera(
                            MapCamera(
                                centerCoordinate: center,
                                distance: Self.recenterCameraDistance,
                                heading: 0,
                                pitch: 0
                            )
                        )
                        currentSearchRegion = MKCoordinateRegion(
                            center: center,
                            latitudinalMeters: Self.recenterCameraDistance * 2,
                            longitudinalMeters: Self.recenterCameraDistance * 2
                        )
                    } else {
                        position = .region(
                            MKCoordinateRegion(
                                center: Self.defaultRegion.center,
                                latitudinalMeters: Self.recenterCameraDistance * 2,
                                longitudinalMeters: Self.recenterCameraDistance * 2
                            )
                        )
                    }
                }
            }
        }
    }

    private func currentUserCoordinate() async -> (latitude: Double, longitude: Double)? {
        do {
            let location = try await CoreLocationProvider().currentLocation()
            return (location.coordinate.latitude, location.coordinate.longitude)
        } catch {
            return nil
        }
    }

    private func mapKitSourceID(for item: MKMapItem, name: String) -> String {
        let latitude = Int((item.placemark.coordinate.latitude * 100_000).rounded())
        let longitude = Int((item.placemark.coordinate.longitude * 100_000).rounded())
        let slug = name
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        return "mapkit_\(slug)_\(latitude)_\(longitude)"
    }

    private func category(for item: MKMapItem) -> String {
        WanderPlaceCategory.primary(for: item.pointOfInterestCategory) ?? "place"
    }

    private func address(for placemark: MKPlacemark) -> String? {
        let parts = [
            placemark.subThoroughfare,
            placemark.thoroughfare,
            placemark.locality
        ].compactMap { value -> String? in
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed?.isEmpty == false ? trimmed : nil
        }

        return parts.isEmpty ? nil : parts.joined(separator: " ")
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

    private static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
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

private struct MapSearchSuggestion: Identifiable {
    enum Source {
        case saved(VisiblePlace)
        case mapKit(PlaceCandidate)
    }

    let id: String
    let title: String
    let subtitle: String
    let category: String
    let source: Source

    static func saved(_ visiblePlace: VisiblePlace) -> MapSearchSuggestion {
        let subtitle = [
            visiblePlace.owner.displayName,
            visiblePlace.place.locality,
            visiblePlace.place.category
        ]
        .compactMap { value -> String? in
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed?.isEmpty == false ? trimmed : nil
        }
        .joined(separator: " · ")

        return MapSearchSuggestion(
            id: "saved_\(visiblePlace.id)",
            title: visiblePlace.place.canonicalName,
            subtitle: subtitle.isEmpty ? "saved on Wander" : subtitle,
            category: visiblePlace.place.category,
            source: .saved(visiblePlace)
        )
    }

    static func mapKit(_ candidate: PlaceCandidate) -> MapSearchSuggestion {
        let subtitle = [
            candidate.locality,
            candidate.category == "place" ? nil : candidate.category,
            "not saved"
        ]
        .compactMap { value -> String? in
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed?.isEmpty == false ? trimmed : nil
        }
        .joined(separator: " · ")

        return MapSearchSuggestion(
            id: "mapkit_\(candidate.id)",
            title: candidate.name,
            subtitle: subtitle,
            category: candidate.category,
            source: .mapKit(candidate)
        )
    }
}

private struct SearchBar: View {
    @Binding var query: String
    let userInitials: String
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: WanderTheme.spacing2) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(WanderTheme.textMuted.color)
            TextField("search your map or people...", text: $query)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(WanderTheme.textInk.color)
                .tint(WanderTheme.terracotta.color)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit(onSubmit)
            Spacer()
            if query.isEmpty {
                WanderAvatar(initials: userInitials, size: 28, color: WanderTheme.terracotta.color)
            } else {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(WanderTheme.textFaint.color)
                }
                .accessibilityLabel("Clear map search")
            }
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

private struct MapTypeaheadList: View {
    let suggestions: [MapSearchSuggestion]
    let isLoading: Bool
    let onSelect: (MapSearchSuggestion) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(suggestions) { suggestion in
                Button {
                    onSelect(suggestion)
                } label: {
                    MapTypeaheadRow(suggestion: suggestion)
                }
                .buttonStyle(.plain)

                if suggestion.id != suggestions.last?.id {
                    Divider()
                        .overlay(WanderTheme.borderHairline.color)
                        .padding(.leading, 52)
                }
            }

            if isLoading {
                HStack(spacing: WanderTheme.spacing2) {
                    ProgressView()
                        .controlSize(.small)
                        .tint(WanderTheme.terracotta.color)
                    Text(suggestions.isEmpty ? "looking nearby..." : "checking nearby...")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(WanderTheme.textMuted.color)
                    Spacer()
                }
                .padding(.horizontal, WanderTheme.spacing3)
                .padding(.vertical, WanderTheme.spacing2)
                .accessibilityLabel("Looking for nearby places")
            }
        }
        .background(WanderTheme.surfaceRaised.color)
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: WanderTheme.radiusLarge)
                .stroke(WanderTheme.borderHairline.color, lineWidth: 1)
        )
        .shadow(color: WanderTheme.textInk.color.opacity(0.1), radius: 12, x: 0, y: 6)
    }
}

private struct MapTypeaheadRow: View {
    let suggestion: MapSearchSuggestion

    var body: some View {
        HStack(spacing: WanderTheme.spacing2) {
            Image(systemName: WanderPlaceCategory.symbolName(for: suggestion.category))
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(iconColor)
                .frame(width: 34, height: 34)
                .background(iconBackground)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(WanderTheme.textInk.color)
                    .lineLimit(1)
                Text(suggestion.subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WanderTheme.textMuted.color)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: isSavedSuggestion ? "checkmark.circle.fill" : "plus.circle.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isSavedSuggestion ? WanderTheme.stateSuccess.color : WanderTheme.pinSocial.color)
        }
        .padding(.horizontal, WanderTheme.spacing3)
        .padding(.vertical, WanderTheme.spacing2)
        .contentShape(Rectangle())
        .accessibilityLabel("\(suggestion.title), \(suggestion.subtitle)")
    }

    private var isSavedSuggestion: Bool {
        if case .saved = suggestion.source { return true }
        return false
    }

    private var iconColor: Color {
        isSavedSuggestion ? WanderTheme.terracotta.color : WanderTheme.pinSocial.color
    }

    private var iconBackground: Color {
        isSavedSuggestion ? WanderTheme.terracottaTint.color : WanderTheme.skyTint.color
    }
}

private struct MapSearchMessage: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(WanderTheme.textInk.color)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, WanderTheme.spacing3)
            .padding(.vertical, WanderTheme.spacing2)
            .background(WanderTheme.surfaceBone.color)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(WanderTheme.borderHairline.color, lineWidth: 1))
    }
}

private struct RecenterButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isLoading ? "location.circle.fill" : "location.fill")
                .font(.system(size: 16, weight: .black))
                .frame(width: 44, height: 44)
                .background(WanderTheme.skyTint.color)
                .foregroundStyle(WanderTheme.pinSocial.color)
                .clipShape(Circle())
                .overlay(Circle().stroke(WanderTheme.pinSocial.color, lineWidth: 2))
                .shadow(color: WanderTheme.textInk.color.opacity(0.14), radius: 10, x: 0, y: 5)
        }
        .disabled(isLoading)
        .accessibilityLabel("Center on my location")
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

private struct SearchResultMarker: View {
    let candidate: PlaceCandidate
    let isSelected: Bool

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: isSelected ? 17 : 15, weight: .black))
            .frame(width: isSelected ? 42 : 38, height: isSelected ? 42 : 38)
            .background(WanderTheme.pinSocial.color)
            .foregroundStyle(WanderTheme.surfaceRaised.color)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(WanderTheme.surfaceRaised.color, lineWidth: isSelected ? 4 : 3)
            )
            .overlay(
                Circle()
                    .stroke(WanderTheme.pinSocial.color, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                    .padding(-5)
            )
            .shadow(color: WanderTheme.textInk.color.opacity(0.18), radius: isSelected ? 9 : 6, x: 0, y: 2)
            .scaleEffect(isSelected ? 1.08 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.78), value: isSelected)
            .accessibilityLabel("Unsaved map result, \(candidate.name)")
    }

    private var symbol: String {
        WanderPlaceCategory.symbolName(for: candidate.category)
    }
}

private struct MapPlaceMarker: View {
    let visiblePlace: VisiblePlace
    let isCurrentUser: Bool
    let isSelected: Bool

    var body: some View {
        WanderMapPin(visiblePlace: visiblePlace, isCurrentUser: isCurrentUser, isSelected: isSelected)
        .scaleEffect(isSelected ? 1.08 : 1)
        .animation(.spring(response: 0.24, dampingFraction: 0.78), value: isSelected)
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
        WanderPlaceCategory.symbolName(for: visiblePlace.place.category)
    }
}

private enum PlaceSheetAction {
    case add
    case edit
    case none

    var systemImage: String {
        switch self {
        case .add: "plus"
        case .edit: "pencil"
        case .none: ""
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .add: "Save to my map"
        case .edit: "Edit saved place"
        case .none: ""
        }
    }
}

private struct PlaceSaveSummary: Identifiable {
    let visiblePlace: VisiblePlace
    let attributes: [LocalPlaceAttribute]

    var id: String { visiblePlace.userPlace.id }
}

private struct SearchCandidateSheet: View {
    let candidate: PlaceCandidate
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing3) {
            Capsule()
                .fill(WanderTheme.borderStrong.color)
                .frame(width: 42, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.vertical, WanderTheme.spacing1)

            HStack(alignment: .center, spacing: WanderTheme.spacing3) {
                CategoryThumb(category: candidate.category)

                VStack(alignment: .leading, spacing: WanderTheme.spacing1) {
                    Text(candidate.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(WanderTheme.textInk.color)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                    Text(candidateSubtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(WanderTheme.textMuted.color)
                        .lineLimit(2)
                    Text("not saved yet")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(WanderTheme.terracotta.color)
                        .padding(.horizontal, WanderTheme.spacing2)
                        .padding(.vertical, WanderTheme.spacing1)
                        .background(WanderTheme.terracottaTint.color)
                        .clipShape(Capsule())
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
                .accessibilityLabel("Add map result")
            }
        }
        .padding(WanderTheme.spacing3)
        .background(WanderTheme.surfaceBone.color)
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusSheet))
        .shadow(color: WanderTheme.textInk.color.opacity(0.14), radius: 20, x: 0, y: 10)
    }

    private var candidateSubtitle: String {
        [
            candidate.locality,
            candidate.category == "place" ? nil : candidate.category
        ]
        .compactMap { value -> String? in
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed?.isEmpty == false ? trimmed : nil
        }
        .joined(separator: " · ")
    }
}

private struct PlaceSheet: View {
    let visiblePlace: VisiblePlace
    let saves: [PlaceSaveSummary]
    let currentUserID: String
    let action: PlaceSheetAction
    @Binding var isExpanded: Bool
    let onAction: () -> Void
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing3) {
            Capsule()
                .fill(WanderTheme.borderStrong.color)
                .frame(width: 42, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.vertical, WanderTheme.spacing1)
                .accessibilityLabel(isExpanded ? "Place details expanded" : "Swipe up for place details")

            if isExpanded {
                ScrollView(showsIndicators: false) {
                    expandedContent
                }
                .frame(maxHeight: 560)
            } else {
                compactContent
            }
        }
        .padding(WanderTheme.spacing3)
        .background(WanderTheme.surfaceBone.color)
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusSheet))
        .shadow(color: WanderTheme.textInk.color.opacity(0.14), radius: 20, x: 0, y: 10)
        .simultaneousGesture(
            DragGesture(minimumDistance: 14, coordinateSpace: .local)
                .onEnded(handleSheetDrag)
        )
    }

    private var compactContent: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing3) {
            HStack(alignment: .center, spacing: WanderTheme.spacing3) {
                CategoryThumb(category: visiblePlace.place.category)

                VStack(alignment: .leading, spacing: WanderTheme.spacing1) {
                    HStack {
                        Text(visiblePlace.place.canonicalName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(WanderTheme.textInk.color)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                        StatusBadge(status: visiblePlace.userPlace.status)
                    }
                    if let subtitle = compactSubtitle {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(WanderTheme.textMuted.color)
                            .lineLimit(1)
                    }
                    if let note = visiblePlace.userPlace.note {
                        Text("\"\(note)\"")
                            .font(.system(size: 13))
                            .italic()
                            .foregroundStyle(WanderTheme.textMuted.color)
                            .lineLimit(2)
                    }
                }

                Spacer()

                actionButton(size: 46, iconSize: 21)
            }

            SocialProofRow(savers: savers, currentUserID: currentUserID, visibility: visiblePlace.userPlace.visibility)
        }
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing4) {
            expandedHeader
            SocialProofRow(savers: savers, currentUserID: currentUserID, visibility: visiblePlace.userPlace.visibility)
            externalActions

            if !placeFacts.isEmpty {
                factSection(title: "place", facts: placeFacts)
            }

            if let ownSave {
                VStack(alignment: .leading, spacing: WanderTheme.spacing2) {
                    sectionTitle("your save")
                    SaveReviewCard(summary: ownSave, currentUserID: currentUserID, emphasis: true)
                }
            }

            if !friendSaves.isEmpty {
                VStack(alignment: .leading, spacing: WanderTheme.spacing2) {
                    sectionTitle("friends' thoughts")
                    ForEach(friendSaves) { summary in
                        SaveReviewCard(summary: summary, currentUserID: currentUserID, emphasis: false)
                    }
                }
            }
        }
        .padding(.bottom, WanderTheme.spacing1)
    }

    private var expandedHeader: some View {
        HStack(alignment: .top, spacing: WanderTheme.spacing3) {
            CategoryThumb(category: visiblePlace.place.category)
            VStack(alignment: .leading, spacing: WanderTheme.spacing1) {
                Text(visiblePlace.place.canonicalName)
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(WanderTheme.textInk.color)
                    .lineLimit(3)
                    .minimumScaleFactor(0.78)

                if let subtitle = expandedSubtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(WanderTheme.textMuted.color)
                        .lineLimit(2)
                }

                StatusBadge(status: visiblePlace.userPlace.status)
            }
            Spacer(minLength: WanderTheme.spacing2)
            VStack(spacing: WanderTheme.spacing2) {
                shareButton
                actionButton(size: 42, iconSize: 18)
            }
        }
    }

    private var externalActions: some View {
        HStack(spacing: WanderTheme.spacing2) {
            if let directionsURL {
                PlaceExternalActionButton(title: "Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill") {
                    openURL(directionsURL)
                }
            }
        }
    }

    @ViewBuilder
    private var shareButton: some View {
        if let shareURL {
            ShareLink(item: shareURL, subject: Text(visiblePlace.place.canonicalName), message: Text(shareText)) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 17, weight: .black))
                    .frame(width: 42, height: 42)
                    .background(WanderTheme.surfaceSand.color)
                    .foregroundStyle(WanderTheme.textInk.color)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Share place")
        }
    }

    private func factSection(title: String, facts: [PlaceFact]) -> some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing2) {
            sectionTitle(title)
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 106), spacing: WanderTheme.spacing2)],
                alignment: .leading,
                spacing: WanderTheme.spacing2
            ) {
                ForEach(facts) { fact in
                    PlaceFactPill(title: fact.title, systemImage: fact.systemImage)
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .black))
            .textCase(.uppercase)
            .foregroundStyle(WanderTheme.textMuted.color)
    }

    private var savers: [LocalProfile] {
        saves.map(\.visiblePlace.owner)
    }

    private var ownSave: PlaceSaveSummary? {
        saves.first { $0.visiblePlace.owner.id == currentUserID }
    }

    private var friendSaves: [PlaceSaveSummary] {
        saves.filter { $0.visiblePlace.owner.id != currentUserID }
    }

    private var compactSubtitle: String? {
        joinedText([visiblePlace.place.locality, categoryDisplay])
    }

    private var expandedSubtitle: String? {
        joinedText([addressLine, categoryDisplay])
    }

    private var addressLine: String? {
        let address = trimmed(visiblePlace.place.address)
        if let address {
            return address
        }
        return joinedText([visiblePlace.place.locality, visiblePlace.place.region])
    }

    private var categoryDisplay: String? {
        let category = trimmed(visiblePlace.place.category)
        return category == "place" ? nil : category
    }

    private var placeFacts: [PlaceFact] {
        var facts: [PlaceFact] = []
        if let categoryDisplay {
            facts.append(PlaceFact(title: categoryDisplay, systemImage: WanderPlaceCategory.symbolName(for: visiblePlace.place.category)))
        }
        if let addressLine {
            facts.append(PlaceFact(title: addressLine, systemImage: "mappin.and.ellipse"))
        }
        return facts
    }

    private var directionsURL: URL? {
        PlaceExternalLinks.googleMapsDirectionsURL(
            placeName: visiblePlace.place.canonicalName,
            latitude: visiblePlace.place.latitude,
            longitude: visiblePlace.place.longitude
        )
    }

    private var shareURL: URL? {
        PlaceExternalLinks.googleMapsSearchURL(
            placeName: visiblePlace.place.canonicalName,
            address: visiblePlace.place.address,
            locality: visiblePlace.place.locality
        )
    }

    private var shareText: String {
        PlaceExternalLinks.shareSummary(
            placeName: visiblePlace.place.canonicalName,
            locality: visiblePlace.place.locality,
            status: visiblePlace.userPlace.status
        )
    }

    private func joinedText(_ values: [String?]) -> String? {
        let parts = values.compactMap(trimmed)
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func trimmed(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == false ? trimmed : nil
    }

    private static func facts(for attribute: LocalPlaceAttribute) -> [PlaceFact] {
        if attribute.valueType == "multi_tag" {
            return decodedStringArray(from: attribute.valueJSON).map { value in
                PlaceFact(title: value, systemImage: icon(for: attribute.questionKey))
            }
        }

        guard let value = decodedString(from: attribute.valueJSON) else { return [] }
        return [PlaceFact(title: value, systemImage: icon(for: attribute.questionKey))]
    }

    private static func icon(for questionKey: String) -> String {
        switch questionKey {
        case "rating_signal": "heart.fill"
        case "work_setup": "laptopcomputer"
        case "strenuousness": "figure.hiking"
        case "price": "dollarsign.circle.fill"
        case "occasion", "best_for": "sparkles"
        default: "tag.fill"
        }
    }

    private static func decodedString(from valueJSON: String) -> String? {
        guard let data = valueJSON.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(String.self, from: data)
    }

    private static func decodedStringArray(from valueJSON: String) -> [String] {
        guard let data = valueJSON.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    private func handleSheetDrag(_ value: DragGesture.Value) {
        let verticalIntent = value.translation.height
        guard abs(verticalIntent) > abs(value.translation.width), abs(verticalIntent) > 24 else { return }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
            isExpanded = verticalIntent < 0
        }
    }

    @ViewBuilder
    private func actionButton(size: CGFloat, iconSize: CGFloat) -> some View {
        if action != .none {
            Button(action: onAction) {
                Image(systemName: action.systemImage)
                    .font(.system(size: iconSize, weight: .black))
                    .frame(width: size, height: size)
                    .background(action == .add ? WanderTheme.terracotta.color : WanderTheme.textInk.color)
                    .foregroundStyle(WanderTheme.textOnAction.color)
                    .clipShape(Circle())
            }
            .accessibilityLabel(action.accessibilityLabel)
        }
    }
}

private struct PlaceFact: Identifiable {
    var id: String { "\(systemImage)-\(title)" }
    let title: String
    let systemImage: String
}

private struct PlaceExternalActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: WanderTheme.spacing1) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .black))
                Text(title)
                    .font(.system(size: 13, weight: .black))
                    .lineLimit(1)
            }
            .frame(minHeight: 42)
            .padding(.horizontal, WanderTheme.spacing4)
            .background(WanderTheme.surfaceRaised.color)
            .foregroundStyle(WanderTheme.textInk.color)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(WanderTheme.borderHairline.color, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private struct SaveReviewCard: View {
    let summary: PlaceSaveSummary
    let currentUserID: String
    let emphasis: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing2) {
            HStack(alignment: .center, spacing: WanderTheme.spacing2) {
                WanderAvatar(initials: owner.initials, size: 34, color: avatarColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(owner.id == currentUserID ? "You" : owner.displayName)
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(WanderTheme.textInk.color)
                    Text("@\(owner.handle)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(WanderTheme.textMuted.color)
                }
                Spacer()
                StatusBadge(status: userPlace.status)
            }

            if let note {
                Text(note)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(WanderTheme.textInk.color)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !facts.isEmpty {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 104), spacing: WanderTheme.spacing2)],
                    alignment: .leading,
                    spacing: WanderTheme.spacing2
                ) {
                    ForEach(facts) { fact in
                        PlaceFactPill(title: fact.title, systemImage: fact.systemImage)
                    }
                }
            }
        }
        .padding(WanderTheme.spacing3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(emphasis ? WanderTheme.surfaceSand.color : WanderTheme.surfaceRaised.color)
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: WanderTheme.radiusLarge)
                .stroke(emphasis ? WanderTheme.borderStrong.color.opacity(0.5) : WanderTheme.borderHairline.color, lineWidth: 1)
        )
    }

    private var owner: LocalProfile {
        summary.visiblePlace.owner
    }

    private var userPlace: LocalUserPlace {
        summary.visiblePlace.userPlace
    }

    private var note: String? {
        let trimmed = userPlace.note?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == false ? trimmed : nil
    }

    private var facts: [PlaceFact] {
        var facts: [PlaceFact] = []

        if owner.id == currentUserID {
            facts.append(PlaceFact(title: userPlace.visibility.displayTitle, systemImage: "eye.fill"))
        }

        if let ratingSignal = userPlace.ratingSignal,
           !summary.attributes.contains(where: { $0.questionKey == "rating_signal" }) {
            facts.append(PlaceFact(title: ratingSignal, systemImage: "heart.fill"))
        }

        facts.append(contentsOf: summary.attributes.flatMap(attributeFacts(for:)))
        return facts
    }

    private var avatarColor: Color {
        if owner.id == currentUserID { return WanderTheme.terracotta.color }
        return owner.handle == "ryan" ? WanderTheme.avatarRyan.color : WanderTheme.pinSocial.color
    }

    private func attributeFacts(for attribute: LocalPlaceAttribute) -> [PlaceFact] {
        if attribute.valueType == "multi_tag" {
            return decodedStringArray(from: attribute.valueJSON).map { value in
                PlaceFact(title: value, systemImage: icon(for: attribute.questionKey))
            }
        }

        guard let value = decodedString(from: attribute.valueJSON) else { return [] }
        return [PlaceFact(title: value, systemImage: icon(for: attribute.questionKey))]
    }

    private func icon(for questionKey: String) -> String {
        switch questionKey {
        case "rating_signal": "heart.fill"
        case "work_setup": "laptopcomputer"
        case "strenuousness": "figure.hiking"
        case "price": "dollarsign.circle.fill"
        case "occasion", "best_for": "sparkles"
        default: "tag.fill"
        }
    }

    private func decodedString(from valueJSON: String) -> String? {
        guard let data = valueJSON.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(String.self, from: data)
    }

    private func decodedStringArray(from valueJSON: String) -> [String] {
        guard let data = valueJSON.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
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
                .foregroundStyle(WanderTheme.textInk.color)
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
                .minimumScaleFactor(0.82)
        }
        .font(.system(size: 12, weight: .bold))
        .padding(.horizontal, WanderTheme.spacing3)
        .frame(minHeight: 36)
        .background(WanderTheme.surfaceSand.color)
        .foregroundStyle(WanderTheme.textInk.color)
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
        WanderPlaceCategory.symbolName(for: category)
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
