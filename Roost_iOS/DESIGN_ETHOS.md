# Roost iOS Design Ethos

**A comprehensive guide to the design philosophy, visual language, and interaction patterns that should make Roost on iPhone feel warm, native, and lived-in.**

---

## Philosophy

Roost is a household app for two people building a life together. On iPhone, it should feel **warm over sterile, calm over busy, and native over styled-for-the-sake-of-it**.

The reference feeling is still the same: a well-lived home. Soft light. Warm materials. Quiet confidence. Nothing cold, glossy, or corporate.

This is not a productivity dashboard pretending to be a home. It is a home app that happens to organise life.

Every design decision should reinforce a few truths:

- Roost is built for exactly two people.
- It should feel at home on iOS.
- It should reduce friction, not create ceremony.
- It should be emotionally warm without becoming cute or precious.

When in doubt, choose the version that feels calmer, simpler, and more human.

---

## iOS Design Principles

### Built for the phone

Roost is now primarily an iPhone app. Designs should start from a handheld, thumb-reachable, portrait-first experience.

- Primary actions should be easy to reach.
- Screens should be scannable in under a second.
- Forms should feel short, focused, and forgiving.
- Important information should appear early without forcing deep navigation.

### Native first

Roost should respect SwiftUI and iOS conventions unless there is a strong product reason not to.

- Use `NavigationStack`, sheets, confirmation dialogs, swipe actions, pull-to-refresh, context menus, and tab navigation in ways that feel familiar.
- Avoid web-like patterns such as dense toolbars, tiny click targets, and overloaded screens.
- Motion should support spatial continuity, not act like marketing animation.

### Warmth without clutter

Warm does not mean decorative. Keep interfaces restrained.

- Let colour, spacing, material, and copy carry the feeling.
- Prefer one strong accent over many competing accents.
- Use rounded shapes and generous spacing rather than ornamental visuals.

### One-handed practicality

Roost is likely to be used in kitchens, shops, hallways, and on sofas.

- Core flows should work comfortably with one hand.
- Tap targets should be generous.
- The most frequent actions should be near the bottom of the screen or easy to reveal.

---

## Color System

### Inspiration

The palette is drawn from warm, earthy domestic tones: terracotta pottery, sage plants, cream linen, warm wood, paper, and evening lamplight.

### Light Mode Palette

**Foundation Colors**

- **Background:** `#ebe3d5`
  A warm cream for the app canvas. Never pure white.
- **Foreground:** `#3d3229`
  A warm dark brown for primary text and icons. Never pure black.
- **Card:** `#f2ebe0`
  A creamy elevated surface for cards, grouped content, and sheets.

**Semantic Colors**

- **Primary (Terracotta):** `#d4795e`
  The emotional centre of the app. Use for primary CTAs, selected states, progress emphasis, and moments of importance.
- **Secondary (Sage):** `#9db19f`
  Calm, supportive, and balancing. Use for secondary actions and softer emphasis.
- **Muted:** `#ddd4c6`
  A neutral warm surface for subtle grouping.
- **Muted Foreground:** `#6b6157`
  Secondary text that recedes gently.
- **Accent:** `#e8d5bc`
  A warm highlight for subtle emphasis and hover-like pressed states where needed.

**Area Accent Colors**

These accents identify sections without replacing the terracotta app primary. Terracotta remains the main commitment colour for primary actions across Roost; area accents are for page rails, focus rings, selected chips, section highlights, empty-state icons, links, and small orientation details.

- **Shopping Accent (Orange):** `#e9822a`
  Warm, practical, and fast. Use for shopping page highlights, add-item focus states, shopping chips, list accents, and the top page rail.
- **Chores Accent (Green):** `#2fae63`
  Fresh, active, and rewarding. Use for chores progress, chore filters, completion-adjacent emphasis, room/task setup highlights, and the top-level chores identity.
- **Money Accent (Blue):** `#337dd6`
  Clear, precise, and modern. Use for money page rails, analytical selected states, money links, spend-context highlights, and compact financial navigation.

Area accents should be confident but restrained. They should read clearly against the warm Roost base without turning neon, and opacity should be used for quiet surfaces.

**Status Colors**

- **Success:** `#7fa087`
- **Warning:** `#e6a563`
- **Info:** `#9db19f`
- **Destructive:** `#c75146`

**Chart / Data Colors**

