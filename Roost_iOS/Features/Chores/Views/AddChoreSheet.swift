import SwiftUI

struct AddChoreSheet: View {
    let myName: String
    let partnerName: String?
    let myUserId: UUID
    let partnerUserId: UUID?
    let suggestedRooms: [String]
    let onAdd: (String, String?, UUID?, String, Date?, String?) async -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var title = ""
    @State private var description = ""
    @State private var assignment = "me"
    @State private var frequency = "once"
    @State private var includeDueDate = true
    @State private var dueDate = Date()
    @State private var room = ""
    @State private var isSaving = false
    @State private var hasAnimatedIn = false

    private let frequencies = [
        ("once", "One-off"),
        ("daily", "Daily"),
        ("weekly", "Weekly"),
        ("monthly", "Monthly")
    ]

    private var canSubmit: Bool {
        !trimmedTitle.isEmpty && !isSaving
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    RoostSheetHeader(
                        title: "Add Chore",
                        subtitle: "Set up the task once so the household can act on it right away."
                    ) {
                        dismiss()
                    }

                    RoostAddSection(
                        title: "Chore",
                        helper: "Write the task the way you want it to appear in the household plan."
                    ) {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            RoostTextField(title: "e.g. Take bins out", text: $title)
                            RoostTextField(title: "Optional description", text: $description)
                        }
                    }
                    .addChoreEntrance(at: 0, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion)

                    RoostAddSection(title: "Assigned to") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 2), spacing: Spacing.sm) {
                            RoostAddChoiceChip(title: myName, isSelected: assignment == "me") {
                                assignment = "me"
                            }

                            if let partnerName {
                                RoostAddChoiceChip(title: partnerName, isSelected: assignment == "partner") {
                                    assignment = "partner"
                                }
                            }

                            RoostAddChoiceChip(title: "Unassigned", isSelected: assignment == "unassigned") {
                                assignment = "unassigned"
                            }
                        }
                    }
                    .addChoreEntrance(at: 1, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion)

                    RoostAddSection(title: "Frequency") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 2), spacing: Spacing.sm) {
                            ForEach(frequencies, id: \.0) { option in
                                RoostAddChoiceChip(title: option.1, isSelected: frequency == option.0) {
                                    frequency = option.0
                                }
                            }
                        }
                    }
                    .addChoreEntrance(at: 2, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion)

                    RoostAddSection(title: "Schedule") {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack(spacing: Spacing.sm) {
                                RoostAddChoiceChip(title: "Due date", isSelected: includeDueDate) {
                                    includeDueDate = true
                                }
                                RoostAddChoiceChip(title: "No date", isSelected: !includeDueDate) {
                                    includeDueDate = false
                                }
                            }

                            if includeDueDate {
                                DatePicker("Due on", selection: $dueDate, displayedComponents: .date)
                                    .font(.roostBody)
                                    .foregroundStyle(Color.roostForeground)
                                    .padding(.horizontal, Spacing.md)
                                    .frame(height: DesignSystem.Size.inputHeight)
                                    .background(Color.roostInput, in: RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                                            .stroke(Color.roostHairline, lineWidth: 1)
                                    )
                                    .tint(.roostPrimary)
                            }
                        }
                    }
                    .addChoreEntrance(at: 3, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion)

                    RoostAddSection(
                        title: "Room",
                        helper: suggestedRooms.isEmpty ? "No rooms have been set up yet." : "Suggested from the rooms already in your home."
                    ) {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            RoostTextField(title: "Optional room", text: $room)

                            if !suggestedRooms.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: Spacing.sm) {
                                        ForEach(suggestedRooms, id: \.self) { suggestedRoom in
                                            RoostAddCapsuleChip(title: suggestedRoom, isSelected: room == suggestedRoom) {
                                                room = suggestedRoom
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .addChoreEntrance(at: 4, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion)

                    RoostAddPreviewCard {
                        HStack(alignment: .top, spacing: Spacing.md) {
                            RoostListControl(
                                state: .idle,
                                tint: .roostPrimary,
                                size: 40
                            )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(trimmedTitle.isEmpty ? "Your chore title" : trimmedTitle)
                                    .font(.roostLabel)
                                    .foregroundStyle(Color.roostForeground)
                                Text(previewAssignment)
                                    .font(.roostMeta)
                                    .foregroundStyle(Color.roostMutedForeground)
                                if let roomValue {
                                    Text(roomValue)
                                        .font(.roostMeta)
                                        .foregroundStyle(Color.roostPrimary)
                                }
                            }

                            Spacer()

                            Text(frequencyLabel)
                                .font(.roostMeta)
                                .foregroundStyle(Color.roostMutedForeground)
                        }
                        .padding(Spacing.md)
                        .background(Color.roostBackground.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous))
                    }
                    .addChoreEntrance(at: 5, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                .padding(.bottom, 120)
            }
            .roostDisableVerticalBounce()
            .roostAddDismissOnPullDown {
                dismiss()
            }
            .background(Color.roostBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                RoostAddBottomBar(
                    actionTitle: "Add chore",
                    isSaving: isSaving,
                    isDisabled: !canSubmit
                ) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Plan")
                            .font(.roostMeta)
                            .foregroundStyle(Color.roostMutedForeground)
                        Text(trimmedTitle.isEmpty ? "Waiting for a chore" : trimmedTitle)
                            .font(.roostLabel)
                            .foregroundStyle(Color.roostForeground)
                            .lineLimit(1)
                    }
                } action: {
                    Task {
                        isSaving = true
                        await onAdd(
                            trimmedTitle,
                            descriptionValue,
                            resolvedAssignedUserId,
                            frequency,
                            includeDueDate ? dueDate : nil,
                            roomValue
                        )
                        isSaving = false
                        dismiss()
                    }
                }
            }
            .task {
                guard !reduceMotion else {
                    hasAnimatedIn = true
                    return
                }
                withAnimation(.roostSmooth) {
                    hasAnimatedIn = true
                }
            }
        }
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var descriptionValue: String? {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var roomValue: String? {
        let trimmed = room.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var resolvedAssignedUserId: UUID? {
        switch assignment {
        case "me":
            return myUserId
        case "partner":
            return partnerUserId
        default:
            return nil
        }
    }

    private var previewAssignment: String {
        switch assignment {
        case "me":
            return "Assigned to \(myName)"
        case "partner":
            return "Assigned to \(partnerName ?? "Partner")"
        default:
            return "Unassigned"
        }
    }

    private var frequencyLabel: String {
        frequencies.first(where: { $0.0 == frequency })?.1 ?? frequency.capitalized
    }
}

private struct AddChoreEntranceModifier: ViewModifier {
    let index: Int
    let hasAnimatedIn: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(hasAnimatedIn ? 1 : 0)
            .offset(y: hasAnimatedIn || reduceMotion ? 0 : 18)
            .animation(
                reduceMotion ? nil : .roostSmooth.delay(Double(index) * 0.05),
                value: hasAnimatedIn
            )
    }
}

private extension View {
    func addChoreEntrance(at index: Int, hasAnimatedIn: Bool, reduceMotion: Bool) -> some View {
        modifier(AddChoreEntranceModifier(index: index, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
    }
}

#Preview("Add Chore") {
    NavigationStack {
        AddChoreSheet(
            myName: "Tom",
            partnerName: "Alex",
            myUserId: UUID(),
            partnerUserId: UUID(),
            suggestedRooms: ["Kitchen", "Bathroom", "Hallway"]
        ) { _, _, _, _, _, _ in }
    }
}
