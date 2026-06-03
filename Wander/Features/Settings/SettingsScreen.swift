import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var store: WanderStore
    @EnvironmentObject private var auth: AuthSessionStore
    @EnvironmentObject private var backend: WanderBackend

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: WanderTheme.spacing4) {
                    header
                    visibilitySection
                    blockedSection
                    groupedRows
                }
                .padding(WanderTheme.spacing4)
                .padding(.bottom, WanderTheme.spacing8)
            }
            .wanderScreen()
        }
    }

    private var header: some View {
        Text("settings")
            .font(.system(size: 30, weight: .black, design: .rounded))
            .lineLimit(1)
    }

    private var visibilitySection: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing3) {
            SettingsSectionTitle("default place visibility")

            HStack(spacing: WanderTheme.spacing2) {
                ForEach(PlaceVisibility.allCases, id: \.rawValue) { visibility in
                    Button {
                        store.defaultVisibility = visibility
                    } label: {
                        WanderChip(title: visibility.displayTitle, isSelected: store.defaultVisibility == visibility)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(store.defaultVisibility.helperCopy)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(WanderTheme.textMuted.color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(WanderTheme.spacing3)
        .background(WanderTheme.surfaceBone.color)
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusLarge))
    }

    private var blockedSection: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing3) {
            SettingsSectionTitle("blocked users")
            let blocked = store.blockedProfiles()
            if blocked.isEmpty {
                Text("No one blocked.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(WanderTheme.textMuted.color)
            } else {
                ForEach(blocked) { profile in
                    HStack {
                        WanderAvatar(initials: String(profile.displayName.prefix(2)).uppercased(), size: 34, color: WanderTheme.stateError.color)
                        VStack(alignment: .leading) {
                            Text(profile.displayName)
                                .font(.system(size: 14, weight: .bold))
                            Text("@\(profile.handle)")
                                .font(.system(size: 12))
                                .foregroundStyle(WanderTheme.textMuted.color)
                        }
                        Spacer()
                        Button("unblock") {
                            auth.requireSignIn(for: .manageBlocks) {
                                Task {
                                    await store.unblock(userID: profile.id, backend: backend)
                                }
                            }
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(WanderTheme.terracotta.color)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(WanderTheme.spacing3)
        .background(WanderTheme.surfaceBone.color)
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusLarge))
    }

    private var groupedRows: some View {
        VStack(spacing: WanderTheme.spacing3) {
            SettingsRow(title: "Profile and account", subtitle: "@\(store.currentUser.handle)", systemImage: "person.crop.circle")
            SettingsRow(title: "Contacts", subtitle: "planned native permission later", systemImage: "person.crop.rectangle.stack")
            SettingsRow(title: "Notifications", subtitle: "after first save", systemImage: "bell")
            SettingsRow(title: "Data and sync", subtitle: "\(store.pendingSyncCount) pending local item\(store.pendingSyncCount == 1 ? "" : "s")", systemImage: "arrow.triangle.2.circlepath") {
                auth.presentGate(for: .syncPending)
            }
        }
    }
}

private struct SettingsSectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.system(size: 15, weight: .black))
    }
}

private struct SettingsRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var action: (() -> Void)?

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: WanderTheme.spacing3) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(WanderTheme.terracotta.color)
                    .frame(width: 38, height: 38)
                    .background(WanderTheme.terracottaTint.color)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: WanderTheme.spacing1) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(WanderTheme.textMuted.color)
                        .lineLimit(1)
                }
                Spacer()
                if action != nil {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(WanderTheme.textFaint.color)
                }
            }
            .frame(minHeight: WanderTheme.tapMinimum)
            .padding(WanderTheme.spacing3)
            .background(WanderTheme.surfaceBone.color)
            .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusLarge))
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}
