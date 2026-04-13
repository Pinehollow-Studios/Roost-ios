import Foundation

struct BudgetRolloverHistory: Codable, Identifiable {
    let id: UUID
    let homeId: UUID
    let templateLineId: UUID
    let month: Date      // date-only: "yyyy-MM-dd"
    let baseAmount: Decimal
    let rolloverAmount: Decimal
    let effectiveAmount: Decimal
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case homeId = "home_id"
        case templateLineId = "template_line_id"
        case month
        case baseAmount = "base_amount"
        case rolloverAmount = "rollover_amount"
        case effectiveAmount = "effective_amount"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        homeId = try c.decode(UUID.self, forKey: .homeId)
        templateLineId = try c.decode(UUID.self, forKey: .templateLineId)
        month = try c.decodeDateOnly(forKey: .month)
        baseAmount = try c.decode(Decimal.self, forKey: .baseAmount)
        rolloverAmount = try c.decode(Decimal.self, forKey: .rolloverAmount)
        effectiveAmount = try c.decode(Decimal.self, forKey: .effectiveAmount)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(homeId, forKey: .homeId)
        try c.encode(templateLineId, forKey: .templateLineId)
        try c.encodeDateOnly(month, forKey: .month)
        try c.encode(baseAmount, forKey: .baseAmount)
        try c.encode(rolloverAmount, forKey: .rolloverAmount)
        try c.encode(effectiveAmount, forKey: .effectiveAmount)
        try c.encode(createdAt, forKey: .createdAt)
    }
}

struct CreateRolloverHistory: Codable {
    let homeId: UUID
    let templateLineId: UUID
    let month: Date
    let baseAmount: Decimal
    let rolloverAmount: Decimal
    let effectiveAmount: Decimal

    enum CodingKeys: String, CodingKey {
        case homeId = "home_id"
        case templateLineId = "template_line_id"
        case month
        case baseAmount = "base_amount"
        case rolloverAmount = "rollover_amount"
        case effectiveAmount = "effective_amount"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(homeId, forKey: .homeId)
        try c.encode(templateLineId, forKey: .templateLineId)
        try c.encodeDateOnly(month, forKey: .month)
        try c.encode(baseAmount, forKey: .baseAmount)
        try c.encode(rolloverAmount, forKey: .rolloverAmount)
        try c.encode(effectiveAmount, forKey: .effectiveAmount)
    }
}

// MARK: - Private date-only helpers

private enum RolloverDateCoding {
    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC") ?? .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}

private extension KeyedDecodingContainer {
    func decodeDateOnly(forKey key: Key) throws -> Date {
        let raw = try decode(String.self, forKey: key)
        if let date = RolloverDateCoding.formatter.date(from: raw) { return date }
        let ctx = DecodingError.Context(
            codingPath: codingPath + [key],
            debugDescription: "Invalid date-only format: \(raw). Expected yyyy-MM-dd."
        )
        throw DecodingError.dataCorrupted(ctx)
    }
}

private extension KeyedEncodingContainer {
    mutating func encodeDateOnly(_ value: Date, forKey key: Key) throws {
        try encode(RolloverDateCoding.formatter.string(from: value), forKey: key)
    }
}
