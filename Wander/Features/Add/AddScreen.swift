import SwiftUI

struct AddScreen: View {
    let fixtures: WanderFixtures
    @State private var visibility: PlaceVisibility = .followers
    @State private var status: PlaceStatus = .been

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add a place")
                .font(.largeTitle.weight(.bold))

            HStack {
                WanderChip(title: "Been", isSelected: status == .been)
                    .onTapGesture { status = .been }
                WanderChip(title: "Wanna go", isSelected: status == .wannaGo)
                    .onTapGesture { status = .wannaGo }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Who can see it?")
                    .font(.headline)
                HStack {
                    WanderChip(title: "Everyone", isSelected: visibility == .followers)
                        .onTapGesture { visibility = .followers }
                    WanderChip(title: "Friends", isSelected: visibility == .mutuals)
                        .onTapGesture { visibility = .mutuals }
                    WanderChip(title: "Self", isSelected: visibility == .selfOnly)
                        .onTapGesture { visibility = .selfOnly }
                }
                Text("Everyone means people who follow you.")
                    .font(.footnote)
                    .foregroundStyle(WanderTheme.espresso.opacity(0.7))
            }

            VStack(spacing: 12) {
                AddModeButton(title: "Use current location", systemImage: "location.fill")
                AddModeButton(title: "Paste a link", systemImage: "link")
                AddModeButton(title: "Add manually", systemImage: "text.cursor")
                AddModeButton(title: "Use a photo", systemImage: "photo")
            }

            Spacer()
        }
        .padding(20)
        .wanderScreen()
    }
}

private struct AddModeButton: View {
    let title: String
    let systemImage: String

    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: systemImage)
                Text(title)
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding(16)
            .background(WanderTheme.sand.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: WanderTheme.cornerRadius))
        }
        .buttonStyle(.plain)
    }
}
