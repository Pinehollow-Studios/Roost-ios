import SwiftUI

enum DesignSystem {
    enum Palette {
        static let background = Color(light: 0xEBE3D5, dark: 0x0F0D0B)
        static let foreground = Color(light: 0x3D3229, dark: 0xF2EBE0)
        static let card = Color(light: 0xF2EBE0, dark: 0x1A1816)
        static let cardForeground = Color(light: 0x3D3229, dark: 0xF2EBE0)
        static let popover = Color(light: 0xF2EBE0, dark: 0x1A1816)
        static let popoverForeground = Color(light: 0x3D3229, dark: 0xF2EBE0)
        static let primary = Color(light: 0xD4795E, dark: 0xD4795E)
        static let primaryDeep = Color(hex: 0xB8563C)
        static let primaryForeground = Color(light: 0xF2EBE0, dark: 0xF2EBE0)
        /// Sage — ATMOSPHERIC only. Illustrations, washes, empty-state tints, decorative fills.
        /// Dissolves into warm cream at small sizes — that's the intent. Do NOT use for buttons,
        /// chips, pills, status dots, or filled tags. For interactive sage, use `secondaryInteractive`.
        static let secondary = Color(light: 0x9DB19F, dark: 0x7A8C7C)
        /// Sage — INTERACTIVE use. Buttons, chips, pills, status dots, filled tags.
        /// Stronger green that holds its own on cream at small sizes and passes 4.5:1 with white text
        /// on the filled variant. Dark-mode value is slightly lifted for cream-on-dark contrast.
        static let secondaryInteractive = Color(light: 0x6B9673, dark: 0x8FB295)
        static let secondaryForeground = Color(light: 0xF2EBE0, dark: 0xF2EBE0)
        static let muted = Color(light: 0xDDD4C6, dark: 0x2A2623)
        static let mutedForeground = Color(light: 0x6B6157, dark: 0xA39A8F)
        static let accent = Color(light: 0xE8D5BC, dark: 0x2A2623)
        static let accentForeground = Color(light: 0x3D3229, dark: 0xF2EBE0)
        static let destructive = Color(light: 0xC75146, dark: 0xC75146)
        /// Tinted destructive fill for error-state form fields. Warmer than muted, unmistakably
        /// destructive without shouting. Dark-mode value sits at the destructive hue, low-brightness.
        static let destructiveSoft = Color(light: 0xF5DDD8, dark: 0x3A1E1B)
        static let destructiveForeground = Color(light: 0xF2EBE0, dark: 0xF2EBE0)
        static let border = Color(lightRGBA: (0x3D3229, 0.15), darkRGBA: (0xF2EBE0, 0.10))
        static let inputBackground = Color(light: 0xE3D9CA, dark: 0x1F1C19)
        static let switchBackground = Color(light: 0xDDD4C6, dark: 0x2A2623)
        static let ring = Color(lightRGBA: (0xD4795E, 0.30), darkRGBA: (0xD4795E, 0.30))
        static let success = Color(light: 0x7FA087, dark: 0x7FA087)
        static let warning = Color(light: 0xE6A563, dark: 0xE6A563)
        static let chart1 = Color(light: 0xD4795E, dark: 0xD4795E)
        static let chart2 = Color(light: 0x9DB19F, dark: 0x7A8C7C)
        static let chart3 = Color(light: 0xE6A563, dark: 0xE6A563)
        static let chart4 = Color(light: 0xB88B7E, dark: 0xB88B7E)
        static let chart5 = Color(light: 0x7FA087, dark: 0x7FA087)
        static let shoppingAccent = Color(light: 0xE9822A, dark: 0xF39A3D)
        static let choresAccent = Color(light: 0x2FAE63, dark: 0x45C978)
        static let moneyAccent = Color(light: 0x337DD6, dark: 0x5B9BE8)

        static let authGradientStart = primary
        static let authGradientEnd = Color(light: 0x9DB19F, dark: 0x7A8C7C)

        static let avatarPalette: [Color] = [
            Color(hex: 0xD4795E),
            Color(hex: 0x9DB19F),
            Color(hex: 0xE6A563),
            Color(hex: 0xC17A6F),
            Color(hex: 0x7A9199),
            Color(hex: 0xA08AB8),
            Color(hex: 0xC4789A),
            Color(hex: 0x8B9E7D),
            Color(hex: 0xB88872),
            Color(hex: 0x7A8FA1),
            Color(hex: 0xC9A77C),
            Color(hex: 0x8A7B6F)
        ]
    }

