import SwiftUI

struct AddShoppingItemSheet: View {
    let suggestedCategories: [String]
    let suggestedQuantities: [String]
    let onAdd: (String, String?, String?) async -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focusedField: Field?

    @State private var name = ""
    @State private var selectedCategory: String?
    @State private var categoryMode: CategoryMode = .automatic
    @State private var isSaving = false
    @State private var hasAppeared = false

    private enum Field {
        case name
    }

    private enum CategoryMode {
        case automatic
        case manual
    }

    private var canSubmit: Bool {
        !previewName.isEmpty && !isSaving
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header
                    .shoppingAddEntrance(at: 0, hasAppeared: hasAppeared, reduceMotion: reduceMotion)

                inputBlock
                    .shoppingAddEntrance(at: 1, hasAppeared: hasAppeared, reduceMotion: reduceMotion)

                categoryBlock
                    .shoppingAddEntrance(at: 2, hasAppeared: hasAppeared, reduceMotion: reduceMotion)

                suggestionsBlock
                    .shoppingAddEntrance(at: 3, hasAppeared: hasAppeared, reduceMotion: reduceMotion)
            }
            .padding(.horizontal, shoppingAddPageInset)
            .padding(.top, DesignSystem.Spacing.screenTop)
            .padding(.bottom, DesignSystem.Spacing.screenBottom + 36)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .scrollDismissesKeyboard(.interactively)
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = nil
        }
        .background(Color.roostBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            NotificationCenter.default.post(name: .roostTabBarHiddenChanged, object: true)
            focusedField = .name
            guard !reduceMotion else {
                hasAppeared = true
                return
            }
            if !hasAppeared {
                withAnimation(.roostSmooth) {
                    hasAppeared = true
                }
            }
        }
        .onDisappear {
            NotificationCenter.default.post(name: .roostTabBarHiddenChanged, object: false)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                    Text("Shopping")
                        .font(.roostLabel)
                }
                .foregroundStyle(shoppingAddPageAccent)
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(shoppingAddPageAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(ShoppingAddPressStyle(reduceMotion: reduceMotion))

            VStack(alignment: .leading, spacing: 7) {
                Text("ADD ITEM")
                    .font(.roostMeta)
                    .foregroundStyle(shoppingAddPageAccent)
                    .tracking(1.0)

                Text("What do you need?")
                    .font(.roostHero)
                    .foregroundStyle(Color.roostForeground)
                    .lineLimit(2)
                    .minimumScaleFactor(0.76)
            }
        }
    }

    private var inputBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            TextField("Milk", text: $name)
                .font(.roostTitle)
                .foregroundStyle(Color.roostForeground)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(false)
                .submitLabel(.done)
                .focused($focusedField, equals: .name)
                .onSubmit {
                    Task { await addAndClose() }
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 70)
                .background(Color.roostCard, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                        .stroke(focusedField == .name ? shoppingAddPageAccent.opacity(0.62) : Color.roostHairline, lineWidth: focusedField == .name ? 1.5 : 1)
                )

            HStack(spacing: 8) {
                Button {
                    Task { await addAndClose() }
                } label: {
                    Text(isSaving ? "Adding" : "Add")
                        .font(.roostLabel)
                    .foregroundStyle(Color.roostCard)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(canSubmit ? Color.roostPrimary : Color.roostMutedForeground.opacity(0.38), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(ShoppingAddPressStyle(reduceMotion: reduceMotion))
                .disabled(!canSubmit)
            }
        }
    }

    @ViewBuilder
    private var suggestionsBlock: some View {
        let matches = matchingSuggestions
        if !matches.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Suggestions")
                    .font(.roostMeta)
                    .foregroundStyle(Color.roostMutedForeground)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(matches, id: \.self) { suggestion in
                            Button {
                                name = suggestion
                                Task { await addAndClose(named: suggestion) }
                            } label: {
                                Text(suggestion)
                                    .font(.roostLabel)
                                    .foregroundStyle(Color.roostForeground)
                                    .padding(.horizontal, 12)
                                    .frame(height: 40)
                                    .background(Color.roostCard, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(Color.roostHairline, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(ShoppingAddPressStyle(reduceMotion: reduceMotion))
                        }
                    }
                }
            }
        }
    }

    private var categoryBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                categoryModeButton(title: "Auto", mode: .automatic)
                categoryModeButton(title: "Choose", mode: .manual)
            }

            if categoryMode == .automatic {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(shoppingAddPageAccent)
                    Text("Roost will categorise this item")
                        .font(.roostCaption)
                        .foregroundStyle(Color.roostMutedForeground)
                }
                .padding(.top, 2)
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2),
                    spacing: 8
                ) {
                    ForEach(categoryOptions, id: \.self) { item in
                        Button {
                            selectedCategory = item
                        } label: {
                            Text(item)
                                .font(.roostMeta)
                                .foregroundStyle(selectedCategory == item ? Color.roostCard : Color.roostForeground)
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                                .background(
                                    selectedCategory == item ? shoppingAddPageAccent : Color.roostCard,
                                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Color.roostHairline, lineWidth: 1)
                                )
                        }
                        .buttonStyle(ShoppingAddPressStyle(reduceMotion: reduceMotion))
                    }
                }
            }
        }
    }

    private func categoryModeButton(title: String, mode: CategoryMode) -> some View {
        Button {
            withAnimation(.roostEaseOut) {
                categoryMode = mode
                if mode == .automatic {
                    selectedCategory = nil
                }
            }
        } label: {
            Text(title)
                .font(.roostLabel)
                .foregroundStyle(categoryMode == mode ? Color.roostCard : Color.roostForeground)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    categoryMode == mode ? shoppingAddPageAccent : Color.roostCard,
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.roostHairline, lineWidth: 1)
                )
        }
        .buttonStyle(ShoppingAddPressStyle(reduceMotion: reduceMotion))
    }

    private func addAndClose() async {
        await addAndClose(named: previewName)
    }

    private func addAndClose(named submittedName: String) async {
        let trimmedName = submittedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !isSaving else { return }
        isSaving = true
        focusedField = nil
        await onAdd(trimmedName, nil, categoryValue)
        isSaving = false
        dismiss()
    }

    private var matchingSuggestions: [String] {
        let query = previewName.lowercased()
        let all = Array(Set(defaultSuggestions + suggestedCategories.flatMap(defaultItems(for:))))
            .sorted()

        guard !query.isEmpty else {
            return Array(defaultSuggestions.prefix(8))
        }

        return all
            .filter { $0.lowercased().contains(query) && $0.caseInsensitiveCompare(previewName) != .orderedSame }
            .prefix(8)
            .map(\.self)
    }

    private var categoryOptions: [String] {
        let base = [
            "Produce", "Dairy", "Bakery", "Meat & Fish",
            "Frozen", "Drinks", "Snacks", "Household", "Personal Care"
        ]
        return Array((base + suggestedCategories).uniqued().prefix(14))
    }

    private var previewName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var categoryValue: String? {
        categoryMode == .manual ? selectedCategory : nil
    }

    private func defaultItems(for category: String) -> [String] {
        switch category.lowercased() {
        case "produce", "fruit", "vegetables":
            return ["Apples", "Bananas", "Avocados", "Carrots", "Lettuce", "Tomatoes"]
        case "dairy":
            return ["Milk", "Butter", "Cheese", "Eggs", "Yoghurt"]
        case "bakery":
            return ["Bread", "Bagels", "Wraps", "Croissants"]
        case "meat & fish", "meat", "fish":
            return ["Chicken", "Mince", "Salmon", "Tuna"]
        case "frozen":
            return ["Frozen peas", "Ice cream", "Frozen berries"]
        case "drinks":
            return ["Coffee", "Tea", "Orange juice", "Sparkling water"]
        case "snacks":
            return ["Crisps", "Chocolate", "Biscuits", "Nuts"]
        case "household":
            return ["Kitchen roll", "Toilet roll", "Bin bags", "Washing up liquid"]
        case "personal care":
            return ["Toothpaste", "Shampoo", "Soap"]
        default:
            return []
        }
    }

    private let defaultSuggestions = [
        "Milk", "Bread", "Eggs", "Bananas", "Apples", "Coffee", "Pasta", "Rice",
        "Chicken", "Cheese", "Kitchen roll", "Toilet roll"
    ]
}

