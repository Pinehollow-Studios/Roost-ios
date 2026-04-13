import Foundation

struct HouseholdIncome: Codable, Identifiable {
    let id: UUID
    let homeId: UUID
    let month: Date          // date-only: "yyyy-MM-dd"
    var combinedAmount: Decimal
    var tomAmount: Decimal?   // internal name only — maps to member1_amount
    var partnerAmount: Decimal? // internal name only — maps to member2_amount
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case homeId = "home_id"
        case month
        case combinedAmount = "combined_amount"
        case tomAmount = "member1_amount"
        case partnerAmount = "member2_amount"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        homeId = try c.decode(UUID.self, forKey: .homeId)
        month = try c.decodeDateOnly(forKey: .month)
        combinedAmount = try c.decode(Decimal.self, forKey: .combinedAmount)
        tomAmount = try c.decodeIfPresent(Decimal.self, forKey: .tomAmount)
        partnerAmount = try c.decodeIfPresent(Decimal.self, forKey: .partnerAmount)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(homeId, forKey: .homeId)
        try c.encodeDateOnly(month, forKey: .month)
        try c.encode(combinedAmount, forKey: .combinedAmount)
        try c.encodeIfPresent(tomAmount, forKey: .tomAmount)
        try c.encodeIfPresent(partnerAmount, forKey: .partnerAmount)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
    }
}

struct UpsertHouseholdIncome: Codable {
    let homeId: UUID
    let month: Date
    let combinedAmount: Decimal
    let tomAmount: Decimal?
    let partnerAmount: Decimal?

    enum CodingKeys: String, CodingKey {
        case homeId = "home_id"
        case month
        case combinedAmount = "combined_amount"
        case tomAmount = "member1_amount"
        case partnerAmount = "member2_amount"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(homeId, forKey: .homeId)
        try c.encodeDateOnly(month, forKey: .month)
        try c.encode(combinedAmount, forKey: .combinedAmount)
        try c.encodeIfPresent(tomAmount, forKey: .tomAmount)
        try c.encodeIfPresent(partnerAmount, forKey: .partnerAmount)
    }
}

// MARK: - Private date-only helpers

private enum IncomeDateCoding {
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
        if let date = IncomeDateCoding.formatter.date(from: raw) { return date }
        let ctx = DecodingError.Context(
            codingPath: codingPath + [key],
            debugDescription: "Invalid date-only format: \(raw). Expected yyyy-MM-dd."
        )
        throw DecodingError.dataCorrupted(ctx)
    }
}

private extension KeyedEncodingContainer {
    mutating func encodeDateOnly(_ value: Date, forKey key: Key) throws {
        try encode(IncomeDateCoding.formatter.string(from: value), forKey: key)
    }
}
