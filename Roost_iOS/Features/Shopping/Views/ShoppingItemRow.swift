import SwiftUI

struct ShoppingItemRow: View {
    let item: ShoppingItem
    let addedByName: String?
    let onToggle: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var checkScale: CGFloat = 1
    @State private var ringScale: CGFloat = 1
    @State private var ringOpacity: Double = 0

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .center, spacing: DesignSystem.Spacing.row) {
                checkbox

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.roostBody.weight(.medium))
                        .foregroundStyle(item.checked ? Color.roostMutedForeground : Color.roostForeground)
                        .strikethrough(item.checked, color: Color.roostMutedForeground.opacity(0.8))
                        .multilineTextAlignment(.leading)
                        .animation(reduceMotion ? nil : .roostEaseOut, value: item.checked)

                    Text(addedByLine)
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                }

                Spacer(minLength: DesignSystem.Spacing.inline)

                if let quantityLabel {
                    FigmaChip(title: quantityLabel)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(minHeight: 52)
            .opacity(item.checked ? 0.6 : 1)
            .contentShape(Rectangle())
        }
        .accessibilityHint(item.checked ? "Marks the item as not done" : "Marks the item as done")
        .buttonStyle(ShoppingRowButtonStyle(reduceMotion: reduceMotion))
        .onChange(of: item.checked) { _, newValue in
            guard newValue, !reduceMotion else { return }
            withAnimation(DesignSystem.Motion.checkmark) {
                checkScale = 1.22
                ringOpacity = 1
                ringScale = 1
            }
            Task {
                try? await Task.sleep(for: .milliseconds(140))
                withAnimation(DesignSystem.Motion.checkmark) {
                    checkScale = 1
                }
                withAnimation(.easeOut(duration: 0.3)) {
                    ringOpacity = 0
                    ringScale = 1.55
                }
            }
        }
    }

    private var checkbox: some View {
        ZStack {
            // Ripple ring
            Circle()
                .strokeBorder(Color.roostPrimary.opacity(0.28), lineWidth: 1.5)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)

            // Fill
            Circle()
                .fill(item.checked ? Color.roostPrimary : Color.clear)
                .animation(DesignSystem.Motion.checkmark, value: item.checked)

            // Border
            Circle()
                .strokeBorder(
                    item.checked ? Color.roostPrimary : Color.roostHairline,
                    lineWidth: 2
                )
                .animation(DesignSystem.Motion.checkmark, value: item.checked)

            if item.checked {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.roostCard)
                    .scaleEffect(checkScale)
                    .transition(
                        .scale(scale: 0.3, anchor: .center)
                        .combined(with: .opacity)
                    )
            }
        }
        .frame(width: 24, height: 24)
        .padding(.top, 1)
    }

    private var addedByLine: String {
        if let addedByName, !addedByName.isEmpty {
            return "Added by \(addedByName)"
        }
        return item.checked ? "Picked up" : "Shared list item"
    }

    private var quantityLabel: String? {
        guard let quantity = item.quantity?.trimmingCharacters(in: .whitespacesAndNewlines), !quantity.isEmpty else {
            return nil
        }

        if quantity.first?.isNumber == true, quantity.hasPrefix("×") == false {
            return "×\(quantity)"
        }
        return quantity
    }
}

private struct ShoppingRowButtonStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(reduceMotion ? nil : DesignSystem.Motion.buttonPress, value: configuration.isPressed)
    }
}
