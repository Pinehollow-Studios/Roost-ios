import SwiftUI

struct MemberAvatar: View {
    enum Size {
        case xs
        case sm
        case md
        case lg
        case xl

        var dimension: CGFloat {
            switch self {
            case .xs: 24
            case .sm: 32
            case .md: 44
            case .lg: 56
            case .xl: 72
            }
        }

        /// DMSans-SemiBold at the size spec'd by `components-avatars.html`.
        var font: Font {
            switch self {
            case .xs: return Font.custom("DMSans-SemiBold", size: 11)
            case .sm: return Font.custom("DMSans-SemiBold", size: 12)
            case .md: return Font.custom("DMSans-SemiBold", size: 15)
            case .lg: return Font.custom("DMSans-SemiBold", size: 18)
            case .xl: return Font.custom("DMSans-SemiBold", size: 24)
            }
        }
    }

    let label: String
    var color: Color = DesignSystem.Palette.primary
    var icon: String?
    var size: Size = .md

    init(label: String, color: Color = DesignSystem.Palette.primary, icon: String? = nil, size: Size = .md) {
        self.label = label
        self.color = color
        self.icon = icon
        self.size = size
    }

    init(member: HomeMember?, fallbackLabel: String = "?", size: Size = .md) {
        self.label = member?.displayName ?? fallbackLabel
        self.color = AvatarColorOption.color(for: member?.avatarColor)
        self.icon = LucideIcon.sfSymbolName(for: member?.avatarIcon)
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(Color.roostCard)
                    .font(size.font)
            } else {
                Text(String(label.prefix(1)).uppercased())
                    .font(size.font)
                    .foregroundStyle(Color.roostCard)
            }
        }
        .frame(width: size.dimension, height: size.dimension)
    }
}
