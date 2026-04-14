import SwiftUI

struct FigmaBackHeader<Accessory: View>: View {
    let title: String
    let accent: Color?
    @ViewBuilder var accessory: Accessory

    @Environment(\.dismiss) private var dismiss

    init(
        title: String,
        accent: Color? = nil,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) {
        self.title = title
        self.accent = accent
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
        .padding(.top, DesignSystem.Spacing.screenTop)
    }
}

