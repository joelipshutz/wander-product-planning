import SwiftUI

struct ProfileScreen: View {
    @State private var showsSettings = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: WanderTheme.spacing4) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: WanderTheme.spacing1) {
                        Text("Joe")
                            .font(.system(size: 28, weight: .bold))
                        Text("@joe")
                            .font(.headline)
                            .foregroundStyle(WanderTheme.textMuted.color)
                    }
                    Spacer()
                    Button {
                        showsSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                    }
                    .accessibilityLabel("Settings")
                }

                Text("Settings is intentionally a Profile gear surface, not a fifth tab.")
                    .font(.body)
                    .foregroundStyle(WanderTheme.textMuted.color)

                HStack {
                    StatPill(value: "0", label: "been")
                    StatPill(value: "0", label: "wanna")
                    StatPill(value: "0", label: "friends")
                }

                Spacer()
            }
            .padding(WanderTheme.spacing6)
            .wanderScreen()
            .sheet(isPresented: $showsSettings) {
                SettingsScreen()
            }
        }
    }
}

private struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: WanderTheme.spacing1) {
            Text(value)
                .font(.title2.weight(.bold))
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(WanderTheme.textMuted.color)
        }
        .frame(maxWidth: .infinity, minHeight: WanderTheme.tapMinimum)
        .padding(WanderTheme.spacing3)
        .background(WanderTheme.surfaceBone.color)
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusLarge))
    }
}
