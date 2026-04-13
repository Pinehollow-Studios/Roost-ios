import Foundation
import SwiftUI

struct Budget: Codable, Identifiable, Hashable {
    let id: UUID
    var homeID: UUID
    var category: String
    var amount: Decimal
    var month: Date

    enum CodingKeys: String, CodingKey {
        case id
        case homeID = "home_id"
        case category
        case amount
        case month
    }

    init(id: UUID, homeID: UUID, category: String, amount: Decimal, month: Date) {
        self.id = id
        self.homeID = homeID
        self.category = category
        self.amount = amount
        self.month = month
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        homeID = try container.decode(UUID.self, forKey: .homeID)
        category = try container.decode(String.self, forKey: .category)
        amount = try container.decode(Decimal.self, forKey: .amount)
        month = try container.decodeDateOnly(forKey: .month)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(homeID, forKey: .homeID)
        try container.encode(category, forKey: .category)
        try container.encode(amount, forKey: .amount)
        try container.encodeDateOnly(month, forKey: .month)
    }
}

struct UpsertBudget: Codable, Hashable {
    var homeID: UUID
    var category: String
    var amount: Decimal
    var month: Date

    enum CodingKeys: String, CodingKey {
        case homeID = "home_id"
        case category
        case amount
        case month
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(homeID, forKey: .homeID)
        try container.encode(category, forKey: .category)
        try container.encode(amount, forKey: .amount)
        try container.encodeDateOnly(month, forKey: .month)
    }
}

struct CustomCategory: Codable, Identifiable, Hashable {
    let id: UUID
    var homeID: UUID
    var name: String
    var emoji: String
    var color: String?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case homeID = "home_id"
        case name
        case emoji
        case color
        case createdAt = "created_at"
    }

    init(
        id: UUID,
        homeID: UUID,
        name: String,
        emoji: String = "⭐",
        color: String?,
        createdAt: Date
    ) {
        self.id = id
        self.homeID = homeID
        self.name = name
        self.emoji = emoji
        self.color = color
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        homeID = try container.decode(UUID.self, forKey: .homeID)
        name = try container.decode(String.self, forKey: .name)
        emoji = try container.decodeIfPresent(String.self, forKey: .emoji) ?? "⭐"
        color = try container.decodeIfPresent(String.self, forKey: .color)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}

struct CreateCustomCategory: Codable, Hashable {
    var homeID: UUID
    var name: String
    var emoji: String
    var color: String?

    enum CodingKeys: String, CodingKey {
        case homeID = "home_id"
        case name
        case emoji
        case color
    }
}

struct BudgetCategoryDefinition: Identifiable, Hashable {
    let name: String
    let emoji: String
    let systemImage: String
    let colorKey: String
    let isCustom: Bool

    var id: String { name.lowercased() }
}

struct BudgetCategoryIconOption: Identifiable, Hashable {
    let emoji: String
    let systemImage: String

    var id: String { emoji }
}

enum BudgetCategoryCatalog {
    static let builtInCategories: [BudgetCategoryDefinition] = [
        .init(name: "Rent", emoji: "🏠", systemImage: "house", colorKey: "violet", isCustom: false),
        .init(name: "Bills", emoji: "⚡", systemImage: "bolt", colorKey: "yellow", isCustom: false),
        .init(name: "Groceries", emoji: "🛒", systemImage: "cart", colorKey: "emerald", isCustom: false),
        .init(name: "Transport", emoji: "🚗", systemImage: "car", colorKey: "sky", isCustom: false),
        .init(name: "Takeaways", emoji: "🍕", systemImage: "takeoutbag.and.cup.and.straw", colorKey: "orange", isCustom: false),
        .init(name: "Toiletries & Household", emoji: "🧴", systemImage: "sparkles", colorKey: "teal", isCustom: false),
        .init(name: "Other", emoji: "📦", systemImage: "tag", colorKey: "slate", isCustom: false)
    ]

    static let optionalPresetCategories: [BudgetCategoryDefinition] = [
        .init(name: "Mortgage", emoji: "🏡", systemImage: "building.2", colorKey: "violet", isCustom: false),
        .init(name: "Subscriptions", emoji: "📺", systemImage: "play.rectangle", colorKey: "indigo", isCustom: false),
        .init(name: "Insurance", emoji: "🛡️", systemImage: "shield", colorKey: "blue", isCustom: false),
        .init(name: "Gym & Fitness", emoji: "🏋️", systemImage: "figure.strengthtraining.traditional", colorKey: "lime", isCustom: false),
        .init(name: "Entertainment", emoji: "🎬", systemImage: "film", colorKey: "purple", isCustom: false),
        .init(name: "Eating Out", emoji: "🍽️", systemImage: "fork.knife", colorKey: "amber", isCustom: false),
        .init(name: "Clothing", emoji: "👗", systemImage: "tshirt", colorKey: "pink", isCustom: false),
        .init(name: "Holidays", emoji: "✈️", systemImage: "airplane", colorKey: "cyan", isCustom: false),
        .init(name: "Pets", emoji: "🐾", systemImage: "pawprint", colorKey: "rose", isCustom: false),
        .init(name: "Healthcare", emoji: "💊", systemImage: "cross.case", colorKey: "red", isCustom: false),
        .init(name: "Gifts", emoji: "🎁", systemImage: "gift", colorKey: "fuchsia", isCustom: false)
    ]

