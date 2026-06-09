import Foundation

struct DiscoverFilters: Equatable {
    var query: String
    var categories: Set<String> = []
    var area: String?
    var statuses: Set<PlaceStatus> = []
    var relationship: ViewerRelationship?
    var tags: Set<String> = []
}

struct DiscoverFilterChip: Identifiable, Equatable {
    let id: String
    let title: String
}

extension DiscoverFilters {
    var chips: [DiscoverFilterChip] {
        var chips: [DiscoverFilterChip] = []

        chips.append(contentsOf: categories.sorted().map { category in
            DiscoverFilterChip(id: "category_\(category)", title: category)
        })

        chips.append(contentsOf: statuses.sorted { $0.rawValue < $1.rawValue }.map { status in
            DiscoverFilterChip(id: "status_\(status.rawValue)", title: status.displayTitle)
        })

        if let relationship {
            chips.append(DiscoverFilterChip(id: "relationship_\(relationship.rawValue)", title: relationship.discoverChipTitle))
        }

        if let area {
            chips.append(DiscoverFilterChip(id: "area_\(area)", title: area))
        }

        chips.append(contentsOf: tags.sorted().map { tag in
            DiscoverFilterChip(id: "tag_\(tag)", title: tag)
        })

        return chips
    }
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
    var attributes: [LocalPlaceAttribute] = []
}

struct DiscoverResults {
    let places: [VisiblePlace]
    let profiles: [ProfileShell]
}

enum DiscoverPlaceScope: String, CaseIterable, Identifiable, Equatable {
    case myPlaces = "my_places"
    case friendsPlaces = "friends_places"
    case everyone

    var id: String { rawValue }

    var title: String {
        switch self {
        case .myPlaces: "mine"
        case .friendsPlaces: "friends"
        case .everyone: "everyone"
        }
    }

    var ownerScopes: Set<String> {
        switch self {
        case .myPlaces: ["you"]
        case .friendsPlaces: ["friends"]
        case .everyone: ["you", "following", "friends"]
        }
    }
}

@MainActor
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

        for (category, aliases) in Self.categoryAliases where schema.allowedCategories.contains(category) {
            if aliases.contains(where: { normalized.contains($0) }) {
                filters.categories.insert(category)
            }
        }

        if normalized.contains("been") || normalized.contains("went") || normalized.contains("tried") || normalized.contains("liked") {
            filters.statuses.insert(.been)
        }

        if normalized.contains("wanna") || normalized.contains("want") || normalized.contains("try") || normalized.contains("saved") {
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

        for area in ["eastside", "silver lake", "larchmont", "echo park", "los feliz"] where normalized.contains(area) {
            filters.area = area
        }

        for tag in Self.knownTags where normalized.contains(tag) {
            filters.tags.insert(tag)
        }

        return filters
    }

    private static let categoryAliases: [String: [String]] = [
        "coffee": ["coffee", "cafe", "cafes", "work from"],
        "restaurant": ["restaurant", "restaurants", "noodle", "noodles", "dinner", "lunch"],
        "hike": ["hike", "hikes", "trail", "trails"],
        "bar": ["bar", "bars", "drink", "drinks", "patio"],
        "park": ["park", "parks"]
    ]

    private static let knownTags = [
        "wifi",
        "work",
        "patio",
        "quiet",
        "cozy",
        "views",
        "sunset",
        "group",
        "date",
        "dog friendly"
    ]
}

private extension ViewerRelationship {
    var discoverChipTitle: String {
        switch self {
        case .owner: "mine"
        case .mutual: "friends"
        case .follower: "following"
        case .nonFollower: "other people"
        }
    }
}
