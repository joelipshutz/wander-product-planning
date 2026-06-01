import Foundation

struct DiscoverFilters: Equatable {
    var query: String
    var categories: Set<String> = []
    var area: String?
    var statuses: Set<PlaceStatus> = []
    var relationship: ViewerRelationship?
    var tags: Set<String> = []
}

struct DiscoverFilterSchema: Equatable {
    let allowedCategories: [String]
    let allowedStatuses: [PlaceStatus]
    let allowedRelationships: [ViewerRelationship]
}

struct VisiblePlace: Identifiable {
    let id: String
    let place: LocalPlace
    let userPlace: LocalUserPlace
    let owner: LocalProfile
}

struct DiscoverResults {
    let places: [VisiblePlace]
    let profiles: [ProfileShell]
}

protocol LLMFilterParser {
    func parse(query: String, schema: DiscoverFilterSchema) async throws -> DiscoverFilters
}

struct DeterministicFilterParser: LLMFilterParser {
    func parse(query: String, schema: DiscoverFilterSchema) async throws -> DiscoverFilters {
        let normalized = query.lowercased()
        var filters = DiscoverFilters(query: query)

        for category in schema.allowedCategories where normalized.contains(category.lowercased()) {
            filters.categories.insert(category)
        }

        if normalized.contains("been") {
            filters.statuses.insert(.been)
        }

        if normalized.contains("wanna") || normalized.contains("want") {
            filters.statuses.insert(.wannaGo)
        }

        if normalized.contains("friend") || normalized.contains("mutual") {
            filters.relationship = .mutual
        } else if normalized.contains("following") || normalized.contains("people") {
            filters.relationship = .follower
        }

        if normalized.contains("la") || normalized.contains("los angeles") {
            filters.area = "LA"
        }

        return filters
    }
}
