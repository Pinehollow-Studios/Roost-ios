import SwiftUI

struct RoostTextField: View {
    let title: String
    @Binding var text: String
    var leadingSystemImage: String? = nil
    var textAlignment: TextAlignment = .leading
    var font: Font = .roostBody
    var textTracking: CGFloat = 0
    /// When `true`, the field switches to its error treatment — tinted destructive fill,
    /// 1.5pt destructive border, leading + trailing destructive icons, and a two-tone
    /// inline message beneath. Overrides the `leadingSystemImage` slot.
    var isError: Bool = false
    /// Destructive-toned copy that names the problem. Rendered in the inline message.
    var errorMessage: String? = nil
    /// Muted-toned copy that tells the user how to fix it. Rendered alongside `errorMessage`.
    var errorHint: String? = nil

    @FocusState private var isFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.inline) {
            fieldBody
            if isError, let errorMessage {
                errorInlineMessage(errorMessage)
            }
        }
    }

    private var fieldBody: some View {
        HStack(spacing: DesignSystem.Spacing.row) {
            if isError {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: DesignSystem.Size.icon, weight: .regular))
                    .foregroundStyle(Color.roostDestructive)
                    .frame(width: 18, alignment: .center)
                    .accessibilityHidden(true)
            } else if let leadingSystemImage {
                Image(systemName: leadingSystemImage)
                    .font(.system(size: DesignSystem.Size.icon, weight: .regular))
                    .foregroundStyle(Color.roostMutedForeground)
                    .frame(width: 18, alignment: .center)
                    .accessibilityHidden(true)
            }

            TextField(title, text: $text)
                .font(font)
                .foregroundStyle(Color.roostForeground)
                .tracking(textTracking)
                .multilineTextAlignment(textAlignment)
                .focused($isFocused)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isError {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: DesignSystem.Size.icon, weight: .regular))
                    .foregroundStyle(Color.roostDestructive)
                    .frame(width: 18, alignment: .center)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.card)
        .frame(minHeight: 48)
        .background(
            RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                .fill(fillColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                .strokeBorder(borderColor, lineWidth: borderWidth)
        )
        .overlay(focusHalo)
        .animation(reduceMotion ? nil : .roostEaseOut, value: isFocused)
        .animation(reduceMotion ? nil : .roostEaseOut, value: isError)
    }

    /// 4pt halo rendered outside the stroked border when focused — per design-system spec.
    /// Suppressed in error state to avoid colour collision with the destructive border.
    @ViewBuilder
    private var focusHalo: some View {
        if isFocused && !isError {
            RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius + 2, style: .continuous)
                .stroke(Color.roostPrimary.opacity(RoostTheme.focusRingOpacity), lineWidth: 4)
                .padding(-2)
                .allowsHitTesting(false)
        }
    }

    private func errorInlineMessage(_ message: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.micro) {
            Text(message)
                .foregroundStyle(Color.roostDestructive)
            if let errorHint {
                Text(errorHint)
                    .foregroundStyle(Color.roostMutedForeground)
            }
        }
        .font(.roostMeta)
        .padding(.leading, DesignSystem.Spacing.card)
        .accessibilityElement(children: .combine)
    }

    private var fillColor: Color {
        isError ? Color.roostDestructiveSoft : Color.roostInput
    }

    private var borderColor: Color {
        if isError { return Color.roostDestructive }
        return isFocused ? Color.roostPrimary : Color.roostHairline
    }

    private var borderWidth: CGFloat {
        if isError || isFocused { return 1.5 }
        return 1
    }
}
