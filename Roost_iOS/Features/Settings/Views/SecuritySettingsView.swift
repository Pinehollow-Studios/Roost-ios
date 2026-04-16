import SwiftUI
import LocalAuthentication

struct SecuritySettingsView: View {
    @Environment(AppLockManager.self) private var lockManager

    @State private var appLockEnabled = false
    @State private var useBiometrics = false
    @State private var showPINSetup = false
    @State private var showDisableConfirm = false
    @State private var biometricsAvailable = false
    @State private var biometricsLabel = "Face ID"

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.block) {
                FigmaBackHeader(title: "Security", accent: .roostPrimary)

                lockStatusCard
                appLockCard
            }
            .padding(.horizontal, DesignSystem.Spacing.page)
            .padding(.bottom, 108)
            .frame(maxWidth: DesignSystem.Size.maxPhoneWidth)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .swipeBackEnabled()
        .onAppear {
            appLockEnabled = lockManager.isEnabled
            useBiometrics = lockManager.useBiometrics
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
        .sheet(isPresented: $showDisableConfirm, onDismiss: {
            appLockEnabled = lockManager.isEnabled
            useBiometrics = lockManager.useBiometrics
        }) {
            DisableLockPINSheet {
                lockManager.clearPIN()
                appLockEnabled = false
                useBiometrics = false
                showDisableConfirm = false
            } onCancel: {
                appLockEnabled = true
                showDisableConfirm = false
            }
            .environment(lockManager)
        }
    }

    // MARK: - Status Card

    private var lockStatusCard: some View {
        RoostCard {
            HStack(spacing: DesignSystem.Spacing.row) {
                ZStack {
                    Circle()
                        .fill(appLockEnabled ? Color.roostSuccess.opacity(0.12) : Color.roostMuted)
                        .frame(width: 44, height: 44)
                    Image(systemName: appLockEnabled ? "lock.fill" : "lock.open.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(appLockEnabled ? Color.roostSuccess : Color.roostMutedForeground)
                }
                .animation(.roostSnappy, value: appLockEnabled)

                VStack(alignment: .leading, spacing: 4) {
                    Text(appLockEnabled ? "App is protected" : "No lock set")
                        .font(.roostBody.weight(.semibold))
                        .foregroundStyle(Color.roostForeground)

                    Text(lockStatusSubtitle)
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .animation(.roostSnappy, value: appLockEnabled)

                Spacer(minLength: 0)

                Text(appLockEnabled ? "On" : "Off")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(appLockEnabled ? Color.roostSuccess : Color.roostMutedForeground)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        (appLockEnabled ? Color.roostSuccess : Color.roostMuted).opacity(appLockEnabled ? 0.12 : 0.7),
                        in: Capsule()
                    )
                    .animation(.roostSnappy, value: appLockEnabled)
            }
        }
    }

    private var lockStatusSubtitle: String {
        if appLockEnabled {
            if biometricsAvailable && useBiometrics {
                return "Locks on exit · Unlocks with \(biometricsLabel) or PIN"
            }
            return "Requires your PIN every time you open Roost"
        }
        return "Anyone with your phone can open Roost"
    }

    // MARK: - App Lock Card

    private var appLockCard: some View {
        RoostCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: DesignSystem.Spacing.inline) {
                    ZStack {
                        Circle()
                            .fill(Color.roostPrimary.opacity(0.10))
                            .frame(width: 32, height: 32)
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.roostPrimary)
                    }
                    Text("App Lock")
                        .font(.roostCardTitle)
                        .foregroundStyle(Color.roostForeground)
                }
                .padding(.bottom, DesignSystem.Spacing.row)

                // Enable toggle
                HStack(spacing: DesignSystem.Spacing.row) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Require PIN to open Roost")
                            .font(.roostBody.weight(.medium))
                            .foregroundStyle(Color.roostForeground)
                        Text("Roost locks automatically every time you leave the app")
                            .font(.roostCaption)
                            .foregroundStyle(Color.roostMutedForeground)
                    }
                    Spacer(minLength: 0)
                    Toggle("", isOn: Binding(
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
                                appLockEnabled = true
                                showDisableConfirm = true
                            }
                        }
                    ))
                    .labelsHidden()
                    .toggleStyle(FigmaSwitchToggleStyle())
                }
                .padding(.vertical, 12)

                if lockManager.hasPIN {
                    Divider().overlay(Color.roostHairline)

                    Button {
                        showPINSetup = true
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.row) {
                            ZStack {
                                Circle()
                                    .fill(Color.roostMuted)
                                    .frame(width: 30, height: 30)
                                Image(systemName: "key.fill")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.roostMutedForeground)
                            }
                            Text("Change PIN")
                                .font(.roostBody.weight(.medium))
                                .foregroundStyle(Color.roostForeground)
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.roostMutedForeground)
                        }
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                if biometricsAvailable && appLockEnabled {
                    Divider().overlay(Color.roostHairline)

                    HStack(spacing: DesignSystem.Spacing.row) {
                        ZStack {
                            Circle()
                                .fill(Color.roostPrimary.opacity(0.08))
                                .frame(width: 30, height: 30)
                            Image(systemName: biometricsLabel == "Face ID" ? "faceid" : "touchid")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.roostPrimary)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Use \(biometricsLabel)")
                                .font(.roostBody.weight(.medium))
                                .foregroundStyle(Color.roostForeground)
                            Text("Unlock Roost with \(biometricsLabel) instead of your PIN")
                                .font(.roostCaption)
                                .foregroundStyle(Color.roostMutedForeground)
                        }

                        Spacer(minLength: 0)

                        Toggle("", isOn: Binding(
                            get: { useBiometrics },
                            set: { newValue in
                                useBiometrics = newValue
                                lockManager.useBiometrics = newValue
                            }
                        ))
                        .labelsHidden()
                        .toggleStyle(FigmaSwitchToggleStyle())
                    }
                    .padding(.vertical, 12)
                    .disabled(!appLockEnabled)
                }
            }
        }
    }

    private func setupBiometrics() {
        let btype = lockManager.biometricType
        biometricsAvailable = btype != .none
        biometricsLabel = btype == .touchID ? "Touch ID" : "Face ID"
    }
}

