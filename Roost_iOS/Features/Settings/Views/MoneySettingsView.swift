import SwiftUI

struct MoneySettingsView: View {
    @Environment(HomeManager.self) private var homeManager
    @Environment(AuthManager.self) private var authManager
    @Environment(MoneySettingsViewModel.self) private var settingsVM
    @Environment(MemberNamesHelper.self) private var memberNames
    @Environment(ScrambleModeEnvironment.self) private var scramble

    // Income section
    @State private var myIncomeText = ""
    @State private var myIncomeVisible = false
    @State private var partnerIncome: Decimal? = nil
    @State private var householdIncomeTotal: Decimal? = nil
    @State private var incomeSetAt: Date? = nil
    @State private var showSavedConfirmation = false
    @State private var isSavingIncome = false

    // Privacy section
    @State private var scrambleMode = false
    @State private var hideBalances = false

    // Budget preferences section
    @State private var defaultSplit: Double = 50
    @State private var carryForward = "auto"
    @State private var overspendThreshold = 80
    @State private var debounceTask: Task<Void, Never>?

    // Currency section
    @State private var currency = "£"

    private let incomeService = HouseholdIncomeService()
    private var sym: String { currency }

    private var myIncome: Decimal { Decimal(string: myIncomeText.replacingOccurrences(of: ",", with: "")) ?? 0 }
    private var combinedIncome: Decimal {
        if let householdIncomeTotal { return householdIncomeTotal }
        if let partner = partnerIncome { return myIncome + partner }
        return myIncome
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                FigmaBackHeader(title: "Money")
                incomeSection
                privacySection
                budgetSection
                currencySection
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .swipeBackEnabled()
        .task {
            await loadData()
        }
    }

    // MARK: - Section 1: YOUR INCOME

