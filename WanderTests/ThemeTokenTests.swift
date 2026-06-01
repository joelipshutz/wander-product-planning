import XCTest
@testable import Wander

final class ThemeTokenTests: XCTestCase {
    func testColorTokensMatchHandoffHexValues() {
        let expected: [String: String] = [
            "color.canvas.warm": "#F3DFCA",
            "color.surface.bone": "#FFF7EA",
            "color.surface.raised": "#FFFFFF",
            "color.surface.sand": "#EFE3D0",
            "color.text.ink": "#2C2118",
            "color.text.muted": "#7B6555",
            "color.text.faint": "#A8957F",
            "color.text.onAction": "#FFF7EA",
            "color.border.hairline": "#DBC2AA",
            "color.border.strong": "#C9AC8F",
            "color.action.terracotta": "#D46F4D",
            "color.action.terracottaDark": "#A94F35",
            "color.action.terracottaTint": "#F6E0D2",
            "color.surface.sunTint": "#F4E8C9",
            "color.surface.skyTint": "#DBEAF1",
            "color.pin.you": "#D46F4D",
            "color.pin.social": "#69B8D7",
            "color.category.moss": "#6F8F5F",
            "color.category.sun": "#E3B64B",
            "color.category.sage": "#A0B98A",
            "color.state.success": "#3F8F64",
            "color.state.warning": "#B98528",
            "color.state.error": "#B84A3A",
            "color.state.info": "#4F8EAD",
            "color.avatar.james": "#D4623F",
            "color.avatar.ryan": "#6F8F5F",
            "color.avatar.andrew": "#E3B64B",
            "color.avatar.sofia": "#69B8D7"
        ]

        let actual = Dictionary(uniqueKeysWithValues: WanderTheme.allColorTokens.map { ($0.name, $0.hex) })
        XCTAssertEqual(actual, expected)
    }
}
