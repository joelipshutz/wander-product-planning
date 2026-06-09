import MapKit

enum WanderPlaceCategory {
    static func primary(for pointCategory: MKPointOfInterestCategory?) -> String? {
        switch pointCategory {
        case .cafe, .bakery:
            "coffee"
        case .restaurant, .foodMarket:
            "restaurant"
        case .brewery, .winery, .nightlife:
            "bar"
        case .park, .nationalPark:
            "park"
        default:
            nil
        }
    }

    static func symbolName(for category: String) -> String {
        switch category {
        case "coffee":
            "cup.and.saucer.fill"
        case "hike":
            "figure.hiking"
        case "restaurant":
            "fork.knife"
        case "bar":
            "wineglass.fill"
        case "park":
            "tree.fill"
        default:
            "mappin"
        }
    }
}
