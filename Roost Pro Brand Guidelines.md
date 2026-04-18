# Roost Pro — Brand Guidelines
**Version 1.0 · April 2026**

---

## Overview

Roost Pro is not a different product — it's the same home, fully lit. The design language builds directly on the Roost foundation (warm terracotta, DM Sans, continuous-curve geometry) but pushes every surface to its richest, most luminous expression. Where the free app is warm and grounded, Pro is warm and radiant.

**The principle:** Every Pro surface should feel like Roost in its best light — same DNA, different time of day.

---

## 01 · Brand Concept

**Name treatment:** "Roost Pro" — two words, equal weight in terms of structure, but "Pro" carries distinct visual treatment (see Typography).

**Symbol:** `sparkles` (SF Symbols). Not a crown — sparkles ties directly to Hazel (the intelligence engine that drives Pro's key features) and reads as magical rather than hierarchical. The crown is generic; sparkles is distinctive to Roost's AI story.

**Tagline:** "Your home, elevated."
Short, warm, aspirational. Doesn't mention features. Doesn't push. It describes a feeling.

**Secondary tagline (used on longer-form surfaces like the subscription page):**
"The full household dashboard — with history, intelligence, and everything that matters."

**Brand personality:** Pro should feel earned, not sold. When a user sees a Pro surface, it should make them want to belong there — not feel locked out.

---

## 02 · Colour Palette

### The Core Principle

Pro colours live entirely within the Roost terracotta-amber family. The progression: **deep burnt copper → warm terracotta copper → amber → champagne**. This is the existing Roost primary colour (#D4795E) taken on a journey from its darkest, richest roots to its brightest, most luminous highlight. On a dark background it reads as gold. In context it reads as Roost.

### Pro Signature Gradient

Three-stop gradient used consistently across all Pro surfaces:

```
proDeepBurn  (#8B3A1E)  →  proCopper  (#C4622A)  →  proAmber  (#E8924A)  →  proChampagne  (#F5C472)
```

In code: always applied as `LinearGradient` from `.topLeading` to `.bottomTrailing` unless specified otherwise.

### Full Colour Tokens

| Token | Light Hex | Dark Hex | Usage |
|---|---|---|---|
| `proDeepBurn` | `#8B3A1E` | `#8B3A1E` | Gradient start, deep shadows, button pressed state |
| `proCopper` | `#C4622A` | `#C4622A` | Gradient mid-low, icon accent, feature accents |
| `proAmber` | `#E8924A` | `#E8924A` | Gradient mid-high, progress bars, active states |
| `proChampagne` | `#F5C472` | `#F5C472` | Gradient end, shimmer highlights, sparkle particles |
| `proWarmWhite` | `#FFF8F2` | `#FFF8F2` | Headlines and badge text on dark Pro surfaces |
| `proBodyText` | `#F0D9C0` | `#F0D9C0` | Body copy on dark Pro surfaces |
| `proMutedText` | `#A07855` | `#A07855` | Secondary/muted text on dark Pro surfaces |

### Pro Surface Colours

These are the existing Roost dark colours pushed half a shade deeper. They belong to the same family:

| Token | Hex | Roost Equivalent | Difference |
|---|---|---|---|
| `proBg` | `#0C0A08` | `#0F0D0B` (roostBackground dark) | 3 steps darker — richer, deeper |
| `proCard` | `#1E1A16` | `#1A1816` (roostCard dark) | Slightly richer — more depth |
| `proMutedSurface` | `#2C2520` | `#2A2623` (roostMuted dark) | Marginally warmer/darker |
| `proBorder` | `#E8924A` @ 0.15 | `#F2EBE0` @ 0.10 (roostHairline) | Warm amber hairline instead of cool white |

### Relationship to Roost Palette

```
Roost Primary:  #D4795E  (terracotta)
Pro Copper:     #C4622A  (terracotta's richer sibling — same hue, deeper)
Pro Amber:      #E8924A  (sits between roostWarning #E6A563 and roostShoppingTint #E9822A)
Pro Champagne:  #F5C472  (roostWarning pushed bright — the same amber family)
```

All Pro accent colours exist between existing Roost palette values. No new hue family is introduced.

### Usage Rules

- **Never use Pro colours on free-tier surfaces** — they belong exclusively to Pro UI (subscription page, upsell sheet, Pro badges, Pro-specific in-app moments)
- **Never mix Pro gradient with the standard terracotta→sage gradient** — these are two distinct Pro vs brand signals
- **Pro surfaces are always dark** — the Pro palette is designed for dark backgrounds only. Do not use Pro Champagne text on light backgrounds.
- **Gradient direction** — always `topLeading → bottomTrailing` for gradients on surfaces. For text gradients, use `leading → trailing`.

---

## 03 · Typography

### Typeface

**DM Sans exclusively** — no change from the existing Roost system. Pro does not introduce a new typeface. The premium feeling comes from treatment, not font choice.

### "Roost Pro" Wordmark Treatment

- "Roost" — DM Sans Bold, `proWarmWhite` (#FFF8F2), standard letter-spacing
- "Pro" — DM Sans Bold, gradient text fill using `proCopper (#C4622A) → proChampagne (#F5C472)` applied left to right
- The wordmark appears at these sizes:
  - Hero (subscription page): 40px
  - Upsell sheet header: 26px
  - In-app badge: 10px (badge only shows "Pro", not "Roost Pro")

### Taglines

| Context | Text | Style |
|---|---|---|
| Hero tagline | "Your home, elevated." | DM Sans Regular 15px, `proBodyText`, +0.3px tracking |
| Secondary tagline | "The full household dashboard..." | DM Sans Regular 13px, `proBodyText` @ 0.75 opacity |
| Section headers | "WHAT YOU UNLOCK" | DM Sans Medium 10px, `proMutedText`, +1.2px tracking, all caps |

### CTA Button Text

- DM Sans Bold, 15px (up from current 13px — slightly more commanding)
- Colour: `proDeepBurn` (#8B3A1E) on the Pro gradient — dark text on warm gold
- This mirrors the premium aesthetic of embossed/engraved lettering on quality materials

### General Type on Pro Surfaces

Existing Roost type scale applies. The only changes are colour values:
- Headlines: `proWarmWhite` instead of `roostForeground`
- Body: `proBodyText` instead of `roostForeground`
- Muted/secondary: `proMutedText` instead of `roostMutedForeground`
- Interactive / links: `proChampagne` instead of `roostPrimary`

---

## 04 · Iconography

### The Pro Symbol

**`sparkles` (SF Symbols)** — the primary Pro symbol, used in:
- The hero section (replaces the crown)
- The animated entrance sequence
- Pro badge (no icon in badge — see below)
- Hazel Pro feature moments

Sizing:
- Hero: 32px, bold weight
- Feature icons: 18px, medium weight
- In-app references: 12px, medium weight

**Why sparkles, not crown:**
The crown is transactional — it says "pay to unlock". Sparkles says "this is magic". It already lives in the Hazel AI identity (the intelligence layer that powers most of Pro's unique features). Using sparkles unifies the Pro and Hazel brands under one visual signal.

### Pro Badge (Inline)

Used throughout the app wherever a feature is Pro-gated. Replaces the current "Roost Pro only" text labels.

**Spec:**
- Shape: Capsule (pill)
- Fill: Pro Gradient (proCopper → proChampagne)
- Text: "Pro" in DM Sans Medium 10px, `proWarmWhite`
- **No icon** — the gradient fill is the premium signal, no icon needed
- Shimmer Sweep animation active (see Animation System)
- Height: 18px, horizontal padding: 8px

### Feature Icons (upsell sheet, subscription page)

Current: flat colour circles.
Pro: warm copper-tinted circles.

- Background: `proCopper` (#C4622A) @ 0.15 opacity
- Icon: `proAmber` (#E8924A) colour
- Size: 44px container, 20px icon
- All feature icons follow this treatment for visual unity on Pro surfaces

### Sparkles Hero Treatment

The `sparkles` symbol in the hero section receives three layers of animation (see Animation System). At rest it is:
- 32px, bold weight, filled with Pro Gradient (copper → champagne)
- Surrounded by the Glow Breathe animation
- The three points of the sparkles symbol animate independently in the Sparkle Sequence animation

---

## 05 · Animation System

All animations use SwiftUI's spring system. Pro introduces six named animations. Existing Roost spring presets (`.roostSmooth`, `.roostSnappy`) remain unchanged and apply to standard interactive elements.

---

### Animation 1: Aurora Drift
**Used on:** Hero section backgrounds (subscription page, upsell sheet)

Three radial colour blobs drift independently behind the content layer. They create the sense of warm light moving through a space.

| Property | Blob A | Blob B | Blob C |
|---|---|---|---|
| Colour | `proDeepBurn` @ 0.30 | `proAmber` @ 0.22 | `proChampagne` @ 0.14 |
| Blur | 80px | 100px | 60px |
| Size | 200×200pt | 280×160pt | 180×180pt |
| Animation period | 9 seconds | 12 seconds | 7 seconds |
| Animation type | easeInOut, autoreverse | easeInOut, autoreverse | easeInOut, autoreverse |
| Movement | Offset X: −60 → +60 | Offset Y: −40 → +40 | Offset X: +40, Y: −50 → −10 |

Each blob runs independently. The result is a slow, organic aurora effect — never static, never distracting.

Implementation: Three `Circle()` views with `.blur(radius: 80)`, each with a separate `@State var phase` animated with `.animation(.easeInOut(duration: N).repeatForever(autoreverses: true))`.

---

### Animation 2: Sparkle Sequence
**Used on:** The `sparkles` icon in the hero section

The three points of the sparkles symbol appear sequentially, then hold together at full opacity, creating a "lighting up" moment.

| Stage | Duration | Effect |
|---|---|---|
| Point 1 appears | 0.3s | Scale 0 → 1, opacity 0 → 1 |
| Point 2 appears | +0.2s delay, 0.3s | Scale 0 → 1, opacity 0 → 1 |
| Point 3 appears | +0.4s delay, 0.3s | Scale 0 → 1, opacity 0 → 1 |
| Hold at full | — | All three points visible |
| Pulse | Every 3s | Subtle scale 1.0 → 1.06 → 1.0, 0.6s ease-in-out |

Implementation: Three separate `Image(systemName:)` elements positioned to compose the sparkles shape, or a single symbol with `.symbolEffect(.appear)` using the `.byLayer` variant on iOS 17+.

---

### Animation 3: Glow Breathe
**Used on:** Behind the sparkles icon in the hero; behind the Pro badge on prominent upsell moments

A soft radial gradient aura that slowly expands and fades — ambient Pro energy, always present.

| Property | Value |
|---|---|
| Shape | Circle, radial gradient fill |
| Colours | `proAmber` @ 0.20 centre → transparent edge |
| Resting size | 80×80pt |
| Animation | Scale 0.85 → 1.45, opacity 0.20 → 0.04 |
| Duration | 2.4 seconds |
| Easing | `.easeInOut` |
| Repeat | Forever, autoreverses |

---

### Animation 4: Shimmer Sweep
**Used on:** CTA button, Pro badge pill, hero gradient surface

A bright warm-white highlight band sweeps left to right across the gradient surface, catching the light like a quality material.

| Property | Value |
|---|---|
| Band colour | `proWarmWhite` @ 0.35, feathered edges |
| Band width | 40% of element width |
| Angle | 25 degrees |
| Duration | 2.2 seconds |
| Repeat delay | 1.4 seconds between sweeps |
| Easing | `.easeInOut` |

Implementation: A `LinearGradient` mask applied as an `.overlay` on the gradient surface. The `@State var shimmerPhase: CGFloat` animates from `-1.0` to `2.0`. The gradient moves with the phase value.

```swift
// Shimmer overlay structure
LinearGradient(
    stops: [
        .init(color: .clear, location: shimmerPhase - 0.3),
        .init(color: proWarmWhite.opacity(0.35), location: shimmerPhase),
        .init(color: .clear, location: shimmerPhase + 0.3)
    ],
    startPoint: .leading,
    endPoint: .trailing
)
```

---

### Animation 5: Feature Cascade
**Used on:** Feature list in the upsell sheet and subscription page feature showcase

Each feature row enters sequentially from below, creating a reveal sequence that feels curated.

| Property | Value |
|---|---|
| Entry offset | Y: +18pt → 0 |
| Entry opacity | 0 → 1 |
| Stagger delay | 0.065s per item |
| Initial delay | 0.28s (after hero settles) |
| Spring | response: 0.38s, damping: 0.76 |

---

### Animation 6: Particle Burst
**Used on:** Upgrade success / trial start confirmation moment only

16 small warm particles radiate outward from the sparkles icon position the instant an upgrade or trial is confirmed. Plays once, never repeats.

| Property | Value |
|---|---|
| Particle count | 16 |
| Particle size | 3–5pt circles (vary per particle) |
| Colours | Mix of `proAmber` and `proChampagne` |
| Spread | 360° arc, randomised angles |
| Distance | 40–90pt from origin (randomised) |
| Duration | 0.7–1.1s per particle (randomised) |
| Exit | Scale 1 → 0, opacity 1 → 0 simultaneously |
| Easing | `.easeOut` |

---

## 06 · Component Library

### Component 1: Pro Hero Section

Used at the top of: SubscriptionView, ProUpsellSheet.

**Structure (top to bottom):**
1. Full-bleed background: `proBg` (#0C0A08)
2. Aurora Drift layer (three animated blobs, behind all content)
3. Content layer:
   - Back/dismiss button (top-left): Capsule, `proWarmWhite` @ 0.10 fill, chevron icon
   - Sparkles icon (centred, or left-aligned in sheet): 32px, Pro Gradient fill, Glow Breathe + Sparkle Sequence animations
   - "Roost **Pro**" wordmark: 40px hero / 26px sheet
   - Tagline: "Your home, elevated." — `proBodyText`, 15px, +0.3 tracking
4. Thin `proAmber` @ 0.25 hairline at base of hero
5. Minimum hero height: 220pt (sheet) / 280pt (full subscription page)

**Note:** The hero background is always `proBg` regardless of system light/dark mode — Pro surfaces are always dark. Use `.colorScheme(.dark)` environment override on the hero.

---

### Component 2: CTA Button

**Primary: "Start Your Free Trial" / "Upgrade to Roost Pro"**

| Property | Value |
|---|---|
| Height | 52pt |
| Corner radius | 26pt (full capsule) |
| Fill | Pro Gradient (proDeepBurn → proCopper → proAmber → proChampagne), angle: leading → trailing |
| Text | DM Sans Bold 15px, `proDeepBurn` (#8B3A1E) |
| Text tracking | −0.2px |
| Animation | Shimmer Sweep (continuous) |
| Press state | Scale 0.97, spring response 0.18s damping 0.62 |
| Release state | Scale 1.0, spring response 0.26s damping 0.68 |
| Max width | `.infinity` (full-width) |
| Horizontal padding | 20pt page inset |

**Secondary: "See all features →" / "Restore purchase"**

| Property | Value |
|---|---|
| Height | 44pt |
| Corner radius | 22pt (capsule) |
| Fill | `proCopper` @ 0.08 |
| Border | `proCopper` @ 0.25, 1pt |
| Text | DM Sans Medium 13px, `proAmber` |

---

### Component 3: Pro Badge (Inline)

Used throughout the app wherever a feature is Pro-gated or labelled.

| Property | Value |
|---|---|
| Shape | Capsule |
| Fill | Pro Gradient, leading → trailing |
| Text | "Pro" — DM Sans Medium 10px, `proWarmWhite` |
| No icon | — (gradient is the signal, no symbol needed) |
| Height | 18pt |
| Padding | 8pt horizontal, 3pt vertical |
| Animation | Shimmer Sweep, every 4 seconds |

**Usage contexts:**
- Settings rows (HazelView, etc.): replaces "Roost Pro only" text
- Feature gates: inline with feature title
- Navigation: small badge next to Pro-only section names

---

### Component 4: Feature Card (Upsell sheet list)

Each feature in the upsell sheet's highlight list.

| Property | Value |
|---|---|
| Background | `proCard` (#1E1A16) |
| Border | `proAmber` @ 0.12, 1pt, continuous corner radius 14pt |
| Left accent bar | 2.5pt wide, Pro Gradient fill, full height |
| Icon container | 44pt circle, `proCopper` @ 0.15 fill |
| Icon | `proAmber` (#E8924A) colour, 20pt |
| Feature name | DM Sans Medium 15px, `proWarmWhite` |
| Description | DM Sans Regular 12px, `proMutedText` |
| Entrance | Feature Cascade animation |

---

### Component 5: Comparison Table (SubscriptionView)

| Element | Spec |
|---|---|
| "Pro" column header cell | Pro Gradient fill, "Pro" in `proWarmWhite` DM Sans Bold 13px |
| "Free" column header cell | `proMutedSurface` fill, muted text |
| Pro checkmark | `proAmber` SF Symbol `checkmark` (not `checkmark.circle.fill`) |
| Free "—" dash | `roostMutedForeground` |
| Row dividers | `proBorder` (proAmber @ 0.12) |
| Row background alternation | None — clean, borderless rows |
| Feature label | DM Sans Regular 14px, `proBodyText` |

---

### Component 6: In-App Pro Upsell Moments

Passive Pro signals that appear contextually without a full sheet (e.g. locked data badges, zone1 insight teaser, spending trend lock pill).

| Element | Spec |
|---|---|
| Lock pill (e.g. "5 months locked") | Capsule, Pro Gradient fill, `lock.fill` 9px + text 10px DM Sans Medium, `proWarmWhite` |
| Teaser text links (e.g. "✨ Hazel can narrate this month →") | Pro Gradient applied as foreground gradient to the text, 11px |
| Locked history nudge card (MoneyHomeView) | `proCard` background, `proAmber` icon, standard card layout |

---

### Component 7: Upgrade Success State

The moment a user starts a trial or upgrades. Plays once.

| Element | Spec |
|---|---|
| Background | Briefly switches to `proBg` with Aurora Drift |
| Sparkles animation | Sparkle Sequence plays in full |
| Particle Burst | Triggers from sparkles icon position |
| Confirmation text | "Welcome to Roost Pro" — DM Sans Bold 22px, `proWarmWhite` |
| Sub-text | "Your home is now elevated." — DM Sans Regular 14px, `proBodyText` |
| Duration before dismissal | 2.2 seconds, then fade to normal Pro state |

---

## 07 · Copywriting

### Voice Principles

1. **Aspirational, not transactional** — Pro copy describes what life feels like, not what features are unlocked
2. **Short and warm** — DM Sans reads best in tight, confident sentences. No padding words.
3. **First person "your"** — "Your home", "Your data", "Your month" — it's personal
4. **Never guilt** — Don't frame free tier as lacking. Frame Pro as richer.
5. **Let the design do the selling** — Copy supports the visual. It doesn't need to list features.

### Core Copy

| Surface | Copy |
|---|---|
| Hero tagline | "Your home, elevated." |
| Hero sub-tagline | "The full household dashboard — with history, intelligence, and everything that matters." |
| Trial CTA | "Start Your Free Trial" |
| Upgrade CTA | "Upgrade to Roost Pro" |
| Trial sub-label | "14 days free, then £4.99/mo. Cancel anytime." |
| Upgrade sub-label | "Billed at £4.99/mo. Cancel anytime." |
| Upgrade success headline | "Welcome to Roost Pro" |
| Upgrade success body | "Your home is now elevated." |
| Trial success headline | "Your trial has started" |
| Trial success body | "14 days of the full Roost experience." |

### Feature Descriptions

For use in the upsell sheet and subscription page showcase:

| Feature | Short (badge/pill) | Long (feature card) |
|---|---|---|
| Hazel AI | "Always working. Never in the way." | "Auto-categorizes as you log, narrates your spending month in plain English, bulk-sorts uncategorized items, and suggests your monthly chore list — all silently in the background." |
| Budget History | "Every month, forever." | "Navigate every past month and see exactly where your money went and why. Your financial story, never locked away." |
| Advanced Budgeting | "Set goals. Watch them happen." | "Unlock multiple savings goals, full month-by-month spending trends, and a detailed month comparison — so you always see the bigger picture." |
| Smart Notifications | "Never miss what matters." | "Get nudged when chores are overdue, bills are coming, or spending is running hot. The right alert, at the right moment." |
| Room Groups | "Tidy the house with one tap." | "Group rooms together and assign chores to all of them at once. Clean all bathrooms. Tidy the whole house. One action." |
| Unlimited Members | "Everyone in, no limits." | "Add every person in your home — no caps, no tiers, no extra cost." |

### In-App Teaser Copy

Contextual moments where Pro value is passively surfaced:

| Context | Copy |
|---|---|
| Spending trend lock pill | "{N} months locked" |
| Locked history nudge card | "{N} months of data locked · Upgrade to access your full spending history" |
| Zone1 Hazel insight teaser | "✨ Hazel can narrate this month →" |
| Hazel free-tier toast | "✨ Hazel Pro auto-sorts as you add →" |
| Goals Pro gate footer | "See every goal. Track every win." |
| Month comparison gate | "See how this month compares to last." |
| Bulk categorize (free) | "✨ Auto-sort with Hazel Pro →" |
| Chores suggest (free) | Shows "Pro" as detail label |

---

## 08 · Platform Application

### iOS App

- **SubscriptionView**: Full rebrand using Hero Section, Aurora Drift, new comparison table, updated copy
- **ProUpsellSheet**: New dark hero, Sparkle Sequence + Glow Breathe, Feature Cascade, new Feature Cards, new CTA button
- **In-app badges**: All "Roost Pro only" labels replaced with Pro Badge component
- **Upgrade success**: Particle Burst + success copy state
- **Upsell teasers**: Lock pill, nudge cards, and teaser text updated to Pro gradient treatment

### Mac App

Same colour tokens and animation intent, adapted for macOS idioms:
- Aurora Drift: slower (11s, 15s, 9s) — desktop can afford more subtlety
- Pro Hero: panel header rather than full-bleed (700×200pt)
- CTA Button: standard macOS button size (360pt wide, 44pt height)
- Shimmer Sweep: same specs

### Website

- Pro landing section: `proBg` full-width section with Aurora Drift
- Feature grid: Feature Card component adapted for web
- CTA: same gradient treatment, adapted for hover states (shimmer on hover)
- Typography: DM Sans via Google Fonts

---

## 09 · What Stays the Same

- DM Sans as the only typeface, at the same sizes and weights
- All Roost spacing values (no new spacing tokens needed)
- All corner radii (continuous curve geometry throughout)
- Spring-based motion for interactive elements
- Roost primary (#D4795E) and secondary (#9DB19F) for all non-Pro surfaces
- The warm, home-focused brand personality
- Roost's existing feature section colours (money blue, chores green, shopping orange)
- Minimum 4.5:1 contrast on all text

---

## 10 · Implementation Notes

### Colour Token Strategy

Add these tokens to `DesignSystem.swift` under a new `ProPalette` enum:

```swift
enum ProPalette {
    static let deepBurn    = Color(hex: 0x8B3A1E)
    static let copper      = Color(hex: 0xC4622A)
    static let amber       = Color(hex: 0xE8924A)
    static let champagne   = Color(hex: 0xF5C472)
    static let warmWhite   = Color(hex: 0xFFF8F2)
    static let bodyText    = Color(hex: 0xF0D9C0)
    static let mutedText   = Color(hex: 0xA07855)
    static let bg          = Color(hex: 0x0C0A08)
    static let card        = Color(hex: 0x1E1A16)
    static let mutedSurface = Color(hex: 0x2C2520)

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
}
```

And convenience Color extensions:
```swift
extension Color {
    static let proDeepBurn    = DesignSystem.ProPalette.deepBurn
    static let proCopper      = DesignSystem.ProPalette.copper
    static let proAmber       = DesignSystem.ProPalette.amber
    static let proChampagne   = DesignSystem.ProPalette.champagne
    static let proWarmWhite   = DesignSystem.ProPalette.warmWhite
    static let proBodyText    = DesignSystem.ProPalette.bodyText
    static let proMutedText   = DesignSystem.ProPalette.mutedText
    static let proBg          = DesignSystem.ProPalette.bg
    static let proCard        = DesignSystem.ProPalette.card
    static let proMutedSurface = DesignSystem.ProPalette.mutedSurface
}
```

### Animation Utility

Create a `ProAnimations.swift` file with reusable animation modifiers:

- `ProShimmerModifier` — the shimmer sweep effect, applicable to any view
- `ProGlowModifier` — the glow breathe effect for the sparkles icon
- `ProAuroraBackground` — the three-blob aurora drift, used as a `.background` modifier
- `ProParticleBurst` — the upgrade success particle system

### Build Order for iOS App Rebrand

Recommended sequence:

1. Add colour tokens to `DesignSystem.swift`
2. Create `ProAnimations.swift` with all reusable modifiers
3. Rebuild `NestUpsellSheet.swift` (ProUpsellSheet) — highest-frequency Pro touchpoint
4. Rebuild `SubscriptionView.swift` — the conversion page
5. Update `Color+Extensions.swift` with Pro convenience tokens
6. Update all in-app Pro badges (HazelView, RoomsView, ChoresView, etc.)
7. Update upgrade success flow
8. Mac app and website

---

*Document maintained by the Roost design team. All implementation should reference this document before shipping any Pro-facing change.*
