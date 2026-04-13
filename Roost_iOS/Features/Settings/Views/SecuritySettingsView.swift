import SwiftUI
import LocalAuthentication

struct SecuritySettingsView: View {
    @Environment(AppLockManager.self) private var lockManager

    @State private var appLockEnabled = false
    @State private var useBiometrics = false
    @State private var autoLockDelay = 0
    @State private var showPINSetup = false
    @State private var showDisableConfirm = false
    @State private var disablePINEntry = ""
    @State private var biometricsAvailable = false
    @State private var biometricsLabel = "Face ID"

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                FigmaBackHeader(title: "Security")
                securitySection
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .swipeBackEnabled()
        .onAppear {
            appLockEnabled = lockManager.isEnabled
            useBiometrics = lockManager.useBiometrics
            autoLockDelay = lockManager.autoLockDelay
            setupBiometrics()
        }
        .sheet(isPresented: $showPINSetup, onDismiss: {
            appLockEnabled = lockManager.isEnabled
        }) {
            PINSetupView(onCancel: {
                if !lockManager.hasPIN {
                    appLockEnabled = false
                }
            })
            .environment(lockManager)
        }
        .alert("Disable App Lock", isPresented: $showDisableConfirm) {
            SecureField("Enter your PIN", text: $disablePINEntry)
            Button("Disable", role: .destructive) {
                confirmDisable()
            }
            Button("Cancel", role: .cancel) {
                disablePINEntry = ""
                appLockEnabled = true
            }
        } message: {
            Text("Enter your current PIN to disable app lock.")
        }
    }

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.row) {
            Text("App Lock")
                .font(.roostLabel)
                .foregroundStyle(Color.roostMutedForeground)
                .textCase(.uppercase)
                .tracking(0.6)

            RoostCard {
                VStack(spacing: 0) {
                    // App Lock toggle
                    Toggle(isOn: Binding(
                        get: { appLockEnabled },
                        set: { newValue in
                            if newValue {
                                if !lockManager.hasPIN {
                                    appLockEnabled = true
                                    showPINSetup = true
                                } else {
                                    lockManager.isEnabled = true
                                    appLockEnabled = true
                                }
                            } else {
                                showDisableConfirm = true
                            }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("App lock")
                                .font(.roostBody)
                                .foregroundStyle(Color.roostForeground)
                            Text("Require PIN to open Roost")
                                .font(.roostCaption)
                                .foregroundStyle(Color.roostMutedForeground)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.inline)
                    .tint(Color.roostPrimary)

                    if lockManager.hasPIN {
                        Divider()
                            .overlay(Color.roostHairline)

                        // Change PIN row
                        Button {
                            showPINSetup = true
                        } label: {
                            HStack {
                                Text("Change PIN")
                                    .font(.roostBody)
                                    .foregroundStyle(Color.roostForeground)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.roostMutedForeground)
                            }
                            .padding(.vertical, DesignSystem.Spacing.inline)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    if biometricsAvailable && appLockEnabled {
                        Divider()
                            .overlay(Color.roostHairline)

                        Toggle(isOn: Binding(
                            get: { useBiometrics },
                            set: { newValue in
                                useBiometrics = newValue
                                lockManager.useBiometrics = newValue
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Use \(biometricsLabel)")
                                    .font(.roostBody)
                                    .foregroundStyle(Color.roostForeground)
                                Text("Unlock Roost with \(biometricsLabel)")
                                    .font(.roostCaption)
                                    .foregroundStyle(Color.roostMutedForeground)
                            }
                        }
                        .padding(.vertical, DesignSystem.Spacing.inline)
                        .tint(Color.roostPrimary)
                        .disabled(!appLockEnabled)
                    }

                    if appLockEnabled {
                        Divider()
                            .overlay(Color.roostHairline)

                        HStack {
                            Text("Lock after")
                                .font(.roostBody)
                                .foregroundStyle(Color.roostForeground)
                            Spacer()
                            Picker("", selection: Binding(
                                get: { autoLockDelay },
                                set: { newValue in
                                    autoLockDelay = newValue
                                    lockManager.autoLockDelay = newValue
                                }
                            )) {
                                Text("Immediately").tag(0)
                                Text("1 minute").tag(60)
                                Text("5 minutes").tag(300)
                                Text("15 minutes").tag(900)
                            }
                            .pickerStyle(.menu)
                            .tint(Color.roostPrimary)
                        }
                        .padding(.vertical, DesignSystem.Spacing.inline)
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
        }
    }

    private func setupBiometrics() {
        biometricsAvailable = lockManager.biometricsAvailable()
        let btype = lockManager.biometricType()
        biometricsLabel = btype == .touchID ? "Touch ID" : "Face ID"
    }

    private func confirmDisable() {
        let pin = disablePINEntry
        disablePINEntry = ""
        if lockManager.unlock(pin: pin) {
            lockManager.clearPIN()
            appLockEnabled = false
            useBiometrics = false
        } else {
            // Wrong PIN — revert toggle
            appLockEnabled = true
        }
    }
}
