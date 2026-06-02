import SwiftUI

struct AddScreen: View {
    @EnvironmentObject private var store: WanderStore
    @State private var step: AddStep = .source
    @State private var candidates: [PlaceCandidate] = []
    @State private var selectedCandidateID: String?
    @State private var selectedStatus: PlaceStatus = .been
    @State private var selectedVisibility: PlaceVisibility = .followers
    @State private var selectedSource: AddSourceType = .manual
    @State private var note = ""
    @State private var manualName = ""
    @State private var manualArea = ""
    @State private var manualCategory = "coffee"
    @State private var linkInput = ""
    @State private var selectedAnswers: [String: Set<String>] = [:]
    @State private var savedResult: SaveResult?
    @State private var draft: UnresolvedDraft?

    private var selectedCandidate: PlaceCandidate? {
        candidates.first { $0.id == selectedCandidateID } ?? candidates.first
    }

    private var currentQuestionBlocks: [AddQuestionBlock] {
        AddQuestionTemplates.blocks(
            category: selectedCandidate?.category ?? manualCategory,
            status: selectedStatus
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: WanderTheme.spacing4) {
                    header

                    switch step {
                    case .source:
                        sourcePicker
                    case .manual:
                        manualForm
                    case .confirm:
                        confirmPlace
                    case .details:
                        detailsForm
                    case .saved:
                        savedView
                    case .draft:
                        draftView
                    }
                }
                .padding(WanderTheme.spacing4)
                .padding(.bottom, WanderTheme.spacing8)
            }
            .scrollDismissesKeyboard(.interactively)
            .wanderScreen()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing2) {
            Text(step.kicker)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(WanderTheme.textMuted.color)
            Text(step.title)
                .font(.system(size: 28, weight: .black))
            Text(step.subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(WanderTheme.textMuted.color)
        }
    }

    private var sourcePicker: some View {
        VStack(spacing: WanderTheme.spacing2) {
            SourceRow(title: AddSourceType.currentLocation.title, subtitle: "use nearby places · not live location", systemImage: "location.fill", isPrimary: true) {
                selectedSource = .currentLocation
                candidates = store.currentLocationCandidates()
                selectedCandidateID = candidates.first?.id
                selectedVisibility = store.defaultVisibility
                step = .confirm
            }
            SourceRow(title: AddSourceType.link.title, subtitle: "saved as unresolved until backend extraction", systemImage: "link") {
                draft = store.createUnresolvedDraft(sourceType: .link, originalInput: linkInput)
                step = .draft
            }
            SourceRow(title: AddSourceType.manual.title, subtitle: "name, area, a note", systemImage: "square.and.pencil") {
                selectedSource = .manual
                step = .manual
            }
            SourceRow(title: AddSourceType.photo.title, subtitle: "draft shell for the extraction job lane", systemImage: "photo") {
                draft = store.createUnresolvedDraft(sourceType: .photo)
                step = .draft
            }

            Text("location is used to find nearby places · not to broadcast you")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(WanderTheme.textMuted.color)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, WanderTheme.spacing2)
        }
    }

    private var manualForm: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing3) {
            LabeledField(label: "place name", placeholder: "Maru Coffee", text: $manualName)
            LabeledField(label: "area", placeholder: "arts district", text: $manualArea)

            VStack(alignment: .leading, spacing: WanderTheme.spacing2) {
                Text("category")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(WanderTheme.textMuted.color)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(["coffee", "restaurant", "hike", "bar", "park"], id: \.self) { category in
                            Button {
                                manualCategory = category
                            } label: {
                                WanderChip(title: category, isSelected: manualCategory == category)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            WanderPrimaryButton(title: "find candidates", systemImage: "magnifyingglass", isDisabled: manualName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                candidates = store.manualCandidates(name: manualName, areaHint: manualArea, category: manualCategory)
                selectedCandidateID = candidates.first?.id
                selectedVisibility = store.defaultVisibility
                step = candidates.isEmpty ? .draft : .confirm
            }
        }
    }

    private var confirmPlace: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing4) {
            VStack(spacing: WanderTheme.spacing2) {
                ForEach(candidates) { candidate in
                    CandidateRow(candidate: candidate, isSelected: selectedCandidate?.id == candidate.id) {
                        selectedCandidateID = candidate.id
                    }
                }
            }

            PickerBlock(title: "I've...") {
                HStack(spacing: WanderTheme.spacing2) {
                    ChoicePill(title: "been", isSelected: selectedStatus == .been) { selectedStatus = .been }
                    ChoicePill(title: "wanna go", isSelected: selectedStatus == .wannaGo) { selectedStatus = .wannaGo }
                }
            }

            PickerBlock(title: "who can see this") {
                VStack(alignment: .leading, spacing: WanderTheme.spacing2) {
                    HStack(spacing: WanderTheme.spacing2) {
                        ForEach(PlaceVisibility.allCases, id: \.rawValue) { visibility in
                            ChoicePill(title: visibility.displayTitle, isSelected: selectedVisibility == visibility) {
                                selectedVisibility = visibility
                            }
                        }
                    }
                    Text(selectedVisibility.helperCopy)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(WanderTheme.textMuted.color)
                }
            }

            WanderPrimaryButton(title: "continue to details", systemImage: "arrow.right") {
                prepareDetails()
            }
        }
    }

    private var detailsForm: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing3) {
            if let selectedCandidate {
                HStack {
                    CategoryIcon(category: selectedCandidate.category)
                    VStack(alignment: .leading) {
                        Text(selectedCandidate.name)
                            .font(.system(size: 18, weight: .bold))
                        Text("\(selectedStatus.displayTitle) · \(selectedVisibility.displayTitle)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(WanderTheme.textMuted.color)
                    }
                    Spacer()
                }
                .padding(WanderTheme.spacing3)
                .background(WanderTheme.surfaceBone.color)
                .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusMedium))
            }

            ForEach(currentQuestionBlocks) { block in
                QuestionBlock(title: block.title, tag: block.tag) {
                    SelectableQuestionOptions(
                        block: block,
                        selectedValues: selectedAnswers[block.key] ?? Set(block.defaultValues)
                    ) { option in
                        toggleAnswer(option, in: block)
                    }
                }
            }

            VStack(alignment: .leading, spacing: WanderTheme.spacing2) {
                Text("a note for future you")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(WanderTheme.textMuted.color)
                TextField("best table, what to order, who told you...", text: $note, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(3, reservesSpace: true)
                    .padding(WanderTheme.spacing3)
                    .background(WanderTheme.surfaceRaised.color)
                    .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusLarge))
            }

            WanderPrimaryButton(title: "save to my map", systemImage: "checkmark") {
                guard let selectedCandidate else { return }
                savedResult = store.saveCandidate(
                    selectedCandidate,
                    status: selectedStatus,
                    visibility: selectedVisibility,
                    note: note.isEmpty ? nil : note,
                    sourceType: selectedSource,
                    attributes: attributeDrafts()
                )
                step = .saved
            }
        }
    }

    private var savedView: some View {
        VStack(spacing: WanderTheme.spacing4) {
            Image(systemName: selectedStatus == .been ? "mappin.circle.fill" : "mappin.circle")
                .font(.system(size: 64, weight: .black))
                .foregroundStyle(WanderTheme.terracotta.color)
                .accessibilityHidden(true)

            VStack(spacing: WanderTheme.spacing2) {
                Text("it's on your map")
                    .font(.system(size: 26, weight: .black))
                Text("saved as \(selectedStatus.displayTitle), visible to \(selectedVisibility.displayTitle.lowercased()).")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(WanderTheme.textMuted.color)
                    .multilineTextAlignment(.center)
            }

            if let savedResult {
                Text(savedResult.syncState == .pendingCreate ? "sync queued" : "saved")
                    .font(.system(size: 13, weight: .bold))
                    .padding(.horizontal, WanderTheme.spacing3)
                    .padding(.vertical, WanderTheme.spacing2)
                    .background(WanderTheme.surfaceSand.color)
                    .clipShape(Capsule())
            }

            WanderPrimaryButton(title: "add another place", systemImage: "plus") {
                reset()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, WanderTheme.spacing8)
    }

    private var draftView: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing4) {
            Image(systemName: "tray.and.arrow.down.fill")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(WanderTheme.terracotta.color)

            Text(draft?.title ?? "Draft saved.")
                .font(.system(size: 22, weight: .bold))
            Text(draft?.message ?? "You can finish this manually.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(WanderTheme.textMuted.color)

            WanderPrimaryButton(title: "add manually instead", systemImage: "square.and.pencil") {
                step = .manual
            }
        }
        .padding(WanderTheme.spacing4)
        .background(WanderTheme.surfaceBone.color)
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusLarge))
    }

    private func reset() {
        step = .source
        candidates = []
        selectedCandidateID = nil
        selectedStatus = .been
        selectedVisibility = store.defaultVisibility
        selectedSource = .manual
        note = ""
        manualName = ""
        manualArea = ""
        manualCategory = "coffee"
        selectedAnswers = [:]
        savedResult = nil
        draft = nil
    }

    private func prepareDetails() {
        let blocks = currentQuestionBlocks
        let allowedKeys = Set(blocks.map(\.key))
        var nextAnswers = selectedAnswers.filter { allowedKeys.contains($0.key) }

        for block in blocks where nextAnswers[block.key] == nil {
            nextAnswers[block.key] = Set(block.defaultValues)
        }

        selectedAnswers = nextAnswers
        step = .details
    }

    private func toggleAnswer(_ option: String, in block: AddQuestionBlock) {
        var values = selectedAnswers[block.key] ?? Set(block.defaultValues)

        switch block.kind {
        case .singleChoice:
            values = [option]
        case .multiTag:
            if values.contains(option) {
                values.remove(option)
            } else {
                values.insert(option)
            }
        }

        selectedAnswers[block.key] = values
    }

    private func attributeDrafts() -> [PlaceAttributeDraft] {
        currentQuestionBlocks.compactMap { block in
            let values = orderedSelections(for: block)
            guard !values.isEmpty else { return nil }

            switch block.kind {
            case .singleChoice:
                return PlaceAttributeDraft(questionKey: block.key, valueType: block.valueType, stringValue: values[0])
            case .multiTag:
                return PlaceAttributeDraft(questionKey: block.key, valueType: block.valueType, stringValues: values)
            }
        }
    }

    private func orderedSelections(for block: AddQuestionBlock) -> [String] {
        let values = selectedAnswers[block.key] ?? Set(block.defaultValues)
        return block.options.filter { values.contains($0) }
    }
}

