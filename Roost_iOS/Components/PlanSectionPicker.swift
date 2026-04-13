import SwiftUI

struct PlanSectionPicker: View {
    enum Section: String, CaseIterable, Identifiable {
        case chores = "Chores"
        case calendar = "Calendar"
        case pinboard = "Pinboard"

        var id: String { rawValue }
    }

    let selected: Section
    var onSelect: ((Section) -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Section.allCases) { section in
                Button {
                    onSelect?(section)
                } label: {
                    Text(section.rawValue)
                        .font(.roostBody.weight(.medium))
                        .foregroundStyle(selected == section ? Color.roostCard : Color.roostMutedForeground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            Capsule()
                                .fill(selected == section ? Color.roostPrimary : .clear)
                        )
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color.roostMuted)
        )
    }
}
