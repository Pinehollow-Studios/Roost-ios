import Observation
import SwiftUI

struct AvatarColorOption: Hashable {
    let key: String
    let color: Color

    static let all: [AvatarColorOption] = [
        .init(key: "#7F77DD", color: Color(hex: 0x7F77DD)), // violet (default)
        .init(key: "#E05878", color: Color(hex: 0xE05878)), // rose
        .init(key: "#D6533A", color: Color(hex: 0xD6533A)), // terracotta
        .init(key: "#D4861D", color: Color(hex: 0xD4861D)), // amber
        .init(key: "#3DA85F", color: Color(hex: 0x3DA85F)), // green
        .init(key: "#3B9BD0", color: Color(hex: 0x3B9BD0)), // blue
        .init(key: "#8B5CF6", color: Color(hex: 0x8B5CF6)), // purple
        .init(key: "#D44FAB", color: Color(hex: 0xD44FAB)), // fuchsia
        .init(key: "#2A9D8F", color: Color(hex: 0x2A9D8F)), // teal
        .init(key: "#5C7A40", color: Color(hex: 0x5C7A40)), // olive
        .init(key: "#C0392B", color: Color(hex: 0xC0392B)), // crimson
        .init(key: "#5C7A8C", color: Color(hex: 0x5C7A8C)), // slate
    ]

    /// Legacy name → hex mapping for users who saved color names with older iOS builds.
    private static let legacyNameMap: [String: String] = [
        "terracotta": "#D6533A",
        "sage":       "#2A9D8F",
        "gold":       "#D4861D",
        "rose":       "#E05878",
        "sky":        "#3B9BD0",
        "plum":       "#8B5CF6",
        "mint":       "#2A9D8F",
        "peach":      "#D4861D",
        "cocoa":      "#D6533A",
        "slate":      "#5C7A8C",
        "berry":      "#E05878",
        "sunflower":  "#D4861D",
    ]

    static func color(for key: String?) -> Color {
        guard let key else { return Color(hex: 0x7F77DD) }
        if let option = all.first(where: { $0.key == key }) { return option.color }
        if let hex = legacyNameMap[key], let option = all.first(where: { $0.key == hex }) { return option.color }
        return Color(hex: 0x7F77DD)
    }
}

@MainActor
@Observable
final class SettingsViewModel {
    var userPreferences = UserPreferences.defaults
    var isLoading = false
    var errorMessage: String?
    var successMessage: String?

    @ObservationIgnored
    private let homeService = HomeService()

    @ObservationIgnored
    private let userPreferencesService = UserPreferencesService()

    @ObservationIgnored
    private let authService = AuthService()

    let avatarColors = AvatarColorOption.all
    let avatarIcons = LucideIcon.allCases
    let currencyOptions = ["GBP", "USD", "EUR"]
    let weekStartOptions = ["monday", "sunday"]
    let timeFormatOptions = ["12h", "24h"]
    let dateFormatOptions = ["dd/MM/yyyy", "MM/dd/yyyy", "yyyy-MM-dd"]

    func loadPreferences(for userId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            userPreferences = try await userPreferencesService.fetchPreferences(for: userId)
        } catch {
            userPreferences = defaultPreferences(for: userId)
        }

        isLoading = false
    }

    func savePreferences(
        userId: UUID,
        weekStarts: String,
        timeFormat: String,
        currency: String,
        dateFormat: String
    ) async {
        let updated = UserPreferences(
            userID: userId,
            weekStarts: weekStarts,
            timeFormat: timeFormat,
            currency: currency,
            dateFormat: dateFormat,
            updatedAt: userPreferences.updatedAt
        )

        do {
            try await userPreferencesService.upsertPreferences(updated)
            userPreferences = updated
            successMessage = "Preferences saved."
        } catch {
            if !isCancellation(error) {
                errorMessage = String(describing: error)
            }
        }
    }

    func updateProfile(
        member: HomeMember,
        displayName: String,
        avatarColor: String,
        avatarIcon: String?,
        showsSuccessMessage: Bool = true
    ) async -> Bool {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }

        do {
            try await homeService.updateMemberProfile(
                id: member.id,
                displayName: trimmedName,
                avatarColor: avatarColor,
                avatarIcon: avatarIcon
            )
            if showsSuccessMessage {
                successMessage = "Profile updated."
            }
            return true
        } catch {
            if !isCancellation(error) {
                errorMessage = String(describing: error)
            }
            return false
        }
    }

    func updateHomeName(_ home: Home, newName: String) async -> Bool {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }

        do {
            try await homeService.updateHomeName(id: home.id, name: trimmedName)
            successMessage = "Household updated."
            return true
        } catch {
            if !isCancellation(error) {
                errorMessage = String(describing: error)
            }
            return false
        }
    }

    func changeEmail(_ email: String) async -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        do {
            try await authService.updateEmail(trimmed)
            successMessage = "Email change confirmation sent."
            return true
        } catch {
            if !isCancellation(error) {
                errorMessage = String(describing: error)
            }
            return false
        }
    }

    func sendPasswordReset(email: String) async -> Bool {
        guard !email.isEmpty else { return false }

        do {
            try await authService.sendPasswordReset(email: email)
            successMessage = "Password reset email sent."
            return true
        } catch {
            if !isCancellation(error) {
                errorMessage = String(describing: error)
            }
            return false
        }
    }

    func leaveHome(authManager: AuthManager, homeManager: HomeManager) async -> Bool {
        do {
            try await homeService.leaveHome()
            homeManager.clearHomeState()
            await authManager.refreshHomeStatus()
            successMessage = "You left the household."
            return true
        } catch {
            if !isCancellation(error) {
                errorMessage = String(describing: error)
            }
            return false
        }
    }

    func deleteAccount(authManager: AuthManager, homeManager: HomeManager) async -> Bool {
        do {
            try await authService.deleteAccount()
            homeManager.clearHomeState()
            successMessage = "Account deleted."
            return true
        } catch {
            if !isCancellation(error) {
                errorMessage = String(describing: error)
            }
            return false
        }
    }

    func avatarColor(for key: String?) -> Color {
        AvatarColorOption.color(for: key)
    }

    func dateFormatStyle() -> Date.FormatStyle {
        switch userPreferences.dateFormat {
        case "MM/dd/yyyy":
            return .dateTime.month(.twoDigits).day(.twoDigits).year()
        case "yyyy-MM-dd":
            return .dateTime.year().month(.twoDigits).day(.twoDigits)
        default:
            return .dateTime.day(.twoDigits).month(.twoDigits).year()
        }
    }

    func formattedDate(_ date: Date) -> String {
        date.formatted(dateFormatStyle())
    }

    func defaultPreferences(for userId: UUID) -> UserPreferences {
        var prefs = UserPreferences.defaults
        prefs.userID = userId
        return prefs
    }

    private func isCancellation(_ error: Error) -> Bool {
        (error as? URLError)?.code == .cancelled ||
        (error as NSError).code == NSURLErrorCancelled
    }
}
