import Foundation
import Observation
import SwiftUI

struct MemberNames {
    let me: String
    let partner: String
    let meInitials: String
    let partnerInitials: String
    let meColour: Color
    let partnerColour: Color
    let hasPartner: Bool
}

@MainActor
@Observable
final class MemberNamesHelper {

    var names: MemberNames = MemberNames(
        me: "You",
        partner: "Your partner",
        meInitials: "YO",
        partnerInitials: "YP",
        meColour: .roostPrimary,
        partnerColour: .roostSecondary,
        hasPartner: false
    )

    func load(currentUserId: UUID, homeMembers: [HomeMember]) {
        guard let me = homeMembers.first(where: { $0.userID == currentUserId }) else { return }
        let partner = homeMembers.first(where: { $0.userID != currentUserId })

        let meName = Self.displayName(member: me)
        let partnerName = partner.map { Self.displayName(member: $0) } ?? "Your partner"

        names = MemberNames(
            me: meName,
            partner: partnerName,
            meInitials: Self.initials(from: meName),
            partnerInitials: partner.map { Self.initials(from: Self.displayName(member: $0)) } ?? "YP",
            meColour: colour(for: me.avatarColor),
            partnerColour: partner.map { colour(for: $0.avatarColor) } ?? Color.roostSecondary,
            hasPartner: partner != nil
        )
    }

    static func initials(from name: String) -> String {
        let parts = name.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if parts.count >= 2 {
            return (String(parts[0].prefix(1)) + String(parts[1].prefix(1))).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    /// Returns displayName trimmed of whitespace, never nil.
    static func displayName(member: HomeMember) -> String {
        let name = member.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Member" : name
    }

    // MARK: - Private

    private func colour(for avatarColor: String?) -> Color {
        switch avatarColor {
        case "terracotta": return Color(hex: 0xD4815E)
        case "sage":       return Color(hex: 0x8EA882)
        case "sky":        return Color(hex: 0x7A8FA1)
        case "rose":       return Color(hex: 0xD98695)
        case "violet":     return Color(hex: 0xA08AB8)
        case "amber":      return Color(hex: 0xC99952)
        case "teal":       return Color(hex: 0x7CB7A3)
        case "slate":      return Color(hex: 0x8A7B6F)
        default:           return Color.roostPrimary
        }
    }
}
