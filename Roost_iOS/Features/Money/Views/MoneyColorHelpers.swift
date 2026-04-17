import SwiftUI

/// Single source of truth for category colours across all Money screens.
/// Use this function everywhere a category name needs a colour so that
/// the same category always appears in the same colour regardless of screen.
func moneyColour(for categoryName: String) -> Color {
    let palette: [Color] = [
        Color(hex: 0xF06F48), // terracotta-orange
        Color(hex: 0x36A873), // sage-green
        Color(hex: 0xF2A33A), // warm amber
        Color(hex: 0x4D8ECF), // medium blue
        Color(hex: 0xD75B83), // dusty rose
        Color(hex: 0x8F73D9), // muted purple
        Color(hex: 0xB8832F), // warm brown
        Color(hex: 0x35AFA6), // teal
        Color(hex: 0x5BAA50), // mid-green
        Color(hex: 0xC17A6F), // rosy brown
    ]
    let hash = abs(categoryName.lowercased().unicodeScalars.reduce(0) { $0 &+ Int($1.value) })
    return palette[hash % palette.count]
}
