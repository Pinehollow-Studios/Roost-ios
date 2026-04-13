import SwiftUI

struct ChoreRow: View {
    @Environment(SettingsViewModel.self) private var settingsViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let chore: Chore
    let assignedMember: HomeMember?
    let assignedName: String?
    let lastCompletedText: String?
    let streak: Int
    let onToggle: () -> Void
    @State private var checkScale: CGFloat = 1
    @State private var ringScale: CGFloat = 1
    @State private var ringOpacity: Double = 0

    var body: some View {
        Button(action: onToggle) {
            RoostSectionSurface(emphasis: .subtle) {
                HStack(alignment: .top, spacing: DesignSystem.Spacing.row) {
                    checkbox

                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.row) {
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.inline) {
                            Text(chore.title)
                                .font(.roostBody.weight(.medium))
                                .foregroundStyle(chore.isCompleted ? Color.roostMutedForeground : Color.roostForeground)
                                .strikethrough(chore.isCompleted)
                                .fixedSize(horizontal: false, vertical: true)
                                .animation(reduceMotion ? nil : .roostEaseOut, value: chore.isCompleted)

                            Spacer(minLength: DesignSystem.Spacing.inline)

                            if streak >= 2, !chore.isCompleted {
                                FigmaChip(title: "\(streak) \(streakUnit)", variant: .warning, systemImage: "flame.fill")
                            }
                        }

                        HStack(alignment: .center, spacing: DesignSystem.Spacing.inline) {
                            MemberAvatar(member: assignedMember, fallbackLabel: assignedName ?? "?", size: .sm)

                            Text(assignedName ?? "Needs someone")
                                .font(.roostLabel)
                                .foregroundStyle(Color.roostMutedForeground)

                            if let room = chore.room, !room.isEmpty {
                                Text("·")
                                    .font(.roostLabel)
                                    .foregroundStyle(Color.roostMutedForeground)

                                Text(room)
                                    .font(.roostLabel)
                                    .foregroundStyle(Color.roostMutedForeground)
                            }
                        }

                        HStack(alignment: .center, spacing: DesignSystem.Spacing.inline) {
                            if let dueDate = chore.dueDate {
                                FigmaChip(
                                    title: dueDateLabel(for: dueDate),
                                    variant: chore.isOverdue ? .destructive : .default,
                                    systemImage: "clock"
                                )
                            }

                            if let frequency = frequencyLabel {
                                FigmaChip(title: frequency)
                            }
                        }

                        if let lastCompletedText {
                            Text(lastCompletedText)
                                .font(.roostCaption)
                                .foregroundStyle(Color.roostMutedForeground)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onChange(of: chore.isCompleted) { _, newValue in
            guard newValue, !reduceMotion else { return }
            // Spring bounce on the checkmark
            withAnimation(DesignSystem.Motion.checkmark) {
                checkScale = 1.22
                ringOpacity = 1
                ringScale = 1
            }
            Task {
                try? await Task.sleep(for: .milliseconds(140))
                withAnimation(DesignSystem.Motion.checkmark) {
                    checkScale = 1
                }
                withAnimation(.easeOut(duration: 0.3)) {
                    ringOpacity = 0
                    ringScale = 1.5
                }
            }
        }
    }

    private var checkbox: some View {
        ZStack {
            // Ripple ring — expands and fades on completion
            Circle()
                .strokeBorder(Color.roostPrimary.opacity(0.3), lineWidth: 1.5)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)

            // Fill circle
            Circle()
                .fill(chore.isCompleted ? Color.roostPrimary : Color.clear)
                .animation(DesignSystem.Motion.checkmark, value: chore.isCompleted)

            // Border ring (fades out when filled)
            Circle()
                .strokeBorder(
                    chore.isCompleted ? Color.roostPrimary : Color.roostHairline,
                    lineWidth: 2
                )
                .animation(DesignSystem.Motion.checkmark, value: chore.isCompleted)

            // Checkmark
            if chore.isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.roostCard)
                    .scaleEffect(checkScale)
                    .transition(
                        .scale(scale: 0.3, anchor: .center)
                        .combined(with: .opacity)
                    )
            }
        }
        .frame(width: 24, height: 24)
        .padding(.top, 2)
    }

    private var frequencyLabel: String? {
        guard let frequency = chore.frequency, frequency != "once" else { return nil }
        return frequency.capitalized
    }

    private var streakUnit: String {
        switch chore.frequency {
        case "daily":   return streak == 1 ? "day"   : "days"
        case "monthly": return streak == 1 ? "month" : "months"
        default:        return streak == 1 ? "week"  : "weeks"
        }
    }

    private func dueDateLabel(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        }
        return settingsViewModel.formattedDate(date)
    }
}
