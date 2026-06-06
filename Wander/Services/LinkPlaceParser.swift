import Foundation

struct LinkPlaceParser {
    func manualInput(from input: LinkPlaceInput) -> ManualPlaceInput? {
        let rawValue = input.rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawValue.isEmpty else { return nil }

        guard let url = URL(string: rawValue),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host?.lowercased()
        else {
            return ManualPlaceInput(name: rawValue, areaHint: nil, category: nil)
        }

        if let queryValue = queryPlaceName(from: components) {
            return ManualPlaceInput(name: queryValue, areaHint: areaHint(from: components), category: nil)
        }

        if isGoogleMapsHost(host) || isAppleMapsHost(host) {
            return mapPathInput(from: components)
        }

        if isInstagramLocationURL(host: host, components: components) {
            return instagramLocationInput(from: components)
        }

        return nil
    }

    private func queryPlaceName(from components: URLComponents) -> String? {
        let preferredKeys = ["q", "query", "destination", "daddr", "address", "place"]
        return firstQueryValue(in: components, keys: preferredKeys)
    }

    private func areaHint(from components: URLComponents) -> String? {
        firstQueryValue(in: components, keys: ["near", "ll", "sll"])
    }

    private func firstQueryValue(in components: URLComponents, keys: [String]) -> String? {
        let items = components.queryItems ?? []

        for key in keys {
            guard let value = items.first(where: { $0.name.lowercased() == key })?.value,
                  let cleaned = cleanedPlaceText(value)
            else {
                continue
            }
            return cleaned
        }

        return nil
    }

    private func mapPathInput(from components: URLComponents) -> ManualPlaceInput? {
        let pieces = normalizedPathPieces(from: components)
        guard let index = pieces.firstIndex(where: { ["place", "search"].contains($0.lowercased()) }),
              pieces.indices.contains(index + 1),
              let name = cleanedPlaceText(pieces[index + 1])
        else {
            return nil
        }

        return ManualPlaceInput(name: name, areaHint: nil, category: nil)
    }

    private func instagramLocationInput(from components: URLComponents) -> ManualPlaceInput? {
        let pieces = normalizedPathPieces(from: components)
        guard let index = pieces.firstIndex(where: { $0.lowercased() == "locations" }),
              pieces.indices.contains(index + 2),
              let name = cleanedPlaceText(pieces[index + 2])
        else {
            return nil
        }

        return ManualPlaceInput(name: name, areaHint: nil, category: nil)
    }

    private func normalizedPathPieces(from components: URLComponents) -> [String] {
        components.path
            .split(separator: "/")
            .map(String.init)
            .compactMap { piece -> String? in
                guard !piece.hasPrefix("@"), !piece.hasPrefix("data=") else { return nil }
                return piece.removingPercentEncoding ?? piece
            }
    }

    private func isGoogleMapsHost(_ host: String) -> Bool {
        host == "maps.google.com" || host.contains(".google.") || host == "google.com"
    }

    private func isAppleMapsHost(_ host: String) -> Bool {
        host == "maps.apple.com"
    }

    private func isInstagramLocationURL(host: String, components: URLComponents) -> Bool {
        host == "instagram.com" || host.hasSuffix(".instagram.com")
            ? components.path.lowercased().contains("/explore/locations/")
            : false
    }

    private func cleanedPlaceText(_ value: String) -> String? {
        let decoded = value.removingPercentEncoding ?? value
        let trimmed = decoded
            .replacingOccurrences(of: "+", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty,
              !trimmed.hasPrefix("@"),
              !trimmed.contains("!"),
              !isLikelyCoordinate(trimmed)
        else {
            return nil
        }

        return trimmed
    }

    private func isLikelyCoordinate(_ value: String) -> Bool {
        let pattern = #"^-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?$"#
        return value.range(of: pattern, options: .regularExpression) != nil
    }
}
