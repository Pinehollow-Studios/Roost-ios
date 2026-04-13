import SwiftUI

struct AddPinboardNoteSheet: View {
    let currentMemberName: String?
    let partnerName: String?
    let rooms: [Room]
    let onAdd: (String, PinboardTargetScope, Bool, Date?, Room?) async -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var content = ""
    @State private var targetScope: PinboardTargetScope = .everyone
    @State private var notifyOnCreate = true
    @State private var includeExpiry = false
    @State private var expiryDate = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
    @State private var selectedRoomID: UUID?
    @State private var isSaving = false
    @State private var hasAnimatedIn = false

    private var canSubmit: Bool {
        !trimmedContent.isEmpty && !isSaving
    }

    private var selectedRoom: Room? {
        rooms.first(where: { $0.id == selectedRoomID })
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    RoostSheetHeader(
                        title: "Add Note",
                        subtitle: "Pin something for the home without leaving the page style."
                    ) {
                        dismiss()
                    }

                    RoostAddSection(
                        title: "Note",
                        helper: "Pin the message exactly as you want everyone to read it."
                    ) {
                        TextEditor(text: $content)
                            .font(.roostBody)
                            .foregroundStyle(Color.roostForeground)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .frame(minHeight: 150)
                            .background(Color.roostInput, in: RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                                    .stroke(Color.roostHairline, lineWidth: 1)
                            )
                    }
                    .addPinboardEntrance(at: 0, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion)

                    RoostAddSection(title: "Audience") {
                        HStack(spacing: Spacing.sm) {
                            RoostAddChoiceChip(title: "Everyone", isSelected: targetScope == .everyone) {
                                targetScope = .everyone
                            }
                            RoostAddChoiceChip(title: "Me", isSelected: targetScope == .self) {
                                targetScope = .self
                            }
                            if partnerName != nil {
                                RoostAddChoiceChip(title: partnerName ?? "Partner", isSelected: targetScope == .partner) {
                                    targetScope = .partner
                                }
                            }
                        }
                    }
                    .addPinboardEntrance(at: 1, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion)

                    RoostAddSection(
                        title: "Link to a room",
                        helper: rooms.isEmpty ? "No rooms are available yet." : "Optional. Choose a room already in your home."
                    ) {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            if !rooms.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: Spacing.sm) {
                                        RoostAddCapsuleChip(title: "None", isSelected: selectedRoomID == nil) {
                                            selectedRoomID = nil
                                        }

                                        ForEach(rooms) { room in
                                            RoostAddCapsuleChip(title: room.name, isSelected: selectedRoomID == room.id) {
                                                selectedRoomID = room.id
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .addPinboardEntrance(at: 2, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion)

                    RoostAddSection(title: "Options") {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            HStack(spacing: Spacing.sm) {
                                RoostAddChoiceChip(title: "Notify", isSelected: notifyOnCreate) {
                                    notifyOnCreate = true
                                }
                                RoostAddChoiceChip(title: "Silent", isSelected: !notifyOnCreate) {
                                    notifyOnCreate = false
                                }
                            }

                            HStack(spacing: Spacing.sm) {
                                RoostAddChoiceChip(title: "Permanent", isSelected: !includeExpiry) {
                                    includeExpiry = false
                                }
                                RoostAddChoiceChip(title: "Set expiry", isSelected: includeExpiry) {
                                    includeExpiry = true
                                }
                            }

                            if includeExpiry {
                                DatePicker("Expires", selection: $expiryDate, in: Date()..., displayedComponents: .date)
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
                    .addPinboardEntrance(at: 3, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion)

                    RoostAddPreviewCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack(spacing: Spacing.sm) {
                                FigmaChip(title: audienceLabel, variant: .default, systemImage: targetScope == .everyone ? "person.2" : "person")
                                if let room = selectedRoom {
                                    FigmaChip(title: room.name, variant: .secondary, systemImage: "link")
                                }
                                if includeExpiry {
                                    FigmaChip(title: expiryLabel, variant: .warning, systemImage: "clock")
                                }
                            }

                            Text(trimmedContent.isEmpty ? "Your note preview appears here." : trimmedContent)
                                .font(.roostBody)
                                .foregroundStyle(Color.roostForeground)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(Spacing.md)
                        .background(Color.roostBackground.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous))
                    }
                    .addPinboardEntrance(at: 4, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion)
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
                    actionTitle: "Add note",
                    isSaving: isSaving,
                    isDisabled: !canSubmit
                ) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pinboard")
                            .font(.roostMeta)
                            .foregroundStyle(Color.roostMutedForeground)
                        Text(audienceLabel)
                            .font(.roostLabel)
                            .foregroundStyle(Color.roostForeground)
                            .lineLimit(1)
                    }
                } action: {
                    Task {
                        isSaving = true
                        await onAdd(
                            trimmedContent,
                            targetScope,
                            notifyOnCreate,
                            includeExpiry ? expiryDate : nil,
                            selectedRoom
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

    private var trimmedContent: String {
        content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var audienceLabel: String {
        switch targetScope {
        case .everyone:
            return "For everyone"
        case .self:
            return currentMemberName.map { "For \($0)" } ?? "For me"
        case .partner:
            return partnerName.map { "For \($0)" } ?? "For partner"
        }
    }

    private var expiryLabel: String {
        "Expires \(expiryDate.formatted(.dateTime.day().month(.abbreviated)))"
    }
}

private struct AddPinboardEntranceModifier: ViewModifier {
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
    func addPinboardEntrance(at index: Int, hasAnimatedIn: Bool, reduceMotion: Bool) -> some View {
        modifier(AddPinboardEntranceModifier(index: index, hasAnimatedIn: hasAnimatedIn, reduceMotion: reduceMotion))
    }
}

#Preview("Add Pinboard Note") {
    NavigationStack {
        AddPinboardNoteSheet(
            currentMemberName: "Tom",
            partnerName: "Alex",
            rooms: [
                Room(id: UUID(), homeID: UUID(), name: "Kitchen", icon: nil),
                Room(id: UUID(), homeID: UUID(), name: "Bathroom", icon: nil)
            ]
        ) { _, _, _, _, _ in }
    }
}
