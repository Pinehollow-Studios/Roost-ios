import SwiftUI

struct JoinView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = JoinViewModel()

    let initialInviteCode: String?
    let initialDisplayName: String?

    // Entrance
    @State private var entered = false
    // Orb floating
    @State private var orbA = false
    @State private var orbB = false
    @State private var orbC = false

    init(initialInviteCode: String? = nil, initialDisplayName: String? = nil) {
        self.initialInviteCode = initialInviteCode
        self.initialDisplayName = initialDisplayName
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.roostBackground.ignoresSafeArea()
                atmosphereLayer.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Back header
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

                        Text("Join a home")
                            .font(.roostPageTitle)
                            .foregroundStyle(Color.roostForeground)

                        Spacer(minLength: 0)
                    }
                    .padding(.top, geo.safeAreaInsets.top + DesignSystem.Spacing.screenTop)
                    .padding(.horizontal, DesignSystem.Spacing.page)
                    .padding(.bottom, DesignSystem.Spacing.block)
                    .opacity(entered ? 1 : 0)
                    .animation(.easeOut(duration: 0.35).delay(0.05), value: entered)

                    // Main content
                    VStack(spacing: 0) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(Color.roostPrimary.opacity(0.15))
                                .frame(width: 88, height: 88)
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundStyle(Color.roostPrimary)
                        }
                        .shadow(color: Color.roostPrimary.opacity(0.35), radius: 20, x: 0, y: 8)
                        .scaleEffect(entered ? 1 : 0.72)
                        .opacity(entered ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.12), value: entered)
                        .padding(.bottom, 20)

                        Text("Enter the invite code from\nyour partner to join their home")
                            .font(.roostBody)
                            .foregroundStyle(Color.roostMutedForeground)
                            .multilineTextAlignment(.center)
                            .opacity(entered ? 1 : 0)
                            .offset(y: entered ? 0 : 12)
                            .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.20), value: entered)
                            .padding(.bottom, DesignSystem.Spacing.blockLarge)

                        // Code field card
                        VStack(spacing: DesignSystem.Spacing.row) {
                            RoostTextField(
                                title: "XXXXXX",
                                text: $viewModel.inviteCode,
                                textAlignment: .center,
                                font: .roostSectionHeading,
                                textTracking: 2
                            )
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(.roostCaption)
                                    .foregroundStyle(Color.roostDestructive)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                            }

                            RoostButton(
                                title: viewModel.isLoading ? "Joining…" : "Join",
                                variant: .primary,
                                isLoading: viewModel.isLoading
                            ) {
                                Task {
                                    if await viewModel.joinHome() {
                                        await authManager.refreshHomeStatus()
                                    }
                                }
                            }
                            .disabled(viewModel.isLoading || trimmedInviteCode.isEmpty)
                            .opacity(trimmedInviteCode.isEmpty ? 0.65 : 1)
                        }
                        .padding(DesignSystem.Spacing.card)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.xl, style: .continuous)
                                .fill(Color.roostCard.opacity(0.88))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.xl, style: .continuous)
                                .stroke(Color.roostHairline, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.24), radius: 28, x: 0, y: 10)
                        .opacity(entered ? 1 : 0)
                        .offset(y: entered ? 0 : 40)
                        .animation(.spring(response: 0.72, dampingFraction: 0.82).delay(0.28), value: entered)

                        AuthDivider(title: "Or", textFont: .roostLabel)
                            .padding(.vertical, DesignSystem.Spacing.blockLarge)
                            .opacity(entered ? 1 : 0)
                            .animation(.easeOut(duration: 0.3).delay(0.38), value: entered)

                        RoostButton(title: "Create your own home", variant: .ghost) {
                            dismiss()
                        }
                        .opacity(entered ? 1 : 0)
                        .animation(.easeOut(duration: 0.3).delay(0.42), value: entered)
                    }
                    .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, DesignSystem.Spacing.page)
                    .padding(.bottom, geo.safeAreaInsets.bottom + DesignSystem.Spacing.screenBottom)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.spring(response: 0.75, dampingFraction: 0.72)) {
                entered = true
            }
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                orbA = true
            }
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true).delay(0.9)) {
                orbB = true
            }
            withAnimation(.easeInOut(duration: 5.8).repeatForever(autoreverses: true).delay(1.8)) {
                orbC = true
            }

            if let initialDisplayName, !initialDisplayName.isEmpty {
                viewModel.displayName = initialDisplayName
            } else if let name = authManager.currentUser?.displayName, !name.isEmpty {
                viewModel.displayName = name
            }

            if let initialInviteCode, !initialInviteCode.isEmpty {
                viewModel.inviteCode = initialInviteCode
            } else if let pendingCode = authManager.consumePendingJoinCode() {
                viewModel.inviteCode = pendingCode
            }
        }
    }

    // MARK: – Background atmosphere

    private var atmosphereLayer: some View {
        ZStack {
            // Terracotta glow — top centre
            Circle()
                .fill(Color.roostPrimary.opacity(0.30))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: orbA ? 10 : -10, y: orbA ? -100 : -70)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            // Amber glow — bottom leading
            Circle()
                .fill(Color(red: 0.96, green: 0.60, blue: 0.18).opacity(0.22))
                .frame(width: 260, height: 260)
                .blur(radius: 72)
                .offset(x: orbB ? -50 : -20, y: orbB ? 90 : 50)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

            // Soft pulse — centre
            Circle()
                .fill(Color.roostPrimary.opacity(0.09))
                .frame(width: 180, height: 180)
                .blur(radius: 50)
                .offset(x: orbC ? 30 : -30, y: orbC ? -10 : 30)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    // MARK: – Helpers

    private var trimmedInviteCode: String {
        viewModel.inviteCode.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
