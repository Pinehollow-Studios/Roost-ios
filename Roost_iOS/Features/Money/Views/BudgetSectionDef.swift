import SwiftUI

// MARK: - BudgetSectionDef

struct BudgetSectionDef: Identifiable {
    let id: String
    let label: String
    let isFixed: Bool

    var headerBorderColour: Color {
        isFixed ? Color.roostPrimary : Color.roostSecondary
    }
    var headerBgColour: Color {
        isFixed ? Color.roostPrimary.opacity(0.10) : Color.roostSecondary.opacity(0.10)
    }
    var allocationColour: Color {
        switch id {
        case "housing-bills":         return Color(hex: 0xD4795E) // terracotta
        case "subscriptions-leisure": return Color(hex: 0xE6A563) // warm amber
        case "transport":             return Color(hex: 0x337DD6) // money blue
        case "food-drink":            return Color(hex: 0x7FA087) // sage-green
        case "household":             return Color(hex: 0x9DB19F) // sage
        case "personal":              return Color(hex: 0xB88B7E) // warm brown
        case "savings":               return Color(hex: 0x6B8FAF) // muted slate-blue
        default:                      return Color.roostMutedForeground
        }
    }
    var sfSymbol: String {
        switch id {
        case "housing-bills":         return "house.fill"
        case "subscriptions-leisure": return "sparkles"
        case "transport":             return "car.fill"
        case "food-drink":            return "fork.knife"
        case "household":             return "cart.fill"
        case "personal":              return "person.fill"
        case "savings":               return "banknote.fill"
        default:                      return "square.fill"
        }
    }
    var suggestions: [String] {
        switch id {
        case "housing-bills":         return ["Rent", "Mortgage", "Council Tax", "Gas & Electricity", "Water", "Broadband", "Contents Insurance", "TV Licence"]
        case "subscriptions-leisure": return ["Netflix", "Spotify", "Disney+", "Amazon Prime", "Gym", "Game Pass", "iCloud", "Other subscriptions"]
        case "transport":             return ["Public transport", "Fuel", "Car insurance", "Parking", "Taxi/Uber", "Rail season ticket"]
        case "food-drink":            return ["Groceries", "Eating out", "Takeaways", "Coffee & cafés", "Work lunches"]
        case "household":             return ["Cleaning & toiletries", "Small home items", "Household repairs"]
        case "personal":              return ["Personal spending", "Clothing", "Haircuts", "Gifts", "Health & wellbeing"]
        case "savings":               return ["Emergency fund", "Holiday fund", "ISA savings", "Other savings"]
        default:                      return []
        }
    }
    static let all: [BudgetSectionDef] = [
        .init(id: "housing-bills",         label: "Housing & bills",         isFixed: true),
        .init(id: "subscriptions-leisure", label: "Subscriptions & leisure", isFixed: true),
        .init(id: "transport",             label: "Transport",                isFixed: true),
        .init(id: "food-drink",            label: "Food & drink",             isFixed: false),
        .init(id: "household",             label: "Household",                isFixed: false),
        .init(id: "personal",              label: "Personal",                 isFixed: false),
        .init(id: "savings",               label: "Savings allocation",       isFixed: false),
    ]
}
