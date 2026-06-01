import SwiftUI

struct AddScreen: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: WanderTheme.spacing4) {
                Text("Add")
                    .font(.system(size: 28, weight: .bold))

                Text("M2 will wire current location and manual entry first. Link and photo stay as unresolved draft shells until backend extraction jobs exist.")
                    .font(.body)
                    .foregroundStyle(WanderTheme.textMuted.color)

                SourceRow(title: "I'm here right now", subtitle: "current location", systemImage: "location.fill")
                SourceRow(title: "Add manually", subtitle: "name, area, note", systemImage: "text.cursor")
                SourceRow(title: "Paste a link", subtitle: "planned extraction shell", systemImage: "link")
                SourceRow(title: "From a photo", subtitle: "planned extraction shell", systemImage: "photo")

                Spacer()
            }
            .padding(WanderTheme.spacing6)
            .wanderScreen()
        }
    }
}

private struct SourceRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: WanderTheme.spacing3) {
            Image(systemName: systemImage)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: WanderTheme.spacing1) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(WanderTheme.textMuted.color)
            }
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