    private var incomeSection: some View {
        RoostSectionSurface(emphasis: .subtle) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("YOUR INCOME")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(Color.roostMutedForeground)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // My income card
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Your monthly take-home pay")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.roostForeground)
                    Text("Only you can see your individual amount. Your combined household income is used across the app.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.roostMutedForeground)

                    HStack {
                        Text(sym)
                            .foregroundStyle(Color.roostMutedForeground)
                        TextField("e.g. 2500", text: $myIncomeText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color.roostForeground)
                    }
                    .padding()
                    .background(Color.roostMuted)
                    .cornerRadius(12)

                    if let setAt = incomeSetAt {
                        Text("Last updated \(setAt.formatted(.dateTime.day().month(.wide).year()))")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.roostMutedForeground)
                    }

                    Button {
                        Task { await saveMyIncome() }
                    } label: {
                        HStack {
                            if isSavingIncome { ProgressView().tint(.white) }
                            Text("Save income")
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(myIncomeText.isEmpty ? Color.roostPrimary.opacity(0.4) : Color.roostPrimary)
                        .cornerRadius(12)
                    }
                    .disabled(myIncomeText.isEmpty || isSavingIncome)

                    if showSavedConfirmation {
                        Text("Saved ✓")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.roostSuccess)
                            .transition(.opacity)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation { showSavedConfirmation = false }
                                }
                            }
                    }
                }

                Divider()

                // Share with partner toggle
                HStack(alignment: .top, spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Share with \(memberNames.names.partner)")
                            .font(.system(size: 14))
                        Text("\(memberNames.names.partner) will be able to see your individual amount in their Settings. You can turn this off at any time.")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.roostMutedForeground)
                    }
                    Toggle("", isOn: $myIncomeVisible)
                        .labelsHidden()
                        .onChange(of: myIncomeVisible) { _, newVal in
                            Task { await saveIncomeVisibility(visible: newVal) }
                        }
                }

                // Partner income (only if I'm sharing)
                if myIncomeVisible {
                    Divider()
                    if let partnerInc = partnerIncome {
                        HStack {
                            Text("\(memberNames.names.partner)'s income")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.roostMutedForeground)
                            Spacer()
                            Text(scramble.format(partnerInc, symbol: sym))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.roostForeground)
                        }
                    } else {
                        Text("\(memberNames.names.partner) hasn't shared their income yet")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.roostMutedForeground)
                    }
                }

                Divider()

                // Combined income
                VStack(alignment: .leading, spacing: 4) {
                    Text("COMBINED HOUSEHOLD")
                        .font(.system(size: 9, weight: .medium))
                        .tracking(1.2)
                        .foregroundStyle(Color.roostMutedForeground)
                    Text(scramble.format(combinedIncome, symbol: sym))
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color.roostForeground)
                    Text("Used across all Money screens")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.roostMutedForeground)
                }
            }
        }
    }

    // MARK: - Section 2: PRIVACY & DISPLAY

    private var privacySection: some View {
        RoostSectionSurface(emphasis: .subtle) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("PRIVACY & DISPLAY")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(Color.roostMutedForeground)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Scramble mode
                HStack(alignment: .top, spacing: 0) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "eye.slash.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.roostWarning)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text("Scramble mode")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color.roostForeground)
                                if scrambleMode {
                                    Text("ON")
                                        .font(.system(size: 10, weight: .medium))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.roostWarning.opacity(0.12))
                                        .foregroundStyle(Color.roostWarning)
                                        .clipShape(Capsule())
                                }
                            }
                            Text("Replace all amounts with ••• when showing Roost to someone. Syncs to both your devices.")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.roostMutedForeground)
                        }
                    }

                    Spacer()

                    Toggle("", isOn: $scrambleMode)
                        .labelsHidden()
                        .onChange(of: scrambleMode) { _, _ in
                            Task {
                                guard let homeId = homeManager.homeId else { return }
                                try? await settingsVM.toggleScrambleMode(homeId: homeId)
                            }
                        }
                }

                Divider()

                // Hide balances
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hide balances on Money home")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.roostForeground)
                        Text("Tap the ring to reveal amounts. Device-only setting.")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.roostMutedForeground)
                    }
                    Spacer()
                    Toggle("", isOn: $hideBalances)
                        .labelsHidden()
                        .onChange(of: hideBalances) { _, newVal in
                            UserDefaults.standard.set(newVal, forKey: "roost-hide-balances")
                        }
                }
            }
        }
    }

    // MARK: - Section 3: BUDGET PREFERENCES

    private var budgetSection: some View {
        RoostSectionSurface(emphasis: .subtle) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("BUDGET PREFERENCES")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(Color.roostMutedForeground)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Default split slider
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Default expense split")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.roostForeground)
                        Text("When you log a shared expense, this is the default split.")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.roostMutedForeground)
                    }

                    HStack(spacing: 8) {
                        MemberAvatar(label: memberNames.names.meInitials, color: memberNames.names.meColour, size: .xs)
                        Text("\(Int(defaultSplit))%")
                            .font(.system(size: 13, weight: .medium))
                            .frame(width: 36)
                        Slider(value: $defaultSplit, in: 0...100, step: 5)
                            .tint(Color.roostPrimary)
                            .onChange(of: defaultSplit) { _, _ in
                                debounceTask?.cancel()
                                debounceTask = Task {
                                    try? await Task.sleep(for: .milliseconds(500))
                                    guard !Task.isCancelled else { return }
                                    guard let homeId = homeManager.homeId else { return }
                                    try? await settingsVM.updateSetting(
                                        \.defaultExpenseSplit,
                                        value: defaultSplit,
                                        homeId: homeId
                                    )
                                }
                            }
                        Text("\(Int(100 - defaultSplit))%")
                            .font(.system(size: 13, weight: .medium))
                            .frame(width: 36)
                        MemberAvatar(label: memberNames.names.partnerInitials, color: memberNames.names.partnerColour, size: .xs)
                    }

                    if Int(defaultSplit) == 50 {
                        Text("Equal split")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.roostSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }

                Divider()

                // Carry-forward
                VStack(alignment: .leading, spacing: 8) {
                    Text("Budget carry-forward")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.roostForeground)
                    Text("When a new month starts, your budget automatically carries forward.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.roostMutedForeground)

                    HStack(spacing: 0) {
                        ForEach([("Automatic", "auto"), ("Manual", "manual")], id: \.1) { label, value in
                            let selected = carryForward == value
                            Button {
                                guard carryForward != value else { return }
                                withAnimation(.easeInOut(duration: 0.18)) { carryForward = value }
                                Task {
                                    guard let homeId = homeManager.homeId else { return }
                                    try? await settingsVM.updateSetting(\.budgetCarryForward, value: value, homeId: homeId)
                                }
                            } label: {
                                Text(label)
                                    .font(.system(size: 13, weight: selected ? .medium : .regular))
                                    .foregroundStyle(selected ? Color.white : Color.roostForeground)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(selected ? Color.roostPrimary : Color.roostMuted)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.roostHairline, lineWidth: 1)
                    )

                    if carryForward == "manual" {
                        Text("You'll need to set up your budget each month manually.")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.roostWarning)
                    }
                }

                Divider()

                // Overspend alerts
                VStack(alignment: .leading, spacing: 8) {
                    Text("Spending alerts")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.roostForeground)
                    Text("Alert when an envelope reaches this percentage of its budget.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.roostMutedForeground)
                    HStack(spacing: 8) {
                        ForEach([50, 60, 70, 80, 90], id: \.self) { pct in
                            Button {
                                overspendThreshold = pct
                                Task {
                                    guard let homeId = homeManager.homeId else { return }
                                    try? await settingsVM.updateSetting(
                                        \.overspendAlertThreshold,
                                        value: pct,
                                        homeId: homeId
                                    )
                                }
                            } label: {
                                Text("\(pct)%")
                                    .font(.system(size: 13, weight: overspendThreshold == pct ? .medium : .regular))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(overspendThreshold == pct ? Color.roostPrimary : Color.roostMuted)
                                    .foregroundStyle(overspendThreshold == pct ? Color.white : Color.roostForeground)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Section 4: CURRENCY

    private var currencySection: some View {
        RoostSectionSurface(emphasis: .subtle) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("CURRENCY")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Picker("Currency", selection: $currency) {
                    Text("£ GBP").tag("£")
                    Text("$ USD").tag("$")
                    Text("€ EUR").tag("€")
                    Text("A$ AUD").tag("A$")
                    Text("CA$ CAD").tag("CA$")
                }
                .pickerStyle(.menu)
                .onChange(of: currency) { _, newVal in
                    Task {
                        guard let homeId = homeManager.homeId else { return }
                        try? await settingsVM.updateSetting(\.currencySymbol, value: newVal, homeId: homeId)
                    }
                }
            }
        }
    }

    // MARK: - Data loading

    private func loadData() async {
        guard let homeId = homeManager.homeId,
              let userId = homeManager.currentUserId else { return }

        // Sync from current member
        if let member = homeManager.currentMember {
            if let income = member.personalIncome {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.minimumFractionDigits = 2
                formatter.maximumFractionDigits = 2
                formatter.decimalSeparator = "."
                myIncomeText = formatter.string(from: income as NSDecimalNumber) ?? "\(income)"
            }
            incomeSetAt = member.incomeSetAt
            myIncomeVisible = member.incomeVisibleToPartner ?? false
        }

        // Total household income is used across Money screens. Individual partner
        // income still respects visibility rules in this settings panel.
        async let total = incomeService.fetchCombinedMemberIncome(homeId: homeId)
        async let partner = incomeService.fetchPartnerIncome(homeId: homeId, currentUserId: userId)
        householdIncomeTotal = try? await total
        partnerIncome = try? await partner

        // Sync settings
        defaultSplit = settingsVM.settings.defaultExpenseSplit
        carryForward = settingsVM.settings.budgetCarryForward
        overspendThreshold = settingsVM.settings.overspendAlertThreshold
        currency = settingsVM.settings.currencySymbol
        scrambleMode = settingsVM.settings.scrambleMode
        hideBalances = UserDefaults.standard.bool(forKey: "roost-hide-balances")
    }

    private func saveMyIncome() async {
        guard let homeId = homeManager.homeId,
              let userId = homeManager.currentUserId else { return }
        let cleaned = myIncomeText.replacingOccurrences(of: sym, with: "").replacingOccurrences(of: ",", with: "")
        guard let amount = Decimal(string: cleaned) else { return }

        isSavingIncome = true
        do {
            try await incomeService.setMyIncome(userId: userId, amount: amount)
            let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
            try await incomeService.syncCombinedIncome(homeId: homeId, month: startOfMonth)
            // Refresh member to get updated incomeSetAt
            await homeManager.refreshCurrentHome()
            incomeSetAt = homeManager.currentMember?.incomeSetAt
            householdIncomeTotal = try? await incomeService.fetchCombinedMemberIncome(homeId: homeId)
            partnerIncome = try? await incomeService.fetchPartnerIncome(homeId: homeId, currentUserId: userId)
            withAnimation { showSavedConfirmation = true }
        } catch {
            // Silently fail — UI stays as-is
        }
        isSavingIncome = false
    }

    private func saveIncomeVisibility(visible: Bool) async {
        guard let homeId = homeManager.homeId,
              let userId = homeManager.currentUserId else { return }
        try? await incomeService.setIncomeVisibility(userId: userId, visible: visible)
        partnerIncome = try? await incomeService.fetchPartnerIncome(homeId: homeId, currentUserId: userId)
    }
}
