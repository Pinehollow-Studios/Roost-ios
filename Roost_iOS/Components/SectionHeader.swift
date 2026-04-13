import SwiftUI

struct SectionHeader: View {
    let eyebrow: String?
    let title: String
    let subtitle: String?
    var trailing: AnyView? = nil

    init(
        eyebrow: String? = nil,
        title: String,
        subtitle: String? = nil,
        trailing: AnyView? = nil
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                if let eyebrow {
                    Text(eyebrow)
                        .font(.roostMeta)
                        .foregroundStyle(Color.roostMutedForeground)
                }

                Text(title)
                    .font(.roostCardTitle)
                    .foregroundStyle(Color.roostForeground)

                if let subtitle {
                    Text(subtitle)
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)

            if let trailing {
                trailing
            }
        }
    }
}

struct StatChip: View {
    let title: String
    let value: String
    var tint: Color = .roostAccent

    var body: some View {
        RoostInfoChip(title: title, value: value, tint: tint)
    }
}