1. `#d4795e`
2. `#9db19f`
3. `#e6a563`
4. `#b88b7e`
5. `#7fa087`

**Interactive Surfaces**

- **Input Background:** `#e3d9ca`
- **Toggle Background:** `#c9c2b8`
- **Border:** `rgba(61, 50, 41, 0.15)`
- **Focus Ring / Active Glow:** `rgba(212, 121, 94, 0.30)`

### Dark Mode Palette

Dark mode should feel like a softly lit room at night, not a cold technical inversion.

**Foundation Colors**

- **Background:** `#0f0d0b`
- **Foreground:** `#f2ebe0`
- **Card:** `#1a1816`

**Semantic Colors**

- **Primary:** `#d4795e`
- **Secondary:** `#7a8c7c`
- **Muted:** `#2a2623`
- **Muted Foreground:** `#a39a8f`
- **Accent:** `#2a2623`

**Interactive Surfaces**

- **Input Background:** `#1f1c19`
- **Toggle Background:** `#3a3530`
- **Border:** `rgba(242, 235, 224, 0.10)`

### Color Rules

- Never use pure white or pure black.
- Never fall back to default SwiftUI blue for branded UI.
- Terracotta should feel intentional, not sprayed everywhere.
- Orange, green, and blue area accents should orient the user by app area; they should not become full-page themes.
- Use muted tones for structure and hierarchy; use primary colour for commitment and meaning.

---

## Typography

### Font Family

**DM Sans** remains the system font choice for Roost. It is modern but human, geometric but soft.

**Fallback stack:** DM Sans, then system sans-serif.

### Weight System

Use a restrained hierarchy.

- **Medium (500):** Titles, labels, buttons, emphasis.
- **Regular (400):** Body, captions, field content.

Avoid heavy bold unless accessibility or a very specific UI state truly requires it.

### Type Scale for iPhone

Use semantic type tokens, not arbitrary sizes.

- **Large Title / Hero:** for welcome moments and major page titles
- **Heading:** for primary screen titles
- **Section:** for grouped content headings
- **Card Title:** for module headings
- **Body:** default reading size
- **Label:** field labels, chips, compact emphasis
- **Caption:** timestamps, helper text, secondary metadata

### Typography Principles

- Create hierarchy with size and weight first.
- Use muted foreground for secondary copy, not weaker font sizing alone.
- Keep line lengths short and readable.
- Let text breathe with comfortable line height and spacing.
- Avoid long walls of copy on mobile screens.

---

## Spacing & Layout

### Corner Radius

Roost uses soft rounding to remove harshness from the interface.

- **Small:** 10pt
- **Medium:** 12pt
- **Large:** 14pt
- **Extra Large:** 18pt
- **Full:** pill/capsule shapes where appropriate

### Spacing Philosophy

Space is one of the primary ways Roost feels calm.

- Cards should have generous internal padding.
- Lists should not feel cramped.
- Sections should have clear vertical rhythm.
- Dense information should be broken into digestible groups.

### Mobile Layout Rules

- Design portrait-first.
- Respect the safe area without wasting space.
- Prefer stacked layouts over compressed multi-column layouts.
- Use full-width cards and grouped sections that read comfortably while scrolling.
- Keep primary content near the top and primary actions easy to reach.

### Navigation Structure

For iPhone, the default navigation model is:

- **Tab bar** for top-level destinations
- **Navigation stack** for drill-down flows
- **Sheets** for focused creation and editing flows
- **Confirmation dialogs / alerts** for destructive or sensitive actions

---

## Borders, Surfaces, and Depth

### Borders

Borders should define space softly, never sharply.

- Use low-contrast warm borders.
- Standard border weight is 1pt.
- Inputs and cards should feel framed, not boxed in.

### Depth

Roost prefers soft layering over obvious elevation.

- Most depth should come from surface colour shifts and borders.
- Strong shadows should be rare.
- Sheets and modal content can use a slightly stronger shadow than in-line cards.

### Materials

If translucency is used, it should be subtle and warm. Avoid glassy, hyper-modern treatments unless they genuinely support the product and still feel like Roost.

---

## Motion & Animation

### Philosophy

Motion in Roost should feel calm, responsive, and quietly physical.

It exists to:

1. Confirm that something happened.
2. Preserve spatial continuity.
3. Make the interface feel cared for.

It should never slow common actions down.

### Timing

