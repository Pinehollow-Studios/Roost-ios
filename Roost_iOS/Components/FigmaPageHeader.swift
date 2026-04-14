import SwiftUI

struct FigmaPageHeader<Accessory: View>: View {
    let title: String
    let subtitle: String?
    let accent: Color?
    @ViewBuilder var accessory: Accessory

    init(
        title: String,
        subtitle: String? = nil,
        accent: Color? = nil,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.accent = accent
        self.accessory = accessory()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.inline) {
            HStack(alignment: .center, spacing: DesignSystem.Spacing.row) {
                HStack(alignment: .center, spacing: 10) {
                    if let accent {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(accent)
                            .frame(width: 3, height: 26)
                    }

                    Text(title)
                        .font(.roostPageTitle)
                        .foregroundStyle(Color.roostForeground)
                }

                Spacer(minLength: 0)

                accessory
            }

            if let subtitle {
                Text(subtitle)
                    .font(.roostBody)
                    .foregroundStyle(Color.roostMutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, accent != nil ? 13 : 0)
            }
        }
    }
}
