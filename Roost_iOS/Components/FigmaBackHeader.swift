import SwiftUI

struct FigmaBackHeader<Accessory: View>: View {
    let title: String
    @ViewBuilder var accessory: Accessory

    @Environment(\.dismiss) private var dismiss

    init(
        title: String,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) {
        self.title = title
        self.accessory = accessory()
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.row) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Color.roostForeground)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text(title)
                .font(.roostPageTitle)
                .foregroundStyle(Color.roostForeground)

            Spacer(minLength: 0)

            accessory
        }
        .padding(.top, DesignSystem.Spacing.screenTop)
    }
}

