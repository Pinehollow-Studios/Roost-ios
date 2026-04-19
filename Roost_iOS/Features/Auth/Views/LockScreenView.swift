import SwiftUI
import UIKit

struct LockScreenView: View {
    @Environment(AppLockManager.self) private var lockManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @State private var enteredPIN = ""
    @State private var feedback = "Enter your PIN"
    @State private var feedbackTone: FeedbackTone = .neutral
    @State private var countdown = 0
    @State private var cooldownTimer: Timer?
    @State private var biometricAttemptedToken: Int?
    @State private var shieldPulse = false
    @State private var isSigningOut = false
    @State private var reauthError: String?

    private let authService = AuthService()

    private var keypadDisabled: Bool {
        lockManager.isInCooldown || lockManager.requiresReauth || lockManager.isAuthenticating
    }

    var body: some View {
        ZStack {
            // Same midnight-to-dawn gradient as AuthLoadingView — the
            // PIN → loading transition is seamless because the background never changes.
            LinearGradient(
                stops: [
                    .init(color: Color(hex: 0x0F0D0B), location: 0.0),
                    .init(color: Color(hex: 0x1A1410), location: 0.4),
                    .init(color: Color(hex: 0x2A1A12), location: 0.75),
                    .init(color: Color(hex: 0xD4795E), location: 1.0),
                ],
                startPoint: UnitPoint(x: 0.5, y: -0.08),
                endPoint: UnitPoint(x: 0.5, y: 1.0)
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer(minLength: 28)

                header

                if lockManager.requiresReauth {
                    reauthPanel
                } else {
                    pinPanel
                }

                Spacer(minLength: 18)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.xl)
        }
        .preferredColorScheme(.dark)
        .background(_SecureTextField().frame(width: 0, height: 0))
        .onAppear {
            preventScreenshotWindowState()
            refreshCooldownState()
            startCooldownTimerIfNeeded()
        }
        .onDisappear {
            cooldownTimer?.invalidate()
            cooldownTimer = nil
        }
        .task(id: lockManager.biometricPromptToken) {
            await attemptBiometricsIfQueued()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task { await attemptBiometricsIfQueued() }
        }
        .onChange(of: lockManager.lockoutUntil) { _, _ in
            refreshCooldownState()
            startCooldownTimerIfNeeded()
        }
    }

    private var header: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(Color.roostPrimary.opacity(0.16), lineWidth: 1)
                    .frame(width: 112, height: 112)
                    .scaleEffect(reduceMotion ? 1 : (shieldPulse ? 1.08 : 0.96))
                    .opacity(reduceMotion ? 1 : (shieldPulse ? 0.45 : 0.9))