private enum AddStep {
    case source
    case manual
    case confirm
    case details
    case saved
    case draft

    var kicker: String {
        switch self {
        case .source, .manual: "ADD A PLACE"
        case .confirm: "STEP 1 OF 2"
        case .details: "STEP 2 OF 2"
        case .saved: "SAVED"
        case .draft: "DRAFT"
        }
    }

    var title: String {
        switch self {
        case .source: "where's it from?"
        case .manual: "what's the place?"
        case .confirm: "is this the one?"
        case .details: "a few quick details"
        case .saved: "nice, saved"
        case .draft: "needs a little help"
        }
    }

    var subtitle: String {
        switch self {
        case .source: "pick a source - we'll fill in what we can."
        case .manual: "name and area are enough to start."
        case .confirm: "pick the place, status, and who can see it."
        case .details: "optional taps for future you."
        case .saved: "it is ready on your map."
        case .draft: "we kept the input without pretending extraction works."
        }
    }
}

private enum AddQuestionKind: Equatable {
    case singleChoice
    case multiTag
}

private struct AddQuestionBlock: Identifiable, Equatable {
    let key: String
    let title: String
    let tag: String
    let kind: AddQuestionKind
    let valueType: String
    let options: [String]
    let defaultValues: [String]
    var minimumOptionWidth: CGFloat = 82

