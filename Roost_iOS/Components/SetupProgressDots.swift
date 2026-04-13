import SwiftUI

struct SetupProgressDots: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.inline) {
            ForEach(1...totalSteps, id: \.self) { step in
                Circle()
                    .fill(step == currentStep ? Color.roostPrimary : Color.roostMuted)
                    .frame(
                        width: step == currentStep ? DesignSystem.Size.progressDotActive : DesignSystem.Size.progressDotInactive,
                        height: step == currentStep ? DesignSystem.Size.progressDotActive : DesignSystem.Size.progressDotInactive
                    )
                    .animation(.roostEaseOut, value: currentStep)
            }
        }
    }
}
