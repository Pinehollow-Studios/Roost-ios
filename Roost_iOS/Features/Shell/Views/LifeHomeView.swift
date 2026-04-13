import SwiftUI

struct LifeHomeView: View {
    private enum Section: String, CaseIterable, Identifiable {
        case chores = "Chores"
        case calendar = "Calendar"

        var id: String { rawValue }
    }

    @State private var selection: Section = .chores

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                picker

                Group {
                    switch selection {
                    case .chores:
                        ChoresView(embeddedInParentScroll: true)
                    case .calendar:
                        CalendarView(embeddedInParentScroll: true)
                    }
                }

                pinboardCard
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
            .padding(.bottom, 124)
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .navigationTitle("Plan")
        .navigationBarTitleDisplayMode(.large)
    }

    private var picker: some View {
        Picker("Life section", selection: $selection) {
            ForEach(Section.allCases) { section in
                Text(section.rawValue).tag(section)
            }
        }
        .pickerStyle(.segmented)
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: RoostTheme.controlCornerRadius, style: .continuous)
                .fill(Color.roostInput)
        )
    }

    private var pinboardCard: some View {
        RoostSectionSurface(emphasis: .subtle) {
            HStack(spacing: Spacing.md) {
                RoostIconBadge(systemImage: "pin.fill", tint: .roostSecondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Pinboard")
                        .font(.roostLabel)
                        .foregroundStyle(Color.roostForeground)
                    Text("Shared notes, reminders, and little things for both of you.")
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                }

                Spacer(minLength: 0)

                RoostInlineBadge(title: "Coming soon", tint: .roostMutedForeground)
            }
        }
    }
}

#Preview {
    NavigationStack {
        LifeHomeView()
            .environment(HomeManager.previewDashboard())
            .environment(SettingsViewModel())
    }
}