// MARK: - Disable Lock Sheet

private struct DisableLockPINSheet: View {
    @Environment(AppLockManager.self) private var lockManager
    @Environment(\.dismiss) private var dismiss

    let onSuccess: () -> Void
    let onCancel: () -> Void

    @State private var pin: [Int] = []
    @State private var message = "Enter your PIN to turn off app lock."
    @State private var messageColor = Color.roostMutedForeground
    @State private var countdown = 0
    @State private var timer: Timer?

    private var keypadDisabled: Bool {
        lockManager.isInCooldown || lockManager.requiresReauth
    }

    var body: some View {
        ZStack {
            Color.roostBackground.ignoresSafeArea()

            VStack(spacing: 28) {
                HStack {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostForeground)

                    Spacer()
                }
                .padding(.top, 16)

                VStack(spacing: 10) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(Color.roostPrimary)
                        .frame(width: 76, height: 76)
                        .background(Color.roostPrimary.opacity(0.09), in: Circle())

                    Text("Disable app lock")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color.roostForeground)

                    Text(statusMessage)
                        .font(.roostCaption.weight(.medium))
                        .foregroundStyle(messageColor)
                        .multilineTextAlignment(.center)
                        .frame(minHeight: 34)
                }

                HStack(spacing: 14) {
                    ForEach(0..<6, id: \.self) { index in
                        Circle()
                            .fill(index < pin.count ? Color.roostPrimary : Color.clear)
                            .frame(width: 13, height: 13)
                            .overlay {
                                Circle()
                                    .stroke(index < pin.count ? Color.roostPrimary : Color.roostHairline, lineWidth: 1.4)
                            }
                    }
                }

                keypad

                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled()
        .onAppear {
            refreshCooldown()
            startTimerIfNeeded()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private var statusMessage: String {
        if lockManager.requiresReauth {
            return "Too many failed attempts. Sign in with your email to continue."
        }
        if lockManager.isInCooldown {
            return "Too many attempts — try again in \(countdown) seconds"
        }
        return message
    }

    private var keypad: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(1...3, id: \.self) { column in
                        KeypadButton(number: row * 3 + column, isDisabled: keypadDisabled) {
                            append(row * 3 + column)
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                Color.clear.frame(width: 72, height: 58)
                KeypadButton(number: 0, isDisabled: keypadDisabled) { append(0) }
                KeypadButton(systemImage: "delete.left", isDisabled: keypadDisabled || pin.isEmpty) {
                    delete()
                }
            }
        }
        .opacity(keypadDisabled ? 0.45 : 1)
        .allowsHitTesting(!keypadDisabled)
    }

    private func append(_ digit: Int) {
        guard pin.count < 6, !keypadDisabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        pin.append(digit)
        if pin.count == 6 {
            verify()
        }
    }

    private func delete() {
        guard !pin.isEmpty, !keypadDisabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        pin.removeLast()
    }

    private func verify() {
        let entered = pin.map(String.init).joined()
        pin = []

        switch lockManager.attemptUnlock(pin: entered) {
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onSuccess()
            dismiss()
        case .wrongPIN(let attemptsRemaining):
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            messageColor = attemptsRemaining == 1 ? Color.roostDestructive : Color.roostWarning
            message = attemptsRemaining == 1
                ? "Incorrect PIN — 1 attempt remaining before lockout"
                : "Incorrect PIN — \(attemptsRemaining) attempts remaining"
        case .lockedOut(let duration, _):
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            messageColor = Color.roostDestructive
            countdown = duration
            startTimerIfNeeded()
        case .cooldown(let seconds):
            messageColor = Color.roostDestructive
            countdown = seconds
            startTimerIfNeeded()
        case .requiresReauth:
            messageColor = Color.roostDestructive
            message = "Too many failed attempts. Sign in with your email to continue."
        case .error:
            messageColor = Color.roostDestructive
            message = "PIN unavailable. Set up your PIN again."
        }
    }

    private func refreshCooldown() {
        countdown = lockManager.cooldownSeconds
        if lockManager.isInCooldown {
            messageColor = Color.roostDestructive
        }
    }

    private func startTimerIfNeeded() {
        timer?.invalidate()
        guard lockManager.isInCooldown else {
            timer = nil
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if lockManager.isInCooldown {
                    countdown = lockManager.cooldownSeconds
                } else {
                    self.timer?.invalidate()
                    self.timer = nil
                    countdown = 0
                    messageColor = Color.roostMutedForeground
                    message = "Enter your PIN to turn off app lock."
                }
            }
        }
    }
}
