import SwiftUI
import Combine
import LocalAuthentication

struct LockScreenView: View {
    @Environment(AppLockManager.self) private var lockManager

    @State private var enteredPIN: [Int] = []
    @State private var shakeOffset: CGFloat = 0
    @State private var justEntered = false
    @State private var countdown: Int = 0
    @State private var biometricsAvailable = false
    @State private var biometricsIcon = "faceid"
    @State private var biometricsLabel = "Use Face ID"

    var body: some View {
        ZStack {
            Color.roostBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                RoostLogoMark(size: 72, cornerRadius: 16)
                    .padding(.bottom, 12)

                Text("Roost")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(Color(hex: 0x3D3229))

                Text("Enter your PIN to continue")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                    .padding(.bottom, 32)

                // PIN dots
                HStack(spacing: 16) {
                    ForEach(0..<6, id: \.self) { index in
                        Circle()
                            .fill(index < enteredPIN.count ? Color(hex: 0xD4795E) : Color.clear)
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: 0xD4795E).opacity(0.4), lineWidth: 1.5)
                            )
                            .frame(width: 14, height: 14)
                            .scaleEffect(index == enteredPIN.count - 1 && justEntered ? 1.2 : 1.0)
                            .animation(.spring(duration: 0.15), value: justEntered)
                    }
                }
                .offset(x: shakeOffset)

                // Biometrics button
                if biometricsAvailable && lockManager.useBiometrics {
                    Button(action: attemptBiometrics) {
                        VStack(spacing: 4) {
                            Image(systemName: biometricsIcon)
                                .font(.system(size: 28))
                            Text(biometricsLabel)
                                .font(.system(size: 12))
                        }
                    }
                    .foregroundStyle(Color(hex: 0x3D3229).opacity(0.6))
                    .padding(.top, 24)
                }

                // Cooldown message
                if let cooldown = lockManager.cooldownUntil, cooldown > Date() {
                    Text("Too many attempts. Try again in \(countdown)s.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: 0x854F0B))
                        .multilineTextAlignment(.center)
                        .padding(.top, 12)
                        .padding(.horizontal, 32)
                }

                Spacer()

                keypad
                    .padding(.bottom, 48)
            }
            .padding(.horizontal, 24)
        }
        .task {
            setupBiometrics()
            if lockManager.useBiometrics && biometricsAvailable {
                _ = await lockManager.unlockWithBiometrics()
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            updateCountdown()
        }
    }

    private var keypad: some View {
        VStack(spacing: 8) {
            ForEach([[1, 2, 3], [4, 5, 6], [7, 8, 9]], id: \.self) { row in
                HStack(spacing: 16) {
                    ForEach(row, id: \.self) { num in
                        KeypadButton(number: num) {
                            appendDigit(num)
                        }
                    }
                }
            }
            HStack(spacing: 16) {
                Color.clear.frame(width: 72, height: 72)
                KeypadButton(number: 0) {
                    appendDigit(0)
                }
                KeypadButton(icon: "delete.left") {
                    deleteLastDigit()
                }
            }
        }
    }

    private func setupBiometrics() {
        biometricsAvailable = lockManager.biometricsAvailable()
        let btype = lockManager.biometricType()
        switch btype {
        case .faceID:
            biometricsIcon = "faceid"
            biometricsLabel = "Use Face ID"
        case .touchID:
            biometricsIcon = "touchid"
            biometricsLabel = "Use Touch ID"
        default:
            biometricsAvailable = false
        }
    }

    private func updateCountdown() {
        guard let cooldown = lockManager.cooldownUntil else {
            countdown = 0
            return
        }
        countdown = max(0, Int(cooldown.timeIntervalSinceNow.rounded(.up)))
    }

    private func appendDigit(_ digit: Int) {
        guard enteredPIN.count < 6 else { return }
        if let cooldown = lockManager.cooldownUntil, cooldown > Date() { return }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        justEntered = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            justEntered = false
        }

        enteredPIN.append(digit)

        if enteredPIN.count == 6 {
            attemptUnlock()
        }
    }

    private func deleteLastDigit() {
        guard !enteredPIN.isEmpty else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        enteredPIN.removeLast()
    }

    private func attemptUnlock() {
        let pin = enteredPIN.map(String.init).joined()
        let success = lockManager.unlock(pin: pin)
        if success {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)) {
                shakeOffset = 10
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.none) { shakeOffset = 0 }
                enteredPIN = []
            }
        }
    }

    private func attemptBiometrics() {
        Task {
            _ = await lockManager.unlockWithBiometrics()
        }
    }
}

// Shared by LockScreenView and PINSetupView
struct KeypadButton: View {
    var number: Int? = nil
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(hex: 0xF2EBE0))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(hex: 0x3D3229).opacity(0.12), lineWidth: 0.5)
                    )
                if let number {
                    Text("\(number)")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(Color(hex: 0x3D3229))
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(Color(hex: 0x3D3229))
                }
            }
            .frame(width: 72, height: 72)
        }
        .buttonStyle(KeypadButtonStyle())
    }
}

private struct KeypadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(duration: 0.1), value: configuration.isPressed)
    }
}
