import SwiftUI

struct DiscoverScreen: View {
    @State private var query = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: WanderTheme.spacing4) {
                Text("Discover")
                    .font(.system(size: 28, weight: .bold))

                TextField("search a place, vibe, or username...", text: $query)
                    .textFieldStyle(.plain)
                    .padding(WanderTheme.spacing4)
                    .background(WanderTheme.surfaceRaised.color)
                    .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusLarge))

                Text("M2 searches contacts, exact/near-exact usernames, and visible profile links. No global people directory.")
                    .font(.body)
                    .foregroundStyle(WanderTheme.textMuted.color)

                HStack {
                    WanderChip(title: "hikes in LA", isSelected: true)
                    WanderChip(title: "coffee")
                    WanderChip(title: "friends")
                }

                Spacer()
            }
            .padding(WanderTheme.spacing6)
            .wanderScreen()
        }
    }
}
