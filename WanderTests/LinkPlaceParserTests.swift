import XCTest
@testable import Wander

final class LinkPlaceParserTests: XCTestCase {
    private let parser = LinkPlaceParser()

    func testParsesGoogleMapsPlacePath() {
        let input = parser.manualInput(
            from: LinkPlaceInput(rawValue: "https://www.google.com/maps/place/Larchmont+Noodles/@34.073,-118.323,17z")
        )

        XCTAssertEqual(input, ManualPlaceInput(name: "Larchmont Noodles", areaHint: nil, category: nil))
    }

    func testParsesAppleMapsQuery() {
        let input = parser.manualInput(
            from: LinkPlaceInput(rawValue: "https://maps.apple.com/?q=Maru%20Coffee&ll=34.0407,-118.2354")
        )

        XCTAssertEqual(input, ManualPlaceInput(name: "Maru Coffee", areaHint: nil, category: nil))
    }

    func testParsesInstagramLocationSlug() {
        let input = parser.manualInput(
            from: LinkPlaceInput(rawValue: "https://www.instagram.com/explore/locations/123456789/larchmont-noodles/")
        )

        XCTAssertEqual(input, ManualPlaceInput(name: "larchmont noodles", areaHint: nil, category: nil))
    }

    func testRejectsOpaqueShortLinkWithoutPlaceHint() {
        let input = parser.manualInput(from: LinkPlaceInput(rawValue: "https://maps.app.goo.gl/abc123"))

        XCTAssertNil(input)
    }

    func testTreatsPlainTextAsManualHint() {
        let input = parser.manualInput(from: LinkPlaceInput(rawValue: "Courage Bagels near Virgil"))

        XCTAssertEqual(input, ManualPlaceInput(name: "Courage Bagels near Virgil", areaHint: nil, category: nil))
    }
}
