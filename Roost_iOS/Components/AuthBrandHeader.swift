import SwiftUI

struct AuthBrandHeader: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.microMedium) {
            RoostLogoMark()
                .padding(.bottom, DesignSystem.Spacing.micro)

            Text("Roost")
                .font(.roostLargeGreeting)
                .foregroundStyle(Color.roostForeground)

            Text("Your home, together.")
                .font(.roostBody)
                .foregroundStyle(Color.roostMutedForeground)
        }
        .frame(maxWidth: .infinity)
    }
}