private let shoppingAddPageInset: CGFloat = 12
private let shoppingAddPageAccent = Color.roostShoppingTint

private struct ShoppingAddPressStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(reduceMotion ? nil : DesignSystem.Motion.buttonPress, value: configuration.isPressed)
    }
}

private struct ShoppingAddEntranceModifier: ViewModifier {
    let index: Int
    let hasAppeared: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: reduceMotion || hasAppeared ? 0 : CGFloat(16 + (index * 4)))
            .animation(reduceMotion ? nil : .roostSmooth.delay(Double(index) * 0.04), value: hasAppeared)
    }
}

private extension View {
    func shoppingAddEntrance(at index: Int, hasAppeared: Bool, reduceMotion: Bool) -> some View {
        modifier(ShoppingAddEntranceModifier(index: index, hasAppeared: hasAppeared, reduceMotion: reduceMotion))
    }
}

private extension Array where Element == String {
    func uniqued() -> [String] {
        var seen = Set<String>()
        return filter { item in
            let key = item.lowercased()
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }
}

extension Notification.Name {
    static let roostTabBarHiddenChanged = Notification.Name("roostTabBarHiddenChanged")
}

#Preview {
    NavigationStack {
        AddShoppingItemSheet(
            suggestedCategories: ["Fruit", "Pantry"],
            suggestedQuantities: ["1", "2", "Weekly"]
        ) { _, _, _ in }
    }
}
