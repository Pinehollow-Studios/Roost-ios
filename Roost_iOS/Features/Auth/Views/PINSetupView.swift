import SwiftUI

struct PINSetupView: View {
    @Environment(AppLockManager.self) private var lockManager
    @Environment(\.dismiss) private var dismiss

    var onCancel: (() -> Void)? = nil

    @State private var step: Step = .choose
    @State private var firstPIN: [Int] = []
    @State private var secondPIN: [Int] = []
    @State private var shakeOffset: CGFloat = 0
    @State private var justEntered = false
    @State private var mismatchError = false

    enum Step { case choose, confirm, success }

    private var currentPIN: [Int] {
        step == .choose ? firstPIN : secondPIN
    }

    var body: some View {
        ZStack {
            Color.roostBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation header
                HStack {
                    if step == .confirm {
                        Button("Back") {
                            secondPIN = []
                            mismatchError = false
                            step = .choose
                        }
                        .foregroundStyle(Color(hex: 0x3D3229))
                    }
                    Spacer()
                    if step == .choose {
                        Button("Cancel") {
                            onCancel?()
                            dismiss()
                        }
                        .foregroundStyle(Color(hex: 0x3D3229))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .frame(height: 44)

                Spacer()

                if step == .success {
                    successContent
                } else {
                    entryContent
                }

                Spacer()

                if step != .success {
                    keypad
                        .padding(.bottom, 48)
                }
            }
        }
        .interactiveDismissDisabled(step == .choose || step == .confirm)
    }

    private var entryContent: some View {
        VStack(spacing: 0) {
            Text(step == .choose ? "Create your PIN" : "Confirm your PIN")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Color(hex: 0x3D3229))
                .padding(.bottom, 8)

            Text(step == .choose
                 ? "Choose a 6-digit PIN to protect your Roost data."
                 : "Enter your PIN again.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)

            // PIN dots
            HStack(spacing: 16) {
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(index < currentPIN.count ? Color(hex: 0xD4795E) : Color.clear)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: 0xD4795E).opacity(0.4), lineWidth: 1.5)
                        )
                        .frame(width: 14, height: 14)
                        .scaleEffect(index == currentPIN.count - 1 && justEntered ? 1.2 : 1.0)
                        .animation(.spring(duration: 0.15), value: justEntered)
                }
            }
            .offset(x: shakeOffset)

            if mismatchError {
                Text("PINs don't match — try again")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.roostDestructive)
                    .padding(.top, 12)
            }
        }
    }

    private var successContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color(hex: 0x9DB19F))
            Text("PIN set")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color(hex: 0x3D3229))
            Text("Roost will lock when you close or step away.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .onAppear {
            lockManager.setupPIN(firstPIN.map(String.init).joined())
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        }
    }

    private var keypad: some View {
        VStack(spacing: 8) {
            ForEach([[1, 2, 3], [4, 5, 6], [7, 8, 9]], id: \.self) { row in
                HStack(spacing: 16) {
                    ForEach(row, id: \.self) { num in
                        KeypadButton(number: num) { appendDigit(num) }
                    }
                }
            }
            HStack(spacing: 16) {
                Color.clear.frame(width: 72, height: 72)
                KeypadButton(number: 0) { appendDigit(0) }
                KeypadButton(icon: "delete.left") { deleteLastDigit() }
            }
        }
    }

    private func appendDigit(_ digit: Int) {
        guard currentPIN.count < 6 else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        justEntered = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { justEntered = false }

        if step == .choose {
            firstPIN.append(digit)
            if firstPIN.count == 6 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    step = .confirm
                }
            }
        } else {
            secondPIN.append(digit)
            if secondPIN.count == 6 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    validatePINs()
                }
            }
        }
    }

    private func deleteLastDigit() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if step == .choose {
            if !firstPIN.isEmpty { firstPIN.removeLast() }
        } else {
            if !secondPIN.isEmpty { secondPIN.removeLast() }
        }
    }

    private func validatePINs() {
        let p1 = firstPIN.map(String.init).joined()
        let p2 = secondPIN.map(String.init).joined()
        if p1 == p2 {
            step = .success
        } else {
            mismatchError = true
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)) {
                shakeOffset = 10
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.none) { shakeOffset = 0 }
                mismatchError = false
                firstPIN = []
                secondPIN = []
                step = .choose
            }
        }
    }
}
