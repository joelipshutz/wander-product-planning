import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var store: InMemoryWanderStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Settings")
                    .font(.largeTitle.weight(.bold))

                SettingSection(title: "Sharing default") {
                    HStack {
                        WanderChip(title: "Everyone", isSelected: true)
                        WanderChip(title: "Friends")
                        WanderChip(title: "Self")
                    }
                    Text("Everyone is followers-only. Full profile privacy comes later.")
                        .font(.footnote)
                        .foregroundStyle(WanderTheme.espresso.opacity(0.7))
                }

                SettingSection(title: "Blocked people") {
                    if store.blockedProfiles().isEmpty {
                        Text("Nobody blocked.")
                            .foregroundStyle(WanderTheme.espresso.opacity(0.7))
                    } else {
                        ForEach(store.blockedProfiles()) { profile in
                            HStack {
                                Text("@\(profile.handle)")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "hand.raised.fill")
                                    .foregroundStyle(WanderTheme.clay)
                            }
                            .padding(16)
                            .background(WanderTheme.sand.opacity(0.35))
                            .clipShape(RoundedRectangle(cornerRadius: WanderTheme.cornerRadius))
                        }
                    }
                }

                SettingSection(title: "Planned") {
                    Label("Native Contacts permission", systemImage: "person.crop.circle.badge.plus")
                    Label("Share extension", systemImage: "square.and.arrow.up")
                    Label("Private profiles and follow requests", systemImage: "lock.fill")
                }
                .font(.headline)
            }
            .padding(20)
        }
        .wanderScreen()
    }
}

private struct SettingSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(WanderTheme.sand.opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.cornerRadius))
    }
}
