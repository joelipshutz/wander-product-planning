import SwiftUI

struct MapScreen: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: WanderTheme.spacing4) {
                Text("Map")
                    .font(.system(size: 28, weight: .bold))

                Text("Seeded MapKit pins land here in M2. This shell exists only to prove the audited tab contract.")
                    .font(.body)
                    .foregroundStyle(WanderTheme.textMuted.color)

                HStack {
                    WanderChip(title: "you", isSelected: true)
                    WanderChip(title: "social")
                    WanderChip(title: "been")
                    WanderChip(title: "wanna")
                }

                Spacer()
            }
            .padding(WanderTheme.spacing6)
            .wanderScreen()
        }
    }
}