- **Major screen transitions:** around `0.35-0.4s`
- **Sheets and modals:** around `0.25s`
- **Buttons and taps:** around `0.15-0.2s`
- **List insertions/removals:** around `0.2-0.3s`
- **Theme or subtle state changes:** around `0.2-0.3s`

### Motion Patterns

**Screen transitions**

- Subtle fade with gentle vertical movement
- Enough movement to orient, not enough to feel theatrical

**Sheets**

- Fade + rise + slight scale
- Should feel like content arriving from below with softness

**Buttons**

- Tap scale down to roughly `0.98`
- Optional subtle spring back for physicality

**Lists**

- New items can stagger lightly
- Deletions should feel clean and quick
- Completion should visibly settle the row into a lower-emphasis state

**Completion states**

- Checked items can animate to reduced opacity
- Strikethrough should appear smoothly, not snap on

### Motion Rules

- Subtle over flashy
- Consistent over clever
- Fast enough to stay out of the way
- Always respect Reduce Motion

---

## Components & Interaction Patterns

### Buttons

Roost button styles should map to app intent clearly.

**Variants**

- **Primary:** terracotta fill, cream text
- **Secondary:** sage or muted supportive fill
- **Outline:** warm border with minimal fill
- **Ghost:** text-first, used sparingly
- **Destructive:** muted terracotta-red fill or text treatment

**Rules**

- Buttons should feel thumb-friendly
- Corner radius should be soft
- Press states should be visible
- Loading states should change the label inline rather than swapping to detached spinners where possible

### Cards

Cards are the main organisational container in Roost.

- Use cards to group related information
- Prefer a few generous cards over many tiny boxes
- Card padding should be comfortable
- Card titles should be clear and low-friction to scan

### Inputs

Inputs should feel calm and approachable.

- Warm input background
- Clear label above field where needed
- Soft focus emphasis in terracotta
- Helpful placeholder text, not vague placeholder-only forms

### Lists

Lists are central to Roost, especially shopping, chores, notifications, and activity.

- Rows should be easy to scan and easy to tap
- Swipe actions should be used where they feel native
- Secondary metadata should be visible but quiet
- Repeated actions should not require opening a detail screen if a row interaction can handle them

### Sheets

Sheets are the preferred mobile pattern for focused creation and editing tasks.

- Keep them narrow in purpose
- Avoid very long forms in a single sheet
- Use clear titles and one obvious primary action
- Dismissal should feel predictable and safe

### Empty States

Empty states should explain the value of the screen and gently invite the first action.

Structure:

- Warm icon or symbol
- Clear title
- Short, encouraging explanation
- Optional CTA

Tone:

- Never scolding
- Never overly chipper
- Always useful

### Loading States

- Prefer skeletons or inline progress where content shape matters
- Use full-screen spinners sparingly
- Preserve layout where possible to avoid jarring shifts

---

## Navigation Patterns

### Tab Bar

Roost uses a bottom tab bar for primary destinations.

- Keep tab count disciplined
- Use familiar SF Symbols
- Active state should feel clear but soft
- Labels should remain legible and not overly stylised

### Top Navigation

Top bars should stay light and native.

- Use standard navigation titles
- Avoid overloading the navigation bar with too many custom controls
- Place utilities only where they materially help

### Deep Navigation

Deeper flows should use standard push navigation, not custom transitions that fight iOS expectations.

---

## Haptics

Haptics matter on iPhone because they reinforce warmth and tactility.

Use them with restraint.

- **Light impact:** common button taps where physical feedback helps
- **Selection:** segmented controls, toggles, and lightweight state changes
- **Success:** completions, save confirmations, settle-up success
- **Warning/Error:** sparingly, only when the state truly warrants it

The user should notice that Roost feels responsive, not that it is vibrating constantly.

---

## Icons

On iOS, Roost should use **SF Symbols** as the primary icon language.

- Prefer simple, friendly, recognisable symbols
- Match symbol weight to text weight and screen density
- Icons should support comprehension, not decorate empty space
- When an icon is paired with text, the meaning should still be obvious without explanation

For avatar icon choices or mapped external icon sets, keep the resulting visual language consistent with SF Symbols.

---

## Accessibility

Accessibility is a product requirement, not a polish pass.

### Core Rules

- Support Dynamic Type cleanly
- Maintain WCAG AA contrast
- Ensure all tap targets are comfortably sized
- Use VoiceOver-friendly labels and traits
- Preserve meaning without relying on colour alone