                Circle()
                    .fill(Color.roostCard)
                    .frame(width: 82, height: 82)
                    .overlay {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 34, weight: .medium))
                            .foregroundStyle(Color.roostPrimary)
                    }
                    .shadow(color: Color.roostPrimary.opacity(0.12), radius: 18, y: 8)
            }
            .onAppear {
                guard !reduceMotion else { return }
                shieldPulse = true
            }
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 1.35).repeatForever(autoreverses: true),
                value: shieldPulse
            )

            VStack(spacing: 8) {
                Text("Roost is locked")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(Color.roostForeground)

                Text("Unlock to access your household and financial data.")
                    .font(.roostBody)
                    .foregroundStyle(Color.roostMutedForeground)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var pinPanel: some View {
        VStack(spacing: 24) {
            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    ForEach(0..<6, id: \.self) { index in
                        Circle()
                            .fill(index < enteredPIN.count ? Color.roostPrimary : Color.clear)
                            .frame(width: 14, height: 14)
                            .overlay {
                                Circle()
                                    .stroke(
                                        index < enteredPIN.count ? Color.roostPrimary : Color.roostHairline,
                                        lineWidth: 1.5
                                    )
                            }
                    }
                }
                .accessibilityLabel("\(enteredPIN.count) of 6 PIN digits entered")

                Text(statusText)
                    .font(.roostCaption.weight(.medium))
                    .foregroundStyle(feedbackColor)
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 34)
                    .contentTransition(.opacity)
            }

            keypad

            if lockManager.useBiometrics && lockManager.biometricType != .none && !lockManager.isInCooldown {
                Button {
                    Task { await attemptBiometricsManual() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: lockManager.biometricType == .faceID ? "faceid" : "touchid")
                        Text(lockManager.biometricType == .faceID ? "Use Face ID" : "Use Touch ID")
                    }
                    .font(.roostLabel)
                    .foregroundStyle(Color.roostPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(Color.roostPrimary.opacity(0.09), in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(lockManager.isAuthenticating)
            }
        }
        .padding(.top, 8)
    }

    private var keypad: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(1...3, id: \.self) { column in
                        KeypadButton(number: row * 3 + column, isDisabled: keypadDisabled) {
                            appendDigit(row * 3 + column)
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                Color.clear
                    .frame(width: 72, height: 58)

                KeypadButton(number: 0, isDisabled: keypadDisabled) {
                    appendDigit(0)
                }

                KeypadButton(systemImage: "delete.left", isDisabled: keypadDisabled || enteredPIN.isEmpty) {
                    deleteDigit()
                }
            }
        }
        .opacity(keypadDisabled ? 0.45 : 1)
        .allowsHitTesting(!keypadDisabled)
    }

    private var reauthPanel: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(Color.roostDestructive)

            VStack(spacing: 8) {
                Text("Too many failed attempts")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.roostForeground)

                Text("For your security, please sign in with your email to continue.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.roostMutedForeground)
                    .multilineTextAlignment(.center)
            }

            if let reauthError {
                Text(reauthError)
                    .font(.roostCaption)
                    .foregroundStyle(Color.roostDestructive)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await signOutForReauth() }
            } label: {
                HStack {
                    Text(isSigningOut ? "Signing out..." : "Sign in with email")
                    if isSigningOut {
                        ProgressView()
                            .tint(.white)
                    }
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color.roostPrimary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isSigningOut)
        }
        .padding(22)
        .background(Color.roostCard, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.roostHairline, lineWidth: 1)
        )
    }

    private var statusText: String {
        if lockManager.isInCooldown {
            return countdown > 60
                ? "Too many attempts — try again in \(formattedCooldown(countdown))"
                : "Too many attempts — locked for \(countdown) seconds"
        }

        return feedback
    }

    private var feedbackColor: Color {
        switch feedbackTone {
        case .neutral:
            return Color.roostMutedForeground
        case .warning:
            return Color.roostWarning
        case .error:
            return Color.roostDestructive
        }
    }

    private func appendDigit(_ digit: Int) {
        guard !keypadDisabled, enteredPIN.count < 6 else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        enteredPIN.append(String(digit))

        if enteredPIN.count == 6 {
            verifyPIN()
        }
    }

    private func deleteDigit() {
        guard !keypadDisabled, !enteredPIN.isEmpty else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        enteredPIN.removeLast()
    }

    private func verifyPIN() {
        let pin = enteredPIN
        enteredPIN = ""

        switch lockManager.attemptUnlock(pin: pin) {
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .wrongPIN(let attemptsRemaining):
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            feedbackTone = attemptsRemaining == 1 ? .error : .warning
            feedback = attemptsRemaining == 1
                ? "Incorrect PIN — 1 attempt remaining before lockout"
                : "Incorrect PIN — \(attemptsRemaining) attempts remaining"
        case .lockedOut(let duration, _):
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            feedbackTone = .error
            feedback = "Too many attempts — locked for \(formattedCooldown(duration))"
            refreshCooldownState()
            startCooldownTimerIfNeeded()
        case .cooldown(let seconds):
            feedbackTone = .error
            countdown = seconds
            feedback = "Too many attempts — locked for \(formattedCooldown(seconds))"
            startCooldownTimerIfNeeded()
        case .requiresReauth:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            feedbackTone = .error
            feedback = "Too many failed attempts. Sign in with your email to continue."
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            feedbackTone = .error
            feedback = "PIN unavailable. Set up your PIN again from Security."
        }
    }

    private func attemptBiometricsIfQueued() async {
        guard scenePhase == .active else { return }
        let token = lockManager.biometricPromptToken
        guard biometricAttemptedToken != token else { return }
        biometricAttemptedToken = token
        await attemptBiometrics()
    }

    private func attemptBiometricsManual() async {
        await attemptBiometrics()
    }

    private func attemptBiometrics() async {
        guard !lockManager.isAuthenticating else { return }
        guard lockManager.useBiometrics, !lockManager.isInCooldown, !lockManager.requiresReauth else { return }

        let result = await lockManager.attemptBiometricUnlock()
        switch result {
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .failed:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            feedbackTone = .warning
            feedback = "Face ID did not unlock Roost. Enter your PIN."
        case .cancelled, .fallbackToPIN, .notAvailable:
            feedbackTone = .neutral
            feedback = "Enter your PIN"
        }
    }

    private func refreshCooldownState() {
        countdown = lockManager.cooldownSeconds
        if lockManager.isInCooldown {
            feedbackTone = .error
        }
    }

    private func startCooldownTimerIfNeeded() {
        cooldownTimer?.invalidate()
        guard lockManager.isInCooldown else {
            cooldownTimer = nil
            countdown = 0
            return
        }

        countdown = lockManager.cooldownSeconds
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if !lockManager.isInCooldown {
                    cooldownTimer?.invalidate()
                    cooldownTimer = nil
                    countdown = 0
                    feedbackTone = .neutral
                    feedback = "Enter your PIN"
                } else {
                    countdown = lockManager.cooldownSeconds
                }
            }
        }
    }

    private func formattedCooldown(_ seconds: Int) -> String {
        if seconds >= 60 {
            let minutes = max(1, Int(ceil(Double(seconds) / 60.0)))
            return minutes == 1 ? "1 minute" : "\(minutes) minutes"
        }

        return "\(seconds) seconds"
    }

    private func signOutForReauth() async {
        isSigningOut = true
        reauthError = nil

        do {
            try await authService.signOut()
            lockManager.resetLockoutForReauth()
        } catch {
            reauthError = "Could not start email sign-in. Try again."
        }

        isSigningOut = false
    }

    private func preventScreenshotWindowState() {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first

        window?.isHidden = false
    }
}