    enum Radius {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 18
        static let xl: CGFloat = 22
        static let full: CGFloat = 999
    }

    enum Spacing {
        static let micro: CGFloat = 4
        static let microMedium: CGFloat = 6
        static let inline: CGFloat = 8
        static let row: CGFloat = 12
        static let page: CGFloat = 20
        static let section: CGFloat = 16
        static let sectionLarge: CGFloat = 20
        static let block: CGFloat = 24
        static let blockLarge: CGFloat = 32
        static let card: CGFloat = 16
        static let cardLarge: CGFloat = 20
        static let iconPadding: CGFloat = 10
        static let screenTop: CGFloat = 12
        static let screenBottom: CGFloat = 32
        static let tabContentBottomInset: CGFloat = 20
    }

    enum Size {
        static let maxPhoneWidth: CGFloat = 390
        static let buttonHeight: CGFloat = 44
        static let inputHeight: CGFloat = 44
        static let icon: CGFloat = 20
        static let navigationIcon: CGFloat = 24
        static let tabBarHeight: CGFloat = 49
        static let authLogoMark: CGFloat = 60
        static let authLogoGlyph: CGFloat = 36
        static let miniLogoMark: CGFloat = 24
        static let miniLogoGlyph: CGFloat = 16
        static let pageTopInset: CGFloat = 12
        static let statusBarInset: CGFloat = 6
        static let authTopSplit: CGFloat = 0.3
        static let authHeaderMinHeight: CGFloat = 220
        static let setupChoiceIconContainer: CGFloat = 56
        static let setupChoiceIcon: CGFloat = 28
        static let setupChoiceMinHeight: CGFloat = 164
        static let setupInputTopOffset: CGFloat = 40
        static let progressDotActive: CGFloat = 8
        static let progressDotInactive: CGFloat = 6
        static let toastBottomOffset: CGFloat = tabBarHeight + DesignSystem.Spacing.tabContentBottomInset + DesignSystem.Spacing.row
    }

    enum Typography {
        // Explicit DM Sans face names so SwiftUI binds weights reliably.
        // The design-system spec (colors_and_type.css) sets a specific weight per token;
        // relying on `.bold()` modifiers on a custom Medium cut was fragile.

        // Structural headings — Bold (700)
        /// Page titles (26pt Bold, -0.005em tracking — apply `.tracking(pageTitleTracking)` at use).
        static let pageTitle = Font.custom("DMSans-Bold", size: 26, relativeTo: .title2)
        /// Section headings (20pt Bold).
        static let sectionHeading = Font.custom("DMSans-Bold", size: 20, relativeTo: .title3)
        /// Card headers (17pt Semibold — `--fs-card-title` + `h4, .roost-card-title` in CSS).
        static let cardTitle = Font.custom("DMSans-SemiBold", size: 17, relativeTo: .headline)

        // Body and utility
        /// Standard body (15pt Regular).
        static let body = Font.custom("DMSans-Regular", size: 15, relativeTo: .body)
        /// Buttons, tags, form labels (13pt Medium).
        static let label = Font.custom("DMSans-Medium", size: 13, relativeTo: .subheadline)
        /// Timestamps, secondary meta (12pt Regular).
        static let caption = Font.custom("DMSans-Regular", size: 12, relativeTo: .caption)
        /// Eyebrow / badges (11pt Medium). Apply `.tracking(microTracking)` + `.textCase(.uppercase)` at usage.
        static let micro = Font.custom("DMSans-Medium", size: 11, relativeTo: .caption2)
        /// Tab-bar labels (10pt Medium).
        static let tabLabel = Font.custom("DMSans-Medium", size: 10, relativeTo: .caption2)

        // Hero display — Bold
        /// Large stats, money amounts (34pt Bold, -0.01em tracking).
        static let heroNumber = Font.custom("DMSans-Bold", size: 34, relativeTo: .largeTitle)
        /// Hero greetings (28pt Bold, -0.01em tracking).
        static let largeGreeting = Font.custom("DMSans-Bold", size: 28, relativeTo: .largeTitle)