### Motion

- Respect Reduce Motion
- Avoid large parallax or unnecessary animated flourishes
- Keep state changes understandable even with animation removed

### Structure

- Use clear heading hierarchy
- Label form inputs explicitly
- Keep gestures discoverable and backed by visible UI where possible

---

## Dark Mode Philosophy

Dark mode is a change in atmosphere, not a simple inversion.

Light mode should feel like daylight on warm materials.
Dark mode should feel like evening lamplight in the same home.

That means:

- Warm blacks, never pure black
- Cream text, never harsh white
- Terracotta remains confident and recognisable
- Cards separate from the background through tone, not glow

Dark mode should feel just as intentional as light mode, never like the neglected version.

---

## Responsive Behavior

The primary target is iPhone, but layouts should remain robust across:

- Smaller phones
- Larger Pro Max phones
- Dynamic Type changes
- Future iPad adaptation

### Rules

- Build vertically first
- Avoid relying on narrow assumptions about screen height
- Make cards and modules resilient to text expansion
- Keep major actions reachable on larger phones

iPad can extend the system later, but the iPhone experience is the source of truth.

---

## Data Visualization

Where Roost shows budgets, balances, or trends, charts should remain warm and readable.

### Principles

- Use the earthy chart palette
- Prefer simple charts over dense analytics
- Labels should be legible at a glance
- Tooltips and legends should feel like the rest of the app, not like imported analytics UI

### Progress Bars

- Green for safe
- Amber for warning
- Red for over-limit or destructive states
- Rounded ends
- Smooth width transitions

---

## Money Section Design Language

The Money section is the one place in Roost that can feel more professional and analytical than the rest of the app. It should still belong to the same warm household system, but the density, typography, and component rhythm should move closer to a modern budgeting product than a general home dashboard.

### Visual Thesis

Money should feel like a calm financial cockpit: compact, warm, precise, and trustworthy. It is not a bank, not a spreadsheet, and not a marketing dashboard.

### Competitive Research Notes

Current budgeting leaders converge on the same product patterns:

- **Monarch** uses a monthly cash-flow model, supports category and flex budgeting, and deliberately simplifies mobile budget columns to the values people need most: budgeted and remaining or actual. Source: https://help.monarch.com/hc/en-us/articles/360048883631-Creating-Your-Budget-in-Monarch
- **Monarch** also treats the dashboard as configurable widgets and has publicly called out improved information density, redesigned mobile cards, higher contrast, and collapsible budget sections. Sources: https://help.monarch.com/hc/en-us/articles/360058127551-Customize-Your-Dashboard and https://partners.monarchmoney.com/blog/monarch-brand-refresh
- **Copilot Money** leads its dashboard with monthly spending progress, free-to-spend context, recurring-payment awareness, and category bars that change colour based on spending pace. Sources: https://help.copilot.money/en/articles/6045480-dashboard-tab-overview and https://help.copilot.money/en/articles/9504513-categories-tab-overview
- **Rocket Money** emphasises spend allowance, category goal trackers, automatic categorisation, and alerts as users approach spending goals. Source: https://www.rocketmoney.com/feature/create-a-budget
- **YNAB** progress bars reinforce the value of seeing budget status at a glance rather than reading long explanations. Source: https://www.ynab.com/progress-bars/

Roost should borrow the useful behaviours, not the visual identity: clear spend pace, category status, cash-flow allocation, upcoming commitments, and compact trend comparison.

### Money Typography

Money uses the same DM Sans family, but with a tighter type scale.

- Page titles still follow the global page title system.
- Module labels: `10-11pt`, medium, uppercase only when acting as an analytical section label.
- Row labels: `12pt`, medium.
- Row values: `13-15pt`, medium.
- Supporting text: `11pt`, regular.
- Chart labels: `9-10pt`, medium.
- Avoid large explanatory paragraphs. If a sentence wraps more than twice inside a money module, shorten it.

### Money Layout Density

Money screens should be denser than Shopping, Home, and Plan.

- Prefer `10-12pt` internal module padding for analytical cards.
- Prefer `7-10pt` vertical spacing inside modules.
- Prefer `12pt` spacing between modules on overview-style pages.
- Use quiet cards for analytics. Borders and surface tone should carry structure; shadows should be minimal or absent.
- Avoid oversized empty-state boxes in Money. Empty states should be compact and action-led.
- Put the most decision-useful information first: pace, remaining, overspent, due soon, and month-over-month change.

