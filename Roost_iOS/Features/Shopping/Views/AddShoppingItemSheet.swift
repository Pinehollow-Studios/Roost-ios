import SwiftUI

struct AddShoppingItemSheet: View {
    let suggestedCategories: [String]
    let suggestedQuantities: [String]
    let onAdd: (String, String?, String?) async -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var name = ""
    @State private var quantity = ""
    @State private var category = ""
    @State private var isSaving = false
    @State private var hasAppeared = false

    private var canSubmit: Bool {
        !previewName.isEmpty && !isSaving
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    RoostSheetHeader(
                        title: "Add Item",
                        subtitle: "Capture something quickly and keep it grouped with the rest of the list."
                    ) {
                        dismiss()
                    }

                    RoostAddSection(
                        title: "Item",
                        helper: "Use the same label you want to see on the shared list."
                    ) {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            RoostTextField(title: "e.g. Milk", text: $name)

                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                RoostTextField(title: "Quantity if useful", text: $quantity)

                                if !suggestedQuantities.isEmpty {
                                    chipRow(items: suggestedQuantities, selection: $quantity)
                                }
                            }
                        }
                    }
                    .sheetEntrance(at: 0, hasAppeared: hasAppeared, reduceMotion: reduceMotion)

                    RoostAddSection(
                        title: "Category",
                        helper: "Taken from the categories already in your home."
                    ) {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            RoostTextField(title: "Optional category", text: $category)

                            if !suggestedCategories.isEmpty {
                                LazyVGrid(
                                    columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 3),
                                    spacing: Spacing.sm
                                ) {
                                    ForEach(suggestedCategories, id: \.self) { item in
                                        RoostAddChoiceChip(title: item, isSelected: category == item) {
                                            category = item
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .sheetEntrance(at: 1, hasAppeared: hasAppeared, reduceMotion: reduceMotion)

                    RoostAddPreviewCard {
                        ShoppingItemRow(
                            item: ShoppingItem(
                                id: UUID(),
                                homeID: UUID(),
                                name: previewName.isEmpty ? "Your item" : previewName,
                                quantity: quantityValue,
                                category: categoryValue,
                                checked: false,
                                addedBy: nil,
                                checkedBy: nil,
                                createdAt: .now,
                                updatedAt: nil
                            ),
                            addedByName: nil
                        ) {}
                        .disabled(true)
                    }
                    .sheetEntrance(at: 2, hasAppeared: hasAppeared, reduceMotion: reduceMotion)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                .padding(.bottom, 120)
            }
            .roostDisableVerticalBounce()
            .roostAddDismissOnPullDown {
                dismiss()
            }
            .background(Color.roostBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                RoostAddBottomBar(
                    actionTitle: "Add item",
                    isSaving: isSaving,
                    isDisabled: !canSubmit
                ) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Shopping list")
                            .font(.roostMeta)
                            .foregroundStyle(Color.roostMutedForeground)
                        Text(previewName.isEmpty ? "Waiting for an item" : previewName)
                            .font(.roostLabel)
                            .foregroundStyle(Color.roostForeground)
                            .lineLimit(1)
                    }
                } action: {
                    Task {
                        isSaving = true
                        await onAdd(previewName, quantityValue, categoryValue)
                        isSaving = false
                        dismiss()
                    }
                }
            }
            .task {
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
        }
    }

    private func chipRow(items: [String], selection: Binding<String>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(items, id: \.self) { item in
                    RoostAddCapsuleChip(title: item, isSelected: selection.wrappedValue == item) {
                        selection.wrappedValue = item
                    }
                }
            }
        }
    }

    private var previewName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var quantityValue: String? {
        let trimmed = quantity.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var categoryValue: String? {
        let trimmed = category.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private struct SheetEntranceModifier: ViewModifier {
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
    func sheetEntrance(at index: Int, hasAppeared: Bool, reduceMotion: Bool) -> some View {
        modifier(SheetEntranceModifier(index: index, hasAppeared: hasAppeared, reduceMotion: reduceMotion))
    }
}

#Preview {
    AddShoppingItemSheet(
        suggestedCategories: ["Fruit", "Pantry"],
        suggestedQuantities: ["1", "2", "Weekly"]
    ) { _, _, _ in }
}
