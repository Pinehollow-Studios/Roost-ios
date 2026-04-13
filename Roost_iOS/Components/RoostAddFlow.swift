import SwiftUI
import UIKit
import SwiftUIIntrospect

struct RoostAddPageButton: View {
    var title: String = "Add"
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.roostLabel)
            }
            .foregroundStyle(Color.roostCard)
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.roostPrimary)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct RoostSheetCancelButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))

                Text("Cancel")
                    .font(.roostLabel)
            }
            .foregroundStyle(Color.roostPrimary)
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.roostPrimary.opacity(0.10))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.roostPrimary.opacity(0.18), lineWidth: 1)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct RoostSheetHeader: View {
    let title: String
    var subtitle: String? = nil
    var onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .center, spacing: Spacing.md) {
                RoostSheetCancelButton(action: onCancel)

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.roostPageTitle)
                    .foregroundStyle(Color.roostForeground)

                if let subtitle {
                    Text(subtitle)
                        .font(.roostBody)
                        .foregroundStyle(Color.roostMutedForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.bottom, Spacing.sm)
    }
}

struct RoostAddSection<Content: View>: View {
    let title: String
    let helper: String?
    @ViewBuilder var content: Content

    init(
        title: String,
        helper: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.helper = helper
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.roostPrimary.opacity(0.9))
                    .frame(width: 10, height: 10)

                Text(title)
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostForeground)
            }

            if let helper {
                Text(helper)
                    .font(.roostMeta)
                    .foregroundStyle(Color.roostMutedForeground)
            }

            content
        }
    }
}

struct RoostAddChoiceChip: View {
    let title: String
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.roostMeta)
                .foregroundStyle(isSelected ? Color.roostCard : Color.roostForeground)
                .padding(.horizontal, Spacing.md)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                        .fill(isSelected ? Color.roostPrimary : Color.roostInput)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                        .stroke(isSelected ? Color.clear : Color.roostHairline, lineWidth: 1)
                )
                .contentShape(RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct RoostAddCapsuleChip: View {
    let title: String
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.roostMeta)
                .foregroundStyle(isSelected ? Color.roostCard : Color.roostForeground)
                .padding(.horizontal, Spacing.md)
                .frame(minHeight: 44)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? Color.roostPrimary : Color.roostMuted)
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct RoostAddPreviewCard<Content: View>: View {
    @ViewBuilder var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        RoostCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.roostPrimary)

                    Text("Preview")
                        .font(.roostCardTitle)
                        .foregroundStyle(Color.roostForeground)
                }

                content
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: RoostTheme.cardCornerRadius, style: .continuous)
                .stroke(Color.roostPrimary.opacity(0.10), lineWidth: 1)
        )
        .background(
            Color.roostPrimary.opacity(0.025),
            in: RoundedRectangle(cornerRadius: RoostTheme.cardCornerRadius, style: .continuous)
        )
    }
}

struct RoostAddBottomBar<Summary: View>: View {
    let actionTitle: String
    let isSaving: Bool
    let isDisabled: Bool
    @ViewBuilder var summary: Summary
    var action: () -> Void

    init(
        actionTitle: String,
        isSaving: Bool,
        isDisabled: Bool,
        @ViewBuilder summary: () -> Summary,
        action: @escaping () -> Void
    ) {
        self.actionTitle = actionTitle
        self.isSaving = isSaving
        self.isDisabled = isDisabled
        self.summary = summary()
        self.action = action
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(Color.roostPrimary.opacity(0.12))

            HStack(spacing: Spacing.md) {
                summary

                Spacer()

                RoostButton(
                    title: isSaving ? savingTitle : actionTitle,
                    variant: .primary,
                    isLoading: isSaving,
                    fullWidth: false,
                    action: action
                )
                .disabled(isDisabled)
                .opacity(isDisabled ? 0.55 : 1)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.md)
            .background(
                LinearGradient(
                    colors: [
                        Color.roostPrimary.opacity(0.02),
                        Color.roostBackground.opacity(0.92),
                        Color.roostBackground
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private var savingTitle: String {
        if actionTitle.hasSuffix("y") {
            return String(actionTitle.dropLast()) + "ying..."
        }
        return actionTitle + "..."
    }
}

private struct RoostAddScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct RoostAddPullDownDismissModifier: ViewModifier {
    @State private var scrollOffset: CGFloat = 0

    let dismiss: () -> Void

    func body(content: Content) -> some View {
        content
            .background(RoostAddScrollViewConfigurator())
            .coordinateSpace(name: "roostAddScroll")
            .background(alignment: .top) {
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: RoostAddScrollOffsetKey.self,
                            value: geo.frame(in: .named("roostAddScroll")).minY
                        )
                }
                .frame(height: 0)
            }
            .onPreferenceChange(RoostAddScrollOffsetKey.self) { scrollOffset = $0 }
            .simultaneousGesture(
                DragGesture(minimumDistance: 18, coordinateSpace: .local)
                    .onEnded { value in
                        let vertical = value.translation.height
                        let horizontal = abs(value.translation.width)

                        guard scrollOffset >= -2,
                              vertical > 110,
                              vertical > horizontal * 1.2 else {
                            return
                        }

                        dismiss()
                    }
            )
    }
}

private struct RoostAddScrollViewConfigurator: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        configure(from: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        configure(from: uiView)
    }

    private func configure(from view: UIView) {
        DispatchQueue.main.async {
            guard let scrollView = view.enclosingScrollView() else { return }
            scrollView.bounces = false
            scrollView.alwaysBounceVertical = false
            scrollView.refreshControl = nil
        }
    }
}

private extension UIView {
    func enclosingScrollView() -> UIScrollView? {
        var candidate = superview
        while let current = candidate {
            if let scrollView = current as? UIScrollView {
                return scrollView
            }
            candidate = current.superview
        }
        return nil
    }
}

extension View {
    func conditionalRefreshable(
        _ isEnabled: Bool,
        action: @escaping @Sendable () async -> Void
    ) -> some View {
        modifier(ConditionalRefreshableModifier(isEnabled: isEnabled, action: action))
    }

    func roostDisableVerticalBounce() -> some View {
        introspect(
            .scrollView,
            on: .iOS(.v17, .v18)
        ) { scrollView in
            scrollView.bounces = false
            scrollView.alwaysBounceVertical = false
            scrollView.refreshControl = nil
        }
    }

    func roostAddDismissOnPullDown(_ dismiss: @escaping () -> Void) -> some View {
        modifier(RoostAddPullDownDismissModifier(dismiss: dismiss))
    }
}

private struct ConditionalRefreshableModifier: ViewModifier {
    let isEnabled: Bool
    let action: @Sendable () async -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            content.refreshable {
                await action()
            }
        } else {
            content
        }
    }
}