    var id: String { key }
}

private enum AddQuestionTemplates {
    static func blocks(category: String, status: PlaceStatus) -> [AddQuestionBlock] {
        let normalizedCategory = category.lowercased()
        var blocks = [ratingBlock(status: status)]

        switch normalizedCategory {
        case "coffee":
            blocks.append(contentsOf: coffeeBlocks)
        case "hike":
            blocks.append(contentsOf: hikeBlocks)
        case "restaurant":
            blocks.append(contentsOf: restaurantBlocks)
        case "bar":
            blocks.append(contentsOf: barBlocks)
        case "park":
            blocks.append(contentsOf: parkBlocks)
        default:
            blocks.append(contentsOf: defaultBlocks(category: normalizedCategory))
        }

        return blocks
    }

    private static func ratingBlock(status: PlaceStatus) -> AddQuestionBlock {
        if status == .wannaGo {
            return AddQuestionBlock(
                key: "rating_signal",
                title: "how excited are you?",
                tag: "scale",
                kind: .singleChoice,
                valueType: "emoji_scale",
                options: ["curious", "excited", "must go"],
                defaultValues: ["excited"],
                minimumOptionWidth: 88
            )
        }

        return AddQuestionBlock(
            key: "rating_signal",
            title: "how much did you like it?",
            tag: "scale",
            kind: .singleChoice,
            valueType: "emoji_scale",
            options: ["meh", "fine", "good", "great"],
            defaultValues: ["great"]
        )
    }