    static let customColorKeys: [String] = [
        "slate", "red", "amber", "lime", "cyan", "blue", "purple", "fuchsia"
    ]

    static let customIconOptions: [BudgetCategoryIconOption] = [
        .init(emoji: "⭐", systemImage: "star"),
        .init(emoji: "🔖", systemImage: "bookmark"),
        .init(emoji: "☕", systemImage: "cup.and.saucer"),
        .init(emoji: "🎵", systemImage: "music.note"),
        .init(emoji: "📷", systemImage: "camera"),
        .init(emoji: "🚲", systemImage: "bicycle"),
        .init(emoji: "🎮", systemImage: "gamecontroller"),
        .init(emoji: "🌍", systemImage: "globe.europe.africa"),
        .init(emoji: "🍼", systemImage: "figure.and.child.holdinghands"),
        .init(emoji: "🔧", systemImage: "wrench.and.screwdriver"),
        .init(emoji: "🌿", systemImage: "leaf"),
        .init(emoji: "💎", systemImage: "diamond"),
        .init(emoji: "🎧", systemImage: "headphones"),
        .init(emoji: "📚", systemImage: "book.closed"),
        .init(emoji: "🌸", systemImage: "camera.macro"),
        .init(emoji: "🍷", systemImage: "wineglass"),
        .init(emoji: "🐶", systemImage: "dog"),
        .init(emoji: "🐱", systemImage: "cat"),
        .init(emoji: "🔑", systemImage: "key"),
        .init(emoji: "💻", systemImage: "laptopcomputer"),
        .init(emoji: "💳", systemImage: "creditcard"),
        .init(emoji: "✂️", systemImage: "scissors"),
        .init(emoji: "🌅", systemImage: "sun.horizon"),
        .init(emoji: "🏆", systemImage: "trophy")
    ]

    static func mergeCategories(custom: [CustomCategory]) -> [BudgetCategoryDefinition] {
        builtInCategories + custom.map {
            BudgetCategoryDefinition(
                name: $0.name,
                emoji: $0.emoji,
                systemImage: systemImage(forStoredEmoji: $0.emoji),
                colorKey: $0.color ?? "slate",
                isCustom: true
            )
        }
    }

    static func definition(for name: String, custom: [CustomCategory]) -> BudgetCategoryDefinition {
        let merged = mergeCategories(custom: custom)
        return merged.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame })
            ?? .init(name: name, emoji: "❓", systemImage: "tag", colorKey: "slate", isCustom: true)
    }

    static func systemImage(forStoredEmoji emoji: String) -> String {
        customIconOptions.first(where: { $0.emoji == emoji })?.systemImage ?? "tag"
    }

    static func tint(for colorKey: String) -> Color {
        switch colorKey {
        case "emerald": return DesignSystem.Palette.secondary
        case "orange": return DesignSystem.Palette.warning
        case "violet": return Color(hex: 0xA08AB8)
        case "yellow": return Color(hex: 0xD7A83E)
        case "sky": return Color(hex: 0x7A8FA1)
        case "indigo": return Color(hex: 0x7F88C4)
        case "rose": return Color(hex: 0xD98695)
        case "teal": return Color(hex: 0x7CB7A3)
        case "pink": return Color(hex: 0xC4789A)
        case "red": return DesignSystem.Palette.destructive
        case "amber": return Color(hex: 0xC99952)
        case "lime": return Color(hex: 0x8B9E7D)
        case "cyan": return Color(hex: 0x78A6C8)
        case "blue": return Color(hex: 0x6E8DB6)
        case "purple": return Color(hex: 0x8F6BAE)
        case "fuchsia": return Color(hex: 0xB86492)
        default: return Color(hex: 0x8A7B6F)
        }
    }

    static func fill(for colorKey: String) -> Color {
        tint(for: colorKey).opacity(0.14)
    }

    static func stroke(for colorKey: String) -> Color {
        tint(for: colorKey).opacity(0.22)
    }
}

private enum BudgetDateCoding {
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = Calendar.current.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private extension KeyedDecodingContainer {
    func decodeDateOnly(forKey key: Key) throws -> Date {
        let value = try decode(String.self, forKey: key)
        if let date = BudgetDateCoding.formatter.date(from: value) {
            return date
        }

        let context = DecodingError.Context(
            codingPath: codingPath + [key],
            debugDescription: "Invalid date-only format: \(value). Expected yyyy-MM-dd."
        )
        throw DecodingError.dataCorrupted(context)
    }
}

private extension KeyedEncodingContainer {
    mutating func encodeDateOnly(_ value: Date, forKey key: Key) throws {
        try encode(BudgetDateCoding.formatter.string(from: value), forKey: key)
    }
}
