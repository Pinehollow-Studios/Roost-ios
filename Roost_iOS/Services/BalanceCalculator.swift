import Foundation

/// Calculates the expense balance between two household members.
///
/// Positive result = I am owed money.
/// Negative result = I owe money.
///
/// Uses splits (not raw expense amounts). Settled splits are excluded.
/// Solo expenses (no splits) do not affect the balance.
enum BalanceCalculator {
    /// Calculate the net balance for `myUserId` against `partnerUserId`.
    static func calculate(
        expenses: [ExpenseWithSplits],
        myUserId: UUID,
        partnerUserId: UUID
    ) -> Decimal {
        var balance: Decimal = 0

        for ews in expenses {
            let splits = ews.expenseSplits

            // Skip solo expenses (no splits means no shared cost)
            if splits.isEmpty { continue }

            for split in splits {
                // Only count unsettled splits
                guard split.settledAt == nil else { continue }

                if split.userID == partnerUserId && ews.paidBy == myUserId {
                    // Partner owes me for this split
                    balance += split.amount
                } else if split.userID == myUserId && ews.paidBy == partnerUserId {
                    // I owe partner for this split
                    balance -= split.amount
                }
            }
        }

        return balance
    }
}
