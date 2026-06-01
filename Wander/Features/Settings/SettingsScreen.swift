import SwiftUI

struct SettingsScreen: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: WanderTheme.spacing4) {
                Text("Settings")
                    .font(.system(size: 28, weight: .bold))

                SettingsRow(title: "Profile and account")
                SettingsRow(title: "Default place visibility")
                SettingsRow(title: "Blocked users")
                SettingsRow(title: "Contacts")
                SettingsRow(title: "Notifications")
                SettingsRow(title: "Data and sync")

                Spacer()
            }
            .padding(WanderTheme.spacing6)
            .wanderScreen()
        }
    }
}

private struct SettingsRow: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(WanderTheme.textFaint.color)
        }
        .frame(minHeight: WanderTheme.tapMinimum)
        .padding(WanderTheme.spacing4)
        .background(WanderTheme.surfaceBone.color)
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusLarge))
    }
}
