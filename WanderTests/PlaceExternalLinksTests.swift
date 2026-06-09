import XCTest
@testable import Wander

final class PlaceExternalLinksTests: XCTestCase {
    func testGoogleMapsDirectionsURLUsesCoordinatesWithoutApiKey() throws {
        let url = try XCTUnwrap(
            PlaceExternalLinks.googleMapsDirectionsURL(
                placeName: "Din Tai Fung",
                latitude: 34.0589,
                longitude: -118.4173
            )
        )
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))

        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "www.google.com")
        XCTAssertEqual(components.path, "/maps/dir/")
        XCTAssertEqual(components.queryItems?.first(where: { $0.name == "api" })?.value, "1")
        XCTAssertEqual(components.queryItems?.first(where: { $0.name == "destination" })?.value, "34.0589,-118.4173")
        XCTAssertNil(components.queryItems?.first(where: { $0.name.lowercased().contains("key") }))
    }

    func testGoogleMapsDirectionsURLRejectsInvalidCoordinates() {
        XCTAssertNil(
            PlaceExternalLinks.googleMapsDirectionsURL(
                placeName: "Bad Pin",
                latitude: 120,
                longitude: -118
            )
        )
    }

    func testGoogleMapsSearchURLUsesOnlyKnownText() throws {
        let url = try XCTUnwrap(
            PlaceExternalLinks.googleMapsSearchURL(
                placeName: "Woodcat Coffee",
                address: nil,
                locality: "Los Angeles"
            )
        )
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))

        XCTAssertEqual(components.path, "/maps/search/")
        XCTAssertEqual(components.queryItems?.first(where: { $0.name == "api" })?.value, "1")
        XCTAssertEqual(components.queryItems?.first(where: { $0.name == "query" })?.value, "Woodcat Coffee Los Angeles")
    }

    func testShareSummaryOmitsMissingMetadata() {
        XCTAssertEqual(
            PlaceExternalLinks.shareSummary(placeName: "Griffith Observatory Trail", locality: nil, status: .been),
            "Griffith Observatory Trail · been"
        )
    }
}