    private static let coffeeBlocks = [
        AddQuestionBlock(
            key: "work_setup",
            title: "good for working?",
            tag: "yes/no",
            kind: .singleChoice,
            valueType: "single_choice",
            options: ["yes", "sometimes", "nope"],
            defaultValues: ["yes"],
            minimumOptionWidth: 96
        ),
        AddQuestionBlock(
            key: "coffee_tags",
            title: "tags",
            tag: "multi",
            kind: .multiTag,
            valueType: "multi_tag",
            options: ["wifi solid", "outlets", "quiet", "cute", "food on point"],
            defaultValues: ["wifi solid", "quiet"],
            minimumOptionWidth: 102
        )
    ]

    private static let hikeBlocks = [
        AddQuestionBlock(
            key: "strenuousness",
            title: "how strenuous?",
            tag: "scale",
            kind: .singleChoice,
            valueType: "single_choice",
            options: ["easy", "moderate", "hard"],
            defaultValues: ["easy"],
            minimumOptionWidth: 94
        ),
        AddQuestionBlock(
            key: "hike_tags",
            title: "tags",
            tag: "multi",
            kind: .multiTag,
            valueType: "multi_tag",
            options: ["sunset", "views", "shade", "dog friendly", "crowded"],
            defaultValues: ["sunset", "views"],
            minimumOptionWidth: 98
        )
    ]

    private static let restaurantBlocks = [
        AddQuestionBlock(
            key: "price",
            title: "price feel?",
            tag: "price",
            kind: .singleChoice,
            valueType: "price_scale",
            options: ["$", "$$", "$$$"],
            defaultValues: ["$$"],
            minimumOptionWidth: 64
        ),
        AddQuestionBlock(
            key: "occasion",
            title: "best for?",
            tag: "occasion",
            kind: .singleChoice,
            valueType: "single_choice",
            options: ["quick bite", "date night", "group", "rainy night"],
            defaultValues: ["rainy night"],
            minimumOptionWidth: 104
        ),
        AddQuestionBlock(
            key: "restaurant_tags",
            title: "tags",
            tag: "multi",
            kind: .multiTag,
            valueType: "multi_tag",
            options: ["cozy", "good table", "share plates", "worth it"],
            defaultValues: ["cozy", "worth it"],
            minimumOptionWidth: 104
        )
    ]

    private static let barBlocks = [
        AddQuestionBlock(
            key: "occasion",
            title: "best for?",
            tag: "occasion",
            kind: .singleChoice,
            valueType: "single_choice",
            options: ["first drink", "date", "group", "late"],
            defaultValues: ["first drink"],
            minimumOptionWidth: 98
        ),
        AddQuestionBlock(
            key: "bar_tags",
            title: "tags",
            tag: "multi",
            kind: .multiTag,
            valueType: "multi_tag",
            options: ["patio", "good music", "not too loud", "walk-in"],
            defaultValues: ["patio"],
            minimumOptionWidth: 104
        )
    ]

    private static let parkBlocks = [
        AddQuestionBlock(
            key: "best_for",
            title: "best for?",
            tag: "occasion",
            kind: .singleChoice,
            valueType: "single_choice",
            options: ["walk", "picnic", "views", "reset"],
            defaultValues: ["walk"],
            minimumOptionWidth: 84
        ),
        AddQuestionBlock(
            key: "park_tags",
            title: "tags",
            tag: "multi",
            kind: .multiTag,
            valueType: "multi_tag",
            options: ["shade", "sunny", "quiet", "dog friendly"],
            defaultValues: ["quiet"],
            minimumOptionWidth: 96
        )
    ]

