import SwiftUI

enum WanderTheme {
    static let cream = Color(red: 0.98, green: 0.94, blue: 0.86)
    static let sand = Color(red: 0.88, green: 0.78, blue: 0.62)
    static let clay = Color(red: 0.54, green: 0.31, blue: 0.22)
    static let terracotta = Color(red: 0.78, green: 0.30, blue: 0.16)
    static let espresso = Color(red: 0.15, green: 0.10, blue: 0.07)
    static let sage = Color(red: 0.47, green: 0.58, blue: 0.42)
    static let mustard = Color(red: 0.86, green: 0.62, blue: 0.16)
    static let sky = Color(red: 0.41, green: 0.61, blue: 0.69)

    static let cornerRadius: CGFloat = 24
}

struct WanderScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(WanderTheme.cream.ignoresSafeArea())
            .foregroundStyle(WanderTheme.espresso)
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
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(isSelected ? WanderTheme.espresso : WanderTheme.sand.opacity(0.45))
            .foregroundStyle(isSelected ? WanderTheme.cream : WanderTheme.espresso)
            .clipShape(Capsule())
    }
}