        // ---- Tracking tokens (points, converted from em). Apply with `.tracking(...)` at use. ----
        /// -0.01em at 34pt.
        static let heroNumberTracking: CGFloat = -0.34
        /// -0.01em at 28pt.
        static let largeGreetingTracking: CGFloat = -0.28
        /// -0.005em at 26pt.
        static let pageTitleTracking: CGFloat = -0.13
        /// +1px tracking on ALL-CAPS eyebrow / micro labels.
        static let microTracking: CGFloat = 1
    }

    enum Motion {
        /// Major screen transitions — feels like content arriving with purpose, not floating.
        static let pageTransition = Animation.spring(response: 0.42, dampingFraction: 0.84)
        /// Sheets and modals — snappy but soft.
        static let modalTransition = Animation.spring(response: 0.32, dampingFraction: 0.88)
        /// Button press — tight and immediate, like real tactile feedback.
        static let buttonPress = Animation.spring(response: 0.18, dampingFraction: 0.62)
        /// Button release — spring back with a hint of life.
        static let buttonRelease = Animation.spring(response: 0.26, dampingFraction: 0.68)
        /// List insertions / staggered reveals.
        static let listAppear = Animation.spring(response: 0.38, dampingFraction: 0.82)
        /// Progress bars — smooth fill with physical feel.
        static let progressFill = Animation.spring(response: 0.5, dampingFraction: 0.84)
        /// Tab bar pill sliding between destinations.
        static let tabSwitch = Animation.spring(response: 0.3, dampingFraction: 0.76)
        /// Checkmark bounce when completing a chore or shopping item.
        static let checkmark = Animation.spring(response: 0.28, dampingFraction: 0.52)
    }

    enum Shadow {
        static let sheetColor = Color.black.opacity(0.15)
        static let sheetRadius: CGFloat = 60
        static let sheetYOffset: CGFloat = 20
        static let tabBarColor = Color.black.opacity(0.05)
        static let tabBarRadius: CGFloat = 16
        static let tabBarYOffset: CGFloat = -4
    }

    // MARK: - Pro Palette
    // Roost Pro colour system — terracotta-copper-amber-champagne family.
    // These colours sit entirely within the Roost hue family. Always used on dark surfaces.

    enum ProPalette {
        /// Gradient start — deep burnt copper, darkest Pro tone
        static let deepBurn     = Color(hex: 0x8B3A1E)
        /// Gradient mid-low — rich copper, Roost primary's deeper sibling
        static let copper       = Color(hex: 0xC4622A)
        /// Gradient mid-high — warm amber, between roostWarning and roostShoppingTint
        static let amber        = Color(hex: 0xE8924A)
        /// Gradient end — warm champagne highlight
        static let champagne    = Color(hex: 0xF5C472)
        /// Headline / badge text on dark Pro surfaces
        static let warmWhite    = Color(hex: 0xFFF8F2)
        /// Body copy on dark Pro surfaces
        static let bodyText     = Color(hex: 0xF0D9C0)
        /// Muted / secondary text on dark Pro surfaces
        static let mutedText    = Color(hex: 0xA07855)
        /// Pro surface background — richer than roostBackground dark
        static let bg           = Color(hex: 0x0C0A08)
        /// Pro card background
        static let card         = Color(hex: 0x1E1A16)
        /// Pro muted surface
        static let mutedSurface = Color(hex: 0x2C2520)

        /// Full 4-stop Pro signature gradient (topLeading → bottomTrailing)
        static let gradient = LinearGradient(
            colors: [
                Color(hex: 0x8B3A1E),
                Color(hex: 0xC4622A),
                Color(hex: 0xE8924A),
                Color(hex: 0xF5C472)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Horizontal gradient for CTA buttons and text
        static let gradientH = LinearGradient(
            colors: [
                Color(hex: 0x8B3A1E),
                Color(hex: 0xC4622A),
                Color(hex: 0xE8924A),
                Color(hex: 0xF5C472)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { trait in
            let hex = trait.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }

    init(lightRGBA: (UInt32, Double), darkRGBA: (UInt32, Double)) {
        self.init(uiColor: UIColor { trait in
            let value = trait.userInterfaceStyle == .dark ? darkRGBA : lightRGBA
            return UIColor(
                red: CGFloat((value.0 >> 16) & 0xFF) / 255,
                green: CGFloat((value.0 >> 8) & 0xFF) / 255,
                blue: CGFloat(value.0 & 0xFF) / 255,
                alpha: value.1
            )
        })
    }
}
