import SwiftUI

struct PreferencesSettingsView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(SettingsViewModel.self) private var settingsViewModel

    @State private var weekStarts = "monday"
    @State private var timeFormat = "24h"
    @State private var currency = "GBP"
    @State private var dateFormat = "dd/MM/yyyy"

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                RoostSectionSurface(emphasis: .subtle) {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        Text("Calendar")
                            .font(.roostCardTitle)
                            .foregroundStyle(Color.roostForeground)

                        Picker("Week starts", selection: $weekStarts) {
                            Text("Monday").tag("monday")
                            Text("Sunday").tag("sunday")
                        }
                        .pickerStyle(.segmented)
                    }
                }

                RoostSectionSurface(emphasis: .subtle) {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        Text("Formatting")
                            .font(.roostCardTitle)
                            .foregroundStyle(Color.roostForeground)

                        Picker("Time format", selection: $timeFormat) {
                            Text("12 Hour").tag("12h")
                            Text("24 Hour").tag("24h")
                        }
                        .pickerStyle(.segmented)

                        Picker("Currency", selection: $currency) {
                            ForEach(settingsViewModel.currencyOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }

                        Picker("Date format", selection: $dateFormat) {
                            ForEach(settingsViewModel.dateFormatOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .navigationTitle("Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .swipeBackEnabled()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let userId = authManager.currentUser?.id {
                    Button("Save") {
                        Task {
                            await settingsViewModel.savePreferences(
                                userId: userId,
                                weekStarts: weekStarts,
                                timeFormat: timeFormat,
                                currency: currency,
                                dateFormat: dateFormat
                            )
                        }
                    }
                    .tint(.roostPrimary)
                }
            }
        }
        .task(id: authManager.currentUser?.id) {
            if let userId = authManager.currentUser?.id {
                await settingsViewModel.loadPreferences(for: userId)
            }
            syncFromPreferences()
        }
        .onChange(of: settingsViewModel.userPreferences) { _, _ in
            syncFromPreferences()
        }
        .settingsMessageOverlay()
    }

    private func syncFromPreferences() {
        weekStarts = settingsViewModel.userPreferences.weekStarts
        timeFormat = settingsViewModel.userPreferences.timeFormat
        currency = settingsViewModel.userPreferences.currency
        dateFormat = settingsViewModel.userPreferences.dateFormat
    }
}