private enum FeedbackTone {
    case neutral
    case warning
    case error
}

// Shared by LockScreenView and PINSetupView.
struct KeypadButton: View {
    let label: String
    let systemImage: String?
    var isDisabled = false
    let action: () -> Void

    init(number: Int, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.label = "\(number)"
        self.systemImage = nil
        self.isDisabled = isDisabled
        self.action = action
    }

    init(systemImage: String, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.label = ""
        self.systemImage = systemImage
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.roostCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.roostHairline, lineWidth: 1)
                    )

                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.roostForeground)
                } else {
                    Text(label)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(Color.roostForeground)
                }
            }
            .frame(width: 72, height: 58)
            .opacity(isDisabled ? 0.5 : 1)
        }
        .buttonStyle(KeypadButtonStyle())
        .disabled(isDisabled)
    }
}

struct KeypadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(DesignSystem.Motion.buttonPress, value: configuration.isPressed)
    }
}

struct SecurePillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(DesignSystem.Motion.buttonPress, value: configuration.isPressed)
    }
}

struct SecureLoginLoadingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pulse = false
    @State private var rotatePrimary = false
    @State private var rotateSecondary = false

    var body: some View {
        ZStack {
            Color.roostBackground.ignoresSafeArea()

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .stroke(Color.roostPrimary.opacity(0.14), lineWidth: 1)
                        .frame(width: 128, height: 128)
                        .scaleEffect(reduceMotion ? 1 : (pulse ? 1.10 : 0.94))
                        .opacity(reduceMotion ? 0.8 : (pulse ? 0.34 : 0.82))

                    Circle()
                        .trim(from: 0.06, to: 0.32)
                        .stroke(
                            Color.roostPrimary.opacity(0.72),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 112, height: 112)
                        .rotationEffect(.degrees(rotatePrimary ? 360 : 0))

                    Circle()
                        .trim(from: 0.56, to: 0.80)
                        .stroke(
                            Color.roostSecondary.opacity(0.62),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 94, height: 94)
                        .rotationEffect(.degrees(rotateSecondary ? -360 : 0))

                    Circle()
                        .fill(Color.roostCard)
                        .frame(width: 76, height: 76)
                        .overlay {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundStyle(Color.roostPrimary)
                        }
                        .shadow(color: Color.roostPrimary.opacity(0.14), radius: pulse ? 20 : 10, y: pulse ? 10 : 4)
                }

                VStack(spacing: 8) {
                    Text("Loading...")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.roostForeground)

                    Text("Securing your data")
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                }
            }
        }
        .background(_SecureTextField().frame(width: 0, height: 0))
        .onAppear {
            guard !reduceMotion else { return }
            pulse = true
            rotatePrimary = true
            rotateSecondary = true
        }
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 1.25).repeatForever(autoreverses: true),
            value: pulse
        )
        .animation(
            reduceMotion ? nil : .linear(duration: 1.05).repeatForever(autoreverses: false),
            value: rotatePrimary
        )
        .animation(
            reduceMotion ? nil : .linear(duration: 1.8).repeatForever(autoreverses: false),
            value: rotateSecondary
        )
    }
}

struct _SecureTextField: UIViewRepresentable {
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.isSecureTextEntry = true
        textField.isUserInteractionEnabled = false
        textField.alpha = 0.01
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.isSecureTextEntry = true
    }
}