### Money Components

Money components should feel custom and product-specific.

- Do not use visible native iOS controls for analytical modules: no default `ProgressView`, `DisclosureGroup`, default blue links, default segmented controls, or default dividers.
- Use custom hairlines, custom expand rows, custom progress bars, and custom loading skeletons.
- Keep progress bars slim: `4-6pt` for rows, `8-10pt` only for primary spend rings.
- Use colour as status, not decoration:
  - Sage: safe, under pace, positive.
  - Amber: approaching limit, due soon, needs attention.
  - Terracotta: primary brand action or neutral money emphasis.
  - Blue (`#337dd6`): money area accent for navigation, links, active analytical controls, and section rails.
  - Destructive red: over budget or genuinely negative.
- Category rows should show status faster than copy can explain it: dot, name, remaining or overage, slim progress bar.

### Money Copy

Money copy should be more operational than emotional.

- Good: “£42 left”, “Over £18”, “Due tomorrow”, “+12% vs last month”.
- Avoid: “You’re doing great”, “Build better habits”, “Stay on top of your finances”.
- Insights should be short and specific. Prefer one sentence under a primary metric.
- Do not repeat what the chart already says.

### Overview Page Direction

The Money Overview page should behave like a compact monthly briefing.

Order of priority:

1. Monthly spend pace and health.
2. Income allocation: fixed, lifestyle, unallocated.
3. Lifestyle category status.
4. Upcoming fixed costs.
5. Spend trend.
6. Month comparison.

Each module should answer one question:

- “How much of the month have we used?”
- “Where is income allocated?”
- “Which categories need attention?”
- “What is due soon?”
- “Is spending changing?”
- “What moved compared with last month?”

If a module cannot answer one of those questions in under one second, simplify it.

---

## Voice & Tone

Roost copy should sound like a thoughtful person, not a system.

### Principles

- Warm and conversational
- Clear and direct
- Encouraging, never scolding
- Human, never robotic

### Examples

- “All settled up” not “Balance: £0.00”
- “You’re owed £24.50” not “Your balance: +£24.50”
- “Nothing to pick up yet” not “No shopping items”
- “Let’s get your home set up” not “Initialize household”

---

## Product-Specific Guidance for iOS

### Auth

- Welcome, sign up, log in, and setup should feel especially simple
- Avoid overwhelming first-time users with too many choices at once
- Post-auth routing should feel immediate and obvious

### Shopping

- Optimise for speed
- Checking off an item should feel satisfying
- Adding an item should be friction-light
- Area accent: orange `#e9822a`. Use it for shopping rails, add-item focus states, suggestions, chips, and quick-action emphasis. Keep primary commitment buttons terracotta unless the interaction is a lightweight shopping-specific selection.

### Expenses

- Money screens should feel calm and trustworthy
- Use hierarchy to clarify who owes whom
- Never make critical balance information visually noisy
- Area accent: blue `#337dd6`. Use it for money navigation, selected analytical controls, money page links, month controls, chart emphasis, and compact section identity. Terracotta remains the app-wide primary CTA colour.

### Chores

- Completion states should feel rewarding
- Overdue items should be visible without turning the screen alarming
- Area accent: green `#2fae63`. Use it for chores rails, filters, progress, task setup highlights, room selection, and completion-adjacent UI. Keep overdue and destructive states semantic rather than green.

### Dashboard

- The dashboard should feel like a shared home snapshot, not a data control panel
- Each card should earn its space

### Settings

- Settings should feel tidy and understandable
- Group by real user mental models: profile, household, notifications, preferences, account

---

## Anti-Patterns

Do not drift into these patterns:

- Cold white backgrounds
- Default iOS blue as brand colour
- Overpacked screens
- Tiny tap targets
- Too many competing cards on one screen
- Excessive shadows or glossy effects
- Loud error states everywhere
- Overly playful copy that undermines trust
- Web-style dense admin layouts

---

## Roost Pro Design Language

Roost Pro is the paid tier of Roost. It should feel like a natural, elevated expression of the same product — not a jarring departure or a separate brand. The design language lifts the warmth and calm of Roost into something that feels quietly premium.

### Identity

- **Name:** Roost Pro (never "Nest" in user-facing copy — "nest" is only the DB wire value)
- **Symbol:** `sparkles` (SF Symbols) — ties to Hazel AI identity, reads as magical not hierarchical
- **Tagline:** "Your home, elevated."
- **Visual anchor:** The Pro copper-amber-champagne gradient (see ProPalette in DesignSystem.swift)

