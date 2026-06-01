import SwiftUI

struct AddScreen: View {
    @EnvironmentObject private var store: InMemoryWanderStore
    @State private var selectedPlaceID = WanderFixtures.seed.places.first?.id ?? ""
    @State private var visibility: PlaceVisibility = .followers
    @State private var status: PlaceStatus = .been
    @State private var note = ""
    @State private var vibeAnswer = "good table"
    @State private var nearbyConfirmed = true
    @State private var didSave = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Add a place")
                    .font(.largeTitle.weight(.bold))

                VStack(alignment: .leading, spacing: 10) {
                    Text("What spot?")
                        .font(.headline)
                    ForEach(store.places) { place in
                        PlacePickRow(place: place, isSelected: selectedPlaceID == place.id)
                            .onTapGesture {
                                selectedPlaceID = place.id
                                didSave = false
                            }
                    }
                }

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

                categoryQuestions

                TextField("Add a note for future you", text: $note, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(3, reservesSpace: true)
                    .padding(16)
                    .background(WanderTheme.sand.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: WanderTheme.cornerRadius))

                Button {
                    Task { await saveSeedPlace() }
                } label: {
                    Text(didSave ? "Saved on this phone" : "Save place")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(WanderTheme.terracotta)
                        .foregroundStyle(WanderTheme.cream)
                        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.cornerRadius))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .wanderScreen()
    }

    @ViewBuilder
    private var categoryQuestions: some View {
        let place = store.place(for: selectedPlaceID)
        VStack(alignment: .leading, spacing: 12) {
            Text(promptTitle(for: place?.category))
                .font(.headline)
            HStack {
                ForEach(promptOptions(for: place?.category), id: \.self) { option in
                    WanderChip(title: option, isSelected: vibeAnswer == option)
                        .onTapGesture { vibeAnswer = option }
                }
            }
            Toggle("I was actually nearby", isOn: $nearbyConfirmed)
                .toggleStyle(.switch)
                .tint(WanderTheme.sage)
        }
    }

    private func promptTitle(for category: String?) -> String {
        switch category {
        case "coffee": "What was the coffee vibe?"
        case "hike": "How spicy was the hike?"
        case "restaurant": "What is it good for?"
        default: "What should you remember?"
        }
    }

    private func promptOptions(for category: String?) -> [String] {
        switch category {
        case "coffee": ["good table", "wifi", "quick cup"]
        case "hike": ["easy", "sweaty", "views"]
        case "restaurant": ["date", "group", "solo"]
        default: ["keeper", "maybe", "skip"]
        }
    }

    private func saveSeedPlace() async {
        guard let place = store.place(for: selectedPlaceID) else { return }
        let userPlace = LocalUserPlace(
            id: "up_\(store.currentUser.id)_\(place.id)_local",
            userID: store.currentUser.id,
            placeID: place.id,
            status: status,
            visibility: visibility,
            note: note.isEmpty ? vibeAnswer : "\(vibeAnswer). \(note)",
            nearbyConfirmed: nearbyConfirmed,
            sourceType: "manual_m2",
            syncState: .pendingCreate
        )
        try? await store.save(userPlace)
        didSave = true
    }
}

private struct PlacePickRow: View {
    let place: LocalPlace
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(place.canonicalName)
                    .font(.headline)
                Text(place.category)
                    .font(.subheadline)
                    .foregroundStyle(WanderTheme.espresso.opacity(0.7))
            }
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? WanderTheme.terracotta : WanderTheme.espresso.opacity(0.35))
        }
        .padding(16)
        .background(isSelected ? WanderTheme.mustard.opacity(0.25) : WanderTheme.sand.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.cornerRadius))
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
