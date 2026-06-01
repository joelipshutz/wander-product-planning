import Foundation

struct DiscoverFilters: Equatable {
    var query: String
    var categories: Set<String> = []
    var area: String?
    var statuses: Set<PlaceStatus> = []
    var relationship: ViewerRelationship?
}

struct VisiblePlace: Identifiable, Equatable {
    let id: String
    let place: LocalPlace
    let userPlace: LocalUserPlace
    let owner: LocalProfile
}

protocol LLMFilterParser {
    func parse(query: String, schema: DiscoverFilterSchema) async throws -> DiscoverFilters
}

struct DiscoverFilterSchema: Equatable {
    let allowedCategories: [String]
    let allowedStatuses: [PlaceStatus]
}

struct CheapFixtureFilterParser: LLMFilterParser {
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

        if normalized.contains("friend") {
            filters.relationship = .mutual
        }

        return filters
    }
}