    private static func defaultBlocks(category: String) -> [AddQuestionBlock] {
        [
            AddQuestionBlock(
                key: "\(category.isEmpty ? "place" : category)_tags",
                title: "tags",
                tag: "multi",
                kind: .multiTag,
                valueType: "multi_tag",
                options: ["worth it", "easy", "cozy", "bring friends"],
                defaultValues: ["worth it"],
                minimumOptionWidth: 104
            )
        ]
    }
}

private struct SourceRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var isPrimary = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: WanderTheme.spacing3) {
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .bold))
                    .frame(width: 40, height: 40)
                    .background(isPrimary ? WanderTheme.terracottaDark.color.opacity(0.18) : WanderTheme.surfaceSand.color)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: WanderTheme.spacing1) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(isPrimary ? WanderTheme.textOnAction.color.opacity(0.82) : WanderTheme.textMuted.color)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(isPrimary ? WanderTheme.textOnAction.color : WanderTheme.textFaint.color)
            }
            .foregroundStyle(isPrimary ? WanderTheme.textOnAction.color : WanderTheme.textInk.color)
            .frame(minHeight: 62)
            .padding(WanderTheme.spacing3)
            .background(isPrimary ? WanderTheme.terracotta.color : WanderTheme.surfaceBone.color)
            .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusLarge))
        }
        .buttonStyle(.plain)
    }
}

private struct CandidateRow: View {
    let candidate: PlaceCandidate
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: WanderTheme.spacing3) {
                CategoryIcon(category: candidate.category)
                VStack(alignment: .leading, spacing: WanderTheme.spacing1) {
                    Text(candidate.name)
                        .font(.system(size: 16, weight: .bold))
                    Text("\(candidate.category) · confidence \(Int(candidate.confidence * 100))%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(WanderTheme.textMuted.color)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? WanderTheme.terracotta.color : WanderTheme.borderStrong.color)
            }
            .padding(WanderTheme.spacing3)
            .background(WanderTheme.surfaceBone.color)
            .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: WanderTheme.radiusLarge)
                    .stroke(isSelected ? WanderTheme.terracotta.color : WanderTheme.borderHairline.color, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct LabeledField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing2) {
            Text(label)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(WanderTheme.textMuted.color)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .padding(WanderTheme.spacing3)
                .background(WanderTheme.surfaceRaised.color)
                .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusMedium))
        }
    }
}

private struct PickerBlock<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing2) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(WanderTheme.textMuted.color)
            content
        }
    }
}

private struct ChoicePill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .frame(minHeight: WanderTheme.tapMinimum)
                .padding(.horizontal, WanderTheme.spacing3)
                .background(isSelected ? WanderTheme.textInk.color : WanderTheme.surfaceRaised.color)
                .foregroundStyle(isSelected ? WanderTheme.textOnAction.color : WanderTheme.textInk.color)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(WanderTheme.borderHairline.color))
        }
        .buttonStyle(.plain)
    }
}

private struct QuestionBlock<Content: View>: View {
    let title: String
    let tag: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: WanderTheme.spacing2) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Text(tag)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(WanderTheme.textMuted.color)
            }
            content
        }
        .padding(WanderTheme.spacing3)
        .background(WanderTheme.surfaceBone.color)
        .clipShape(RoundedRectangle(cornerRadius: WanderTheme.radiusLarge))
    }
}

private struct SelectableQuestionOptions: View {
    let block: AddQuestionBlock
    let selectedValues: Set<String>
    let onSelect: (String) -> Void

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: block.minimumOptionWidth), spacing: WanderTheme.spacing2)],
            alignment: .leading,
            spacing: WanderTheme.spacing2
        ) {
            ForEach(block.options, id: \.self) { option in
                Button {
                    onSelect(option)
                } label: {
                    WanderChip(title: option, isSelected: selectedValues.contains(option))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct CategoryIcon: View {
    let category: String

    var body: some View {
        Image(systemName: imageName)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(WanderTheme.terracotta.color)
            .frame(width: 40, height: 40)
            .background(WanderTheme.terracottaTint.color)
            .clipShape(Circle())
    }

    private var imageName: String {
        switch category {
        case "coffee": "cup.and.saucer.fill"
        case "hike": "figure.hiking"
        case "restaurant": "fork.knife"
        case "bar": "wineglass.fill"
        default: "mappin"
        }
    }
}
