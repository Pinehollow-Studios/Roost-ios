import SwiftUI

// MARK: - AddBudgetLineSheet

struct AddBudgetLineSheet: View {

    let sectionId: String
    let sectionLabel: String
    let isFixed: Bool
    let suggestions: [String]
    let currencySymbol: String
    let onSave: (CreateBudgetLine, UUID) async throws -> Void

    @Environment(HomeManager.self) private var homeManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var amountText = ""
    @State private var selectedDay: Int = 1
    @State private var isAnnual = false
    @State private var noteText = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    @FocusState private var nameFocused: Bool

    private var parsedAmount: Decimal {
        Decimal(string: amountText.trimmingCharacters(in: .whitespaces)) ?? 0
    }

    private var monthlyCost: Decimal? {
        guard isAnnual, parsedAmount > 0 else { return nil }
        var result = parsedAmount / 12
        var rounded = Decimal()
        NSDecimalRound(&rounded, &result, 2, .bankers)
        return rounded
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && parsedAmount > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // MARK: Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.system(size: 11, weight: .medium))
                            .tracking(0.8)
                            .foregroundStyle(Color.roostMutedForeground)

                        TextField(isFixed ? "e.g. Rent" : (suggestions.first.map { "e.g. \($0)" } ?? "e.g. Groceries"),
                                  text: $name)
                            .font(.system(size: 15))
                            .focused($nameFocused)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(DesignSystem.Palette.muted.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(nameFocused ? Color.roostPrimary.opacity(0.4) : DesignSystem.Palette.border, lineWidth: 1)
                            )
                            .onSubmit { if canSave { Task { await save() } } }

                        // Suggestion chips
                        if !suggestions.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(suggestions, id: \.self) { s in
                                        Button {
                                            name = s
                                        } label: {
                                            Text(s)
                                                .font(.system(size: 12))
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(name == s
                                                    ? Color.roostPrimary.opacity(0.12)
                                                    : Color(.systemFill))
                                                .foregroundStyle(name == s
                                                    ? Color.roostPrimary
                                                    : Color.roostMutedForeground)
                                                .clipShape(Capsule())
                                                .overlay(
                                                    Capsule()
                                                        .stroke(name == s
                                                            ? Color.roostPrimary.opacity(0.3)
                                                            : DesignSystem.Palette.border.opacity(0.5),
                                                            lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }

                    // MARK: Amount
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isFixed && isAnnual ? "Annual total" : "Monthly amount")
                            .font(.system(size: 11, weight: .medium))
                            .tracking(0.8)
                            .foregroundStyle(Color.roostMutedForeground)

                        HStack(spacing: 0) {
                            Text(currencySymbol)
                                .font(.system(size: 20))
                                .foregroundStyle(Color.roostMutedForeground)
                                .padding(.leading, 14)
                                .padding(.trailing, 4)

                            TextField("0.00", text: $amountText)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 22, weight: .medium))
                                .padding(.vertical, 12)
                                .padding(.trailing, 14)
                        }
                        .background(Color(.systemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        // Annual toggle (fixed only)
                        if isFixed {
                            Toggle(isOn: $isAnnual) {
                                Text("Annual cost — spread monthly")
                                    .font(.system(size: 14))
                            }
                            .tint(Color.roostPrimary)

                            if let monthly = monthlyCost {
                                Text("\(currencySymbol)\(formatDecimal(monthly))/month added to budget")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: 0x9DB19F))
                            }
                        }
                    }

                    // MARK: Day of month (fixed only)
                    if isFixed {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Day it goes out")
                                .font(.system(size: 11, weight: .medium))
                                .tracking(0.8)
                                .foregroundStyle(Color.roostMutedForeground)

                            Text("Goes out on the \(ordinal(selectedDay)) of each month")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.roostMutedForeground)

                            ScrollViewReader { proxy in
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 6) {
                                        ForEach(1...31, id: \.self) { day in
                                            Button {
                                                withAnimation(.easeInOut(duration: 0.15)) {
                                                    selectedDay = day
                                                }
                                            } label: {
                                                Text("\(day)")
                                                    .font(.system(size: 13,
                                                                  weight: selectedDay == day ? .medium : .regular))
                                                    .frame(width: 34, height: 34)
                                                    .background(selectedDay == day
                                                        ? Color.roostPrimary
                                                        : Color(.systemFill))
                                                    .foregroundStyle(selectedDay == day
                                                        ? Color.white
                                                        : Color.roostForeground)
                                                    .clipShape(Circle())
                                            }
                                            .buttonStyle(.plain)
                                            .id(day)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                                .onAppear {
                                    proxy.scrollTo(selectedDay, anchor: .center)
                                }
                            }
                        }
                    }

                    // MARK: Note (optional)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note (optional)")
                            .font(.system(size: 11, weight: .medium))
                            .tracking(0.8)
                            .foregroundStyle(Color.roostMutedForeground)

                        TextField("Add a note", text: $noteText)
                            .font(.system(size: 13))
                            .onChange(of: noteText) { _, v in
                                if v.count > 120 { noteText = String(v.prefix(120)) }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(DesignSystem.Palette.muted.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(DesignSystem.Palette.border, lineWidth: 1)
                            )
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.roostDestructive)
                    }

                    // MARK: Save button
                    Button {
                        Task { await save() }
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            }
                            Text(isSaving ? "Saving…" : "Save")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(canSave ? Color.roostPrimary : Color.roostPrimary.opacity(0.4))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(!canSave || isSaving)
                    .buttonStyle(.plain)
                }
                .padding(DesignSystem.Spacing.page)
            }
            .background(Color.roostBackground.ignoresSafeArea())
            .navigationTitle(isFixed ? "Add fixed cost" : "Add \(sectionLabel.lowercased()) line")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.roostMutedForeground)
                }
            }
            .onAppear {
                nameFocused = true
            }
        }
    }

    private func save() async {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, parsedAmount > 0 else { return }
        guard let homeId = homeManager.homeId else { return }

        isSaving = true
        errorMessage = nil

        let line = CreateBudgetLine(
            homeId: homeId,
            name: trimmedName,
            amount: isFixed && isAnnual ? (monthlyCost ?? parsedAmount) : parsedAmount,
            budgetType: isFixed ? "fixed" : "envelope",
            sectionGroup: sectionId,
            dayOfMonth: isFixed ? selectedDay : nil,
            isAnnual: isFixed && isAnnual,
            annualAmount: isFixed && isAnnual ? parsedAmount : nil,
            rolloverEnabled: !isFixed,
            ownership: "shared",
            member1Percentage: 50,
            note: noteText.trimmingCharacters(in: .whitespaces).isEmpty ? nil : noteText,
            sortOrder: 0,
            isActive: true
        )

        do {
            try await onSave(line, homeId)
            dismiss()
        } catch {
            errorMessage = "Failed to save. Please try again."
        }

        isSaving = false
    }

    private func ordinal(_ n: Int) -> String {
        switch n % 10 {
        case 1 where n != 11: return "\(n)st"
        case 2 where n != 12: return "\(n)nd"
        case 3 where n != 13: return "\(n)rd"
        default: return "\(n)th"
        }
    }

    private func formatDecimal(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
    }
}
