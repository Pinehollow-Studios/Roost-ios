import SwiftUI

struct FigmaChip: View {
    enum Variant {
        case `default`
        case success
        case warning
        case destructive
        case primary
        case secondary
    }

    let title: String
    var variant: Variant = .default
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .semibold))
            }

            Text(title)
                .font(.roostMeta)
                .lineLimit(1)
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(backgroundColor, in: Capsule())
        .overlay(Capsule().stroke(foregroundColor.opacity(0.2), lineWidth: 1))
    }

    private var foregroundColor: Color {
        switch variant {
        case .default:
            return .roostMutedForeground
        case .success:
            return .roostSuccess
        case .warning:
            return .roostWarning
        case .destructive:
            return .roostDestructive
        case .primary:
            return .roostPrimary
        case .secondary:
            return .roostSecondaryInteractive
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .default:
            return .roostMuted
        case .success:
            return .roostSuccess.opacity(0.15)
        case .warning:
            return .roostWarning.opacity(0.15)
        case .destructive:
            return .roostDestructive.opacity(0.15)
        case .primary:
            return .roostPrimary.opacity(0.15)
        case .secondary:
            return .roostSecondaryInteractive.opacity(0.15)
        }
    }
}
