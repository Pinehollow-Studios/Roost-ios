import SwiftUI

/// Static card-coloured rectangle placeholder. Per design-system spec
/// (`README.md §158`): "Skeleton loaders are static card-coloured rectangles — no shimmer.
/// Shimmer is reserved for the Pro CTA sweep." The previous animated gradient-sweep
/// implementation violated that rule and has been removed.
struct LoadingSkeletonView: View {
    var height: CGFloat = 100

    var body: some View {
        RoundedRectangle(cornerRadius: DesignSystem.Radius.sm, style: .continuous)
            .fill(Color.roostMuted)
            .frame(height: height)
    }
}
