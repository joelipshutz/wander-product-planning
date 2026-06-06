import CoreLocation
import Foundation
import MapKit

enum PlaceResolutionError: Error, Equatable {
    case locationDenied
    case locationUnavailable
    case noCandidates
}

extension PlaceResolutionError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .locationDenied:
            "Location is off for Wander. Turn it on or add the place manually."
        case .locationUnavailable:
            "Could not find where you are right now. Try adding the place manually."
        case .noCandidates:
            "No matching places found. Try a more specific name or nearby area."
        }
    }
}

@MainActor
final class MapKitPlaceResolver: PlaceCandidateResolving {
    private let locationProvider: CurrentLocationProviding

    init(locationProvider: CurrentLocationProviding = CoreLocationProvider()) {
        self.locationProvider = locationProvider
    }

    func resolveCurrentLocation() async throws -> [PlaceCandidate] {
        let location = try await locationProvider.currentLocation()
        let request = MKLocalPointsOfInterestRequest(center: location.coordinate, radius: 700)
        request.pointOfInterestFilter = .includingAll

        let response = try await MKLocalSearch(request: request).start()
        let candidates = mapItems(response.mapItems, fallbackCategory: nil, limit: 8)
        guard !candidates.isEmpty else {
            throw PlaceResolutionError.noCandidates
        }
        return candidates
    }

    func resolveManualEntry(_ input: ManualPlaceInput) async throws -> [PlaceCandidate] {
        let name = input.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return [] }

        let area = input.areaHint?.trimmingCharacters(in: .whitespacesAndNewlines)
        let category = input.category?.trimmingCharacters(in: .whitespacesAndNewlines)
        let query = [name, area]
            .compactMap { value -> String? in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: " ")

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.pointOfInterest, .address]

        let response = try await MKLocalSearch(request: request).start()
        let candidates = mapItems(response.mapItems, fallbackCategory: category, limit: 8)
        guard !candidates.isEmpty else {
            throw PlaceResolutionError.noCandidates
        }
        return candidates
    }

    private func mapItems(_ items: [MKMapItem], fallbackCategory: String?, limit: Int) -> [PlaceCandidate] {
        var seen = Set<String>()
        var candidates: [PlaceCandidate] = []

        for item in items {
            guard let name = item.name?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty,
                  CLLocationCoordinate2DIsValid(item.placemark.coordinate)
            else {
                continue
            }

            let sourceID = sourceProviderPlaceID(for: item, name: name)
            guard !seen.contains(sourceID) else { continue }
            seen.insert(sourceID)

            candidates.append(
                PlaceCandidate(
                    id: sourceID,
                    name: name,
                    category: category(for: item, fallbackCategory: fallbackCategory),
                    address: address(for: item.placemark),
                    locality: item.placemark.locality,
                    region: item.placemark.administrativeArea,
                    country: item.placemark.countryCode,
                    latitude: item.placemark.coordinate.latitude,
                    longitude: item.placemark.coordinate.longitude,
                    sourceProvider: "mapkit",
                    sourceProviderPlaceID: sourceID,
                    confidence: confidence(for: item, fallbackCategory: fallbackCategory)
                )
            )

            if candidates.count >= limit { break }
        }

        return candidates
    }

    private func category(for item: MKMapItem, fallbackCategory: String?) -> String {
        let fallback = fallbackCategory?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let pointCategory = item.pointOfInterestCategory

        if let fallback, !fallback.isEmpty, fallback != "place" {
            return fallback
        }

        switch pointCategory {
        case .cafe, .bakery:
            return "coffee"
        case .restaurant, .foodMarket:
            return "restaurant"
        case .brewery, .winery, .nightlife:
            return "bar"
        case .park, .nationalPark:
            return "park"
        default:
            return fallback?.isEmpty == false ? fallback ?? "place" : "place"
        }
    }

    private func confidence(for item: MKMapItem, fallbackCategory: String?) -> Double {
        if item.pointOfInterestCategory != nil {
            return 0.9
        }

        if fallbackCategory?.isEmpty == false {
            return 0.74
        }

        return 0.66
    }

    private func address(for placemark: MKPlacemark) -> String? {
        let street = [placemark.subThoroughfare, placemark.thoroughfare]
            .compactMap { value -> String? in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: " ")

        if !street.isEmpty { return street }
        return placemark.title
    }

    private func sourceProviderPlaceID(for item: MKMapItem, name: String) -> String {
        let coordinate = item.placemark.coordinate
        let lat = Int((coordinate.latitude * 100_000).rounded())
        let lng = Int((coordinate.longitude * 100_000).rounded())
        return "mapkit_\(slug(name))_\(lat)_\(lng)"
    }

    private func slug(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics
        let parts = value
            .lowercased()
            .unicodeScalars
            .map { allowed.contains($0) ? Character($0) : "-" }

        return String(parts)
            .split(separator: "-")
            .joined(separator: "-")
    }
}

@MainActor
protocol CurrentLocationProviding {
    func currentLocation() async throws -> CLLocation
}

@MainActor
final class CoreLocationProvider: NSObject, CurrentLocationProviding, @preconcurrency CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    func currentLocation() async throws -> CLLocation {
        let status = manager.authorizationStatus
        let authorizedStatus: CLAuthorizationStatus

        switch status {
        case .notDetermined:
            authorizedStatus = await requestAuthorization()
        default:
            authorizedStatus = status
        }

        guard authorizedStatus == .authorizedWhenInUse || authorizedStatus == .authorizedAlways else {
            throw PlaceResolutionError.locationDenied
        }

        return try await requestLocation()
    }

    private func requestAuthorization() async -> CLAuthorizationStatus {
        await withCheckedContinuation { continuation in
            authorizationContinuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    private func requestLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard let continuation = authorizationContinuation else { return }
        authorizationContinuation = nil
        continuation.resume(returning: manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let continuation = locationContinuation else { return }
        locationContinuation = nil

        guard let location = locations.last else {
            continuation.resume(throwing: PlaceResolutionError.locationUnavailable)
            return
        }

        continuation.resume(returning: location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard let continuation = locationContinuation else { return }
        locationContinuation = nil
        continuation.resume(throwing: PlaceResolutionError.locationUnavailable)
    }
}
