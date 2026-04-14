import Foundation
import Supabase

struct HouseholdIncomeService {

    /// Fetch the current user's personal income from home_members.
    func fetchMyIncome(userId: UUID) async throws -> Decimal? {
        let client = try SupabaseClientProvider.shared.requireClient()
        let member: HomeMember = try await client
            .from("home_members")
            .select()
            .eq("user_id", value: userId)
            .single()
            .execute()
            .value
        return member.personalIncome
    }

    /// Update the current user's personal income in home_members.
    func setMyIncome(userId: UUID, amount: Decimal) async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        try await client
            .from("home_members")
            .update(["personal_income": amount])
            .eq("user_id", value: userId)
            .execute()
    }

    /// Update income visibility preference in home_members.
    func setIncomeVisibility(userId: UUID, visible: Bool) async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        try await client
            .from("home_members")
            .update(["income_visible_to_partner": visible])
            .eq("user_id", value: userId)
            .execute()
    }

    /// Fetch the combined household income row for a given month.
    func fetchHouseholdIncome(homeId: UUID, month: Date) async throws -> HouseholdIncome? {
        let client = try SupabaseClientProvider.shared.requireClient()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let monthString = formatter.string(from: month)
        let rows: [HouseholdIncome] = try await client
            .from("household_income")
            .select()
            .eq("home_id", value: homeId)
            .eq("month", value: monthString)
            .execute()
            .value
        return rows.first
    }

    /// Returns the partner's personal_income only if BOTH home members
    /// have income_visible_to_partner = true. Returns nil otherwise.
    func fetchPartnerIncome(homeId: UUID, currentUserId: UUID) async throws -> Decimal? {
        let client = try SupabaseClientProvider.shared.requireClient()
        let members: [HomeMember] = try await client
            .from("home_members")
            .select()
            .eq("home_id", value: homeId)
            .execute()
            .value

        // Both must have consented
        guard members.count == 2,
              members.allSatisfy({ $0.incomeVisibleToPartner == true }) else {
            return nil
        }
        return members.first(where: { $0.userID != currentUserId })?.personalIncome
    }

    /// Fetch the live household income total from home_members.
    /// This is the authoritative app-side value for Money screens because
    /// household_income is a monthly cache that may not exist yet or may lag.
    func fetchCombinedMemberIncome(homeId: UUID) async throws -> Decimal {
        let client = try SupabaseClientProvider.shared.requireClient()
        let members: [HomeMember] = try await client
            .from("home_members")
            .select()
            .eq("home_id", value: homeId)
            .execute()
            .value

        return members.reduce(Decimal(0)) { total, member in
            total + (member.personalIncome ?? 0)
        }
    }

    /// Calculates the combined income from all home members and upserts it
    /// to the household_income table. Called whenever either partner updates
    /// their individual income.
    func syncCombinedIncome(homeId: UUID, month: Date) async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        let members: [HomeMember] = try await client
            .from("home_members")
            .select()
            .eq("home_id", value: homeId)
            .execute()
            .value

        let sorted = members.sorted { $0.joinedAt < $1.joinedAt }
        let member1Income = sorted.first?.personalIncome ?? 0
        let member2Income = sorted.dropFirst().first?.personalIncome ?? 0
        let combined = member1Income + member2Income

        let payload = UpsertHouseholdIncome(
            homeId: homeId,
            month: month,
            combinedAmount: combined,
            tomAmount: member1Income > 0 ? member1Income : nil,
            partnerAmount: member2Income > 0 ? member2Income : nil
        )

        try await client
            .from("household_income")
            .upsert(payload, onConflict: "home_id,month")
            .execute()
    }
}
