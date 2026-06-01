import SwiftUI

struct WanderColorToken: Equatable {
    let name: String
    let hex: String

    var color: Color {
        Color(hex: hex)
    }
}

enum WanderTheme {
    static let canvasWarm = WanderColorToken(name: "color.canvas.warm", hex: "#F3DFCA")
    static let surfaceBone = WanderColorToken(name: "color.surface.bone", hex: "#FFF7EA")
    static let surfaceRaised = WanderColorToken(name: "color.surface.raised", hex: "#FFFFFF")
    static let surfaceSand = WanderColorToken(name: "color.surface.sand", hex: "#EFE3D0")

    static let textInk = WanderColorToken(name: "color.text.ink", hex: "#2C2118")
    static let textMuted = WanderColorToken(name: "color.text.muted", hex: "#7B6555")
    static let textFaint = WanderColorToken(name: "color.text.faint", hex: "#A8957F")
    static let textOnAction = WanderColorToken(name: "color.text.onAction", hex: "#FFF7EA")

    static let borderHairline = WanderColorToken(name: "color.border.hairline", hex: "#DBC2AA")
    static let borderStrong = WanderColorToken(name: "color.border.strong", hex: "#C9AC8F")

    static let terracotta = WanderColorToken(name: "color.action.terracotta", hex: "#D46F4D")
    static let terracottaDark = WanderColorToken(name: "color.action.terracottaDark", hex: "#A94F35")
    static let terracottaTint = WanderColorToken(name: "color.action.terracottaTint", hex: "#F6E0D2")
    static let sunTint = WanderColorToken(name: "color.surface.sunTint", hex: "#F4E8C9")
    static let skyTint = WanderColorToken(name: "color.surface.skyTint", hex: "#DBEAF1")

    static let pinYou = WanderColorToken(name: "color.pin.you", hex: "#D46F4D")
    static let pinSocial = WanderColorToken(name: "color.pin.social", hex: "#69B8D7")

    static let categoryMoss = WanderColorToken(name: "color.category.moss", hex: "#6F8F5F")
    static let categorySun = WanderColorToken(name: "color.category.sun", hex: "#E3B64B")
    static let categorySage = WanderColorToken(name: "color.category.sage", hex: "#A0B98A")

    static let stateSuccess = WanderColorToken(name: "color.state.success", hex: "#3F8F64")
    static let stateWarning = WanderColorToken(name: "color.state.warning", hex: "#B98528")
    static let stateError = WanderColorToken(name: "color.state.error", hex: "#B84A3A")
    static let stateInfo = WanderColorToken(name: "color.state.info", hex: "#4F8EAD")

    static let avatarJames = WanderColorToken(name: "color.avatar.james", hex: "#D4623F")
    static let avatarRyan = WanderColorToken(name: "color.avatar.ryan", hex: "#6F8F5F")
    static let avatarAndrew = WanderColorToken(name: "color.avatar.andrew", hex: "#E3B64B")
    static let avatarSofia = WanderColorToken(name: "color.avatar.sofia", hex: "#69B8D7")

    static let spacing1: CGFloat = 4
    static let spacing2: CGFloat = 8
    static let spacing3: CGFloat = 12
    static let spacing4: CGFloat = 16
    static let spacing6: CGFloat = 24
    static let spacing8: CGFloat = 32
    static let spacing12: CGFloat = 48
    static let spacing16: CGFloat = 64

    static let radiusSmall: CGFloat = 8
    static let radiusMedium: CGFloat = 12
    static let radiusLarge: CGFloat = 16
    static let radiusSheet: CGFloat = 24
    static let radiusPill: CGFloat = 999

    static let tapMinimum: CGFloat = 44

    static let allColorTokens: [WanderColorToken] = [
        canvasWarm, surfaceBone, surfaceRaised, surfaceSand,
        textInk, textMuted, textFaint, textOnAction,
        borderHairline, borderStrong,
        terracotta, terracottaDark, terracottaTint, sunTint, skyTint,
        pinYou, pinSocial,
        categoryMoss, categorySun, categorySage,
        stateSuccess, stateWarning, stateError, stateInfo,
        avatarJames, avatarRyan, avatarAndrew, avatarSofia
    ]
}

private extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255

        self.init(red: red, green: green, blue: blue)
    }
}

struct WanderScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(WanderTheme.canvasWarm.color.ignoresSafeArea())
            .foregroundStyle(WanderTheme.textInk.color)
    }
}

extension View {
    func wanderScreen() -> some View {
        modifier(WanderScreenBackground())
    }
}

struct WanderChip: View {
    let title: String
    var isSelected = false

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, WanderTheme.spacing4)
            .frame(minHeight: WanderTheme.tapMinimum)
            .background(isSelected ? WanderTheme.textInk.color : WanderTheme.surfaceSand.color)
            .foregroundStyle(isSelected ? WanderTheme.textOnAction.color : WanderTheme.textInk.color)
            .clipShape(Capsule())
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
