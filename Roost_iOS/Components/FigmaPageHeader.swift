import SwiftUI

struct FigmaPageHeader<Accessory: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder var accessory: Accessory

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.accessory = accessory()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.inline) {
            HStack(alignment: .center, spacing: DesignSystem.Spacing.row) {
                Text(title)
                    .font(.roostPageTitle)
                    .foregroundStyle(Color.roostForeground)

                Spacer(minLength: 0)

                accessory
            }

            if let subtitle {
                Text(subtitle)
                    .font(.roostBody)
                    .foregroundStyle(Color.roostMutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
