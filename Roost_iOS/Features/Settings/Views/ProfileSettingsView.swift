import SwiftUI

struct ProfileSettingsView: View {
    @Environment(HomeManager.self) private var homeManager
    @Environment(SettingsViewModel.self) private var settingsViewModel

    @State private var displayName = ""
    @State private var selectedColor = AvatarColorOption.all.first?.key ?? "#7F77DD"
    @State private var selectedIcon: String?
    @State private var isSaving = false
    @State private var hasHydratedProfile = false
    @State private var autoSaveTask: Task<Void, Never>?

    private let colorColumns = Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.inline), count: 5)
    private let iconColumns = Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.inline), count: 5)
    private var profileSyncKey: String {
        guard let member = homeManager.currentMember else { return "nil" }
        return [
            member.id.uuidString,
            member.displayName,
            member.avatarColor ?? "",
            member.avatarIcon ?? "",
        ].joined(separator: "|")
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sectionLarge) {
                header

                displayNameCard

                avatarPreviewCard

                avatarColorCard

                avatarIconCard
            }
            .padding(.horizontal, DesignSystem.Spacing.page)
            .padding(.bottom, 108)
            .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .swipeBackEnabled()
        .task(id: profileSyncKey) {
            if let member = homeManager.currentMember {
                displayName = member.displayName
                selectedColor = member.avatarColor ?? selectedColor
                selectedIcon = member.avatarIcon
                hasHydratedProfile = true
            }
        }
        .onChange(of: displayName) { _, _ in
            scheduleAutoSave()
        }
        .onChange(of: selectedColor) { _, _ in
            scheduleAutoSave()
        }
        .onChange(of: selectedIcon) { _, _ in
            scheduleAutoSave()
        }
        .onDisappear {
            autoSaveTask?.cancel()
        }
        .settingsMessageOverlay()
    }

    private var header: some View {
        FigmaBackHeader(title: "Profile")
    }

    private var avatarPreviewCard: some View {
        RoostCard {
            ZStack(alignment: .bottomTrailing) {
                MemberAvatar(
                    label: displayName.isEmpty ? "A" : displayName,
                    color: settingsViewModel.avatarColor(for: selectedColor),
                    icon: LucideIcon.sfSymbolName(for: selectedIcon),
                    size: .lg
                )

                Circle()
                    .fill(Color.roostCard)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .stroke(Color.roostBackground, lineWidth: 2)
                    )
                    .overlay {
                        Image(systemName: "camera")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.roostForeground)
                    }
                    .shadow(color: Color.roostShadow.opacity(0.5), radius: 8, x: 0, y: 4)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var avatarColorCard: some View {
        RoostCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.row) {
                Text("Avatar Color")
                    .font(.roostBody.weight(.medium))
                    .foregroundStyle(Color.roostForeground)

                LazyVGrid(columns: colorColumns, spacing: DesignSystem.Spacing.inline) {
                    ForEach(settingsViewModel.avatarColors, id: \.key) { option in
                        Button {
                            selectedColor = option.key
                        } label: {
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous)
                                .fill(option.color)
                                .frame(height: 44)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous)
                                        .stroke(option.key == selectedColor ? Color.roostForeground.opacity(0.2) : .clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var avatarIconCard: some View {
        RoostCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.row) {
                Text("Avatar Icon")
                    .font(.roostBody.weight(.medium))
                    .foregroundStyle(Color.roostForeground)

                LazyVGrid(columns: iconColumns, spacing: DesignSystem.Spacing.inline) {
                    ForEach(settingsViewModel.avatarIcons, id: \.rawValue) { icon in
                        Button {
                            selectedIcon = icon.rawValue
                        } label: {
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous)
                                .fill(selectedIcon == icon.rawValue ? Color.roostAccent.opacity(0.8) : Color.roostAccent)
                                .frame(height: 44)
                                .overlay {
                                    Image(systemName: icon.sfSymbolName)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(Color.roostForeground)
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous)
                                        .stroke(selectedIcon == icon.rawValue ? Color.roostPrimary.opacity(0.35) : .clear, lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var displayNameCard: some View {
        RoostCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.row) {
                Text("Display Name")
                    .font(.roostBody.weight(.medium))
                    .foregroundStyle(Color.roostForeground)

                Text("This is the name shown across your household.")
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostMutedForeground)
                    .fixedSize(horizontal: false, vertical: true)

                RoostTextField(title: "Your name", text: $displayName)
                
                if isSaving {
                    HStack(spacing: DesignSystem.Spacing.inline) {
                        ProgressView()
                            .controlSize(.small)
                            .tint(Color.roostPrimary)

                        Text("Saving changes…")
                            .font(.roostCaption)
                            .foregroundStyle(Color.roostMutedForeground)
                    }
                }
            }
        }
    }

    private var draftProfileKey: String {
        [
            displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            selectedColor,
            selectedIcon ?? ""
        ].joined(separator: "|")
    }

    private var savedProfileKey: String {
        guard let member = homeManager.currentMember else { return "nil" }
        return [
            member.displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            member.avatarColor ?? (AvatarColorOption.all.first?.key ?? "#7F77DD"),
            member.avatarIcon ?? ""
        ].joined(separator: "|")
    }

    private func scheduleAutoSave() {
        guard hasHydratedProfile else { return }

        autoSaveTask?.cancel()

        guard draftProfileKey != savedProfileKey else { return }

        autoSaveTask = Task {
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            await persistProfileIfNeeded()
        }
    }

    @MainActor
    private func persistProfileIfNeeded() async {
        guard hasHydratedProfile,
              let member = homeManager.currentMember else { return }

        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        while isSaving {
            try? await Task.sleep(for: .milliseconds(120))
            if Task.isCancelled { return }
        }

        guard draftProfileKey != savedProfileKey else { return }

        isSaving = true

        let didSave = await settingsViewModel.updateProfile(
            member: member,
            displayName: trimmedName,
            avatarColor: selectedColor,
            avatarIcon: selectedIcon,
            showsSuccessMessage: false
        )

        if didSave,
           let homeId = homeManager.homeId,
           let userId = homeManager.currentUserId {
            await homeManager.loadHome(homeId: homeId, userId: userId)
        }

        isSaving = false

        if draftProfileKey != savedProfileKey {
            scheduleAutoSave()
        }
    }
}
