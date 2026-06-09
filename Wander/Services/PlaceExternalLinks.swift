import Foundation

enum PlaceExternalLinks {
    static func googleMapsDirectionsURL(
        placeName: String,
        latitude: Double,
        longitude: Double
    ) -> URL? {
        guard isValid(latitude: latitude, longitude: longitude) else { return nil }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.google.com"
        components.path = "/maps/dir/"
        components.queryItems = [
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(name: "destination", value: "\(latitude),\(longitude)")
        ]
        return components.url
    }

    static func googleMapsSearchURL(
        placeName: String,
        address: String? = nil,
        locality: String? = nil
    ) -> URL? {
        let query = [
            trimmed(placeName),
            trimmed(address),
            trimmed(locality)
        ]
        .compactMap { value -> String? in
            guard let value, !value.isEmpty else { return nil }
            return value
        }
        .joined(separator: " ")

        guard !query.isEmpty else { return nil }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.google.com"
        components.path = "/maps/search/"
        components.queryItems = [
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(name: "query", value: query)
        ]
        return components.url
    }

    static func shareSummary(placeName: String, locality: String?, status: PlaceStatus?) -> String {
        let placeLine = [
            trimmed(placeName),
            trimmed(locality)
        ]
        .compactMap { value -> String? in
            guard let value, !value.isEmpty else { return nil }
            return value
        }
        .joined(separator: " · ")

        guard let status else { return placeLine }
        return "\(placeLine) · \(status.displayTitle)"
    }

    private static func trimmed(_ value: String?) -> String? {
        value?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isValid(latitude: Double, longitude: Double) -> Bool {
        (-90...90).contains(latitude) && (-180...180).contains(longitude)
    }
}