### The Pro Gradient

The defining visual motif of Roost Pro is a four-stop diagonal gradient within the Roost terracotta-amber family:

```swift
DesignSystem.ProPalette.gradient        // topLeading → bottomTrailing
DesignSystem.ProPalette.gradientH       // leading → trailing (for CTAs and text)
```

Use this gradient on:
- The Pro upsell sheet hero and feature cards
- The Pro hero section on the subscription page
- CTA buttons ("Start Your Free Trial", "Upgrade to Roost Pro")
- The `ProBadge` capsule component
- The `ProLockPill` for locked data

Never mix the Pro gradient with the standard Roost terracotta→sage gradient. Never use it on free-tier surfaces.

### Sparkles Motif

The `sparkles` SF Symbol is the Roost Pro icon. Use it:
- In the Pro upsell sheet hero alongside "Roost Pro"
- As the primary action button icon when upgrading
- In the More menu row for the Pro/Subscription destination
- In any Pro-branded surface where a symbol is needed

**Never use `crown.fill` for Pro** — it is removed from the design system.

### Pro Surface Treatment

Pro surfaces are always dark (`.colorScheme(.dark)` applied at the surface level). Key tokens:
- Background: `Color.proBg` (#0C0A08)
- Card: `Color.proCard` (#1E1A16)
- Feature icon containers: `Color.proCopper.opacity(0.15)` fill
- Feature icons: `Color.proAmber`
- Headlines: `Color.proWarmWhite`
- Body text: `Color.proBodyText`
- Muted: `Color.proMutedText`
- Borders: `Color.proAmber.opacity(0.12–0.18)`

### Lock State / Pro Badge

Free users encountering Pro-gated features should see:
1. The feature icon in a `proCopper.opacity(0.15)` circle
2. A `ProBadge()` component inline with the feature title
3. The feature description in `proMutedText`

The gate should feel informative, not punishing. Free users should understand what they are missing without feeling blocked or scolded.

### Upsell Sheet

The `ProUpsellSheet` (accessed via `.proUpsell(isPresented:feature:)` modifier) is the primary Pro conversion surface:

- Presented as a `.fraction(0.68)` detent with `.large` fallback
- `presentationCornerRadius(24)` for a modern, app-store-quality modal feel
- Header: full-bleed gradient strip with crown icon + "Roost Pro" in white
- Locked feature card: explains what the user was trying to access
- Features list: "Everything in Roost Pro" with checkmarks in `roostPrimary`
- Primary action: direct to Stripe checkout with `crown.fill` icon
- Secondary action: navigate to the Pro page ("See all features →")

### Subscription Page (Roost Pro)

The subscription page is titled "Roost Pro" and leads with a full-width gradient hero card. Sections:

1. **Gradient hero card** — "Roost Pro" wordmark with crown + subtitle
2. **Current plan card** — `RoostHeroCard` tinted by subscription state
3. **Trial banner** — visible for free users who haven't used trial, and active trial users
4. **Free vs Roost Pro comparison** — feature groups with colored chips
5. **Plan selector** — Monthly/Annual cards with radio-style selection
6. **Primary action** — upgrades, portal access, or status indicators
7. **Promo code** — collapsible
8. **FAQ** — collapsible

### Copy Principles for Pro

- Use "Roost Pro" (never just "Pro" alone in sentence-starting contexts, never "Nest")
- Use "Upgrade to Roost Pro" (not "Go Pro" or "Unlock Pro")
- Use "per household" — Roost Pro applies to the whole home
- Trial language: "14-Day Free Trial" — be specific, not vague
- Stripe references: be transparent about the payment partner

### More Menu

The Roost Pro row in the More menu uses:
- Icon: `crown.fill`
- Background: `Color.roostPrimary.opacity(0.15)`
- Color: `Color.roostPrimary`

This makes the Pro row distinctly warm and intentional among the standard settings rows.

---

## Summary

Roost on iPhone should feel like a digital extension of a shared home.

It should be:

- **Warm** over sterile
- **Soft** over sharp
- **Native** over web-like
- **Calm** over hectic
- **Human** over mechanical
- **Useful** over decorative

If a design decision is unclear, ask:

**Does this feel like home on iPhone?**
