# Roost — Design Ethos V2

**Document created:** 16 April 2026
**Scope:** All Roost platforms — iOS, macOS, web
**Status:** Living document. Update when the design language evolves.

---

## 1. Philosophy

Roost is a home management app for couples and households. The design should feel like the product itself: warm, reliable, and personal — not sterile or corporate. Every decision should reduce friction and build trust between the people using it together.

**Core principles:**

1. **Warmth over polish.** The colour palette, typography, and motion should feel inviting and human. Avoid cold greys and clinical whites.
2. **Clarity through hierarchy.** Information is structured so the most important thing on any screen is immediately obvious. Scale, weight, and colour all serve hierarchy — nothing decorative adds noise.
3. **Motion with meaning.** Animations are spring-based and feel physical. They signal state, guide attention, and reward interaction. They are never purely decorative.
4. **Consistency creates trust.** Repeated spacing, radius, type scale, and interaction patterns make the interface learnable. Surprising the user is always a mistake.
5. **Feature cohesion.** Each section of the app (Money, Chores, Shopping, etc.) has its own identity colour, but all share the same underlying component and layout language. The app reads as one product, not a collection of features.
6. **Accessible by default.** Contrast, touch targets, motion reduction, and semantic structure are not afterthoughts — they are built into every component.

---

## 2. Colour

### 2.1 Background & Surface

| Token | Light | Dark | Usage |
|---|---|---|---|
| Background | `#EBE3D5` | `#0F0D0B` | Page/screen background |
| Card | `#F2EBE0` | `#1A1816` | Component surfaces, cards |
| Muted | `#DDD4C6` | `#2A2623` | Secondary surfaces, dividers, skeletons |
| Input | `#E8D5BC` | `#2A2623` | Form field backgrounds |

The background is warm — never pure white or pure black. The warmth persists in both light and dark modes; dark mode uses deep charcoal-brown rather than neutral black.

### 2.2 Foreground

| Token | Light | Dark | Usage |
|---|---|---|---|
| Foreground | `#3D3229` | `#F2EBE0` | Primary text |
| Muted Foreground | `#3D3229` @ 45% | `#F2EBE0` @ 45% | Secondary text, captions, labels |
| Hairline | `#3D3229` @ 15% | `#F2EBE0` @ 10% | Borders, dividers, strokes |

### 2.3 Brand & Semantic Colours

| Token | Light | Dark | Usage |
|---|---|---|---|
| Primary (Terracotta) | `#D4795E` | `#D4795E` | Primary actions, links, selection |
| Secondary (Sage) | `#9DB19F` | `#7A8C7C` | Supporting actions, success indicators |
| Destructive | `#C75146` | `#C75146` | Delete, error, critical warnings |
| Warning | `#E6A563` | `#E6A563` | Caution, amber states |
| Success | `#7FA087` | `#7FA087` | Completion, positive confirmation |
| Ring/Focus | `#D4795E` @ 30% | `#D4795E` @ 30% | Focus rings, selection highlights |

### 2.4 Feature Accent Colours

Each major feature has a dedicated accent colour used for tints, hero gradients, and active states. The accent is applied at reduced opacity on backgrounds (8–13%) and at full opacity on icons and highlights.

| Feature | Light | Dark |
|---|---|---|
| Money | `#337DD6` | `#5B9BE8` |
| Shopping | `#E9822A` | `#F39A3D` |
| Chores | `#2FAE63` | `#45C978` |
| Calendar | (uses primary terracotta) | (uses primary terracotta) |
| Pinboard | (uses primary terracotta) | (uses primary terracotta) |

### 2.5 Data Visualisation Palette

Used in charts, spending breakdowns, and category colour coding. Applied in order:

1. `#D4795E` — Terracotta (primary)
2. `#9DB19F` — Sage (secondary)
3. `#E6A563` — Amber (warning)
4. `#7A9199` — Slate
5. `#7FA087` — Moss (success)

### 2.6 Avatar Palette

12 distinct colours for user avatars and identity indicators:

`#D4795E` · `#9DB19F` · `#E6A563` · `#C17A6F` · `#7A9199` · `#A08AB8` · `#C4789A` · `#8B9E7D` · `#B88872` · `#7A8FA1` · `#C9A77C` · `#8A7B6F`

### 2.7 Colour Usage Rules

- Never use pure black (`#000000`) or pure white (`#FFFFFF`) as surfaces or text.
- Never introduce a colour not in this palette without updating this document.
- Feature accent colours must not bleed into other features — Money blue should never appear in Chores, for example.
- Auth screens are always forced to dark mode, regardless of system preference.
- Use opacity layering (e.g. `tint @ 0.10`) for tinted backgrounds rather than mixing a new colour.

---

## 3. Typography

### 3.1 Font Family

**DM Sans** is used exclusively across all platforms. It is a low-contrast, geometric sans-serif with a friendly, modern character that complements the warm colour palette.

- Do not use any system font (San Francisco, Helvetica) in product UI.
- Do not mix in a serif or display typeface without a deliberate decision and update to this document.

### 3.2 Type Scale

| Role | Size | Weight | Relative Style | Usage |
|---|---|---|---|---|
| Hero Number | 34px | Bold | Large Title | Large statistics, key figures, money amounts |
| Large Greeting | 28px | Bold | Title 1 | Page hero greetings, welcome headings |
| Page Title | 26px | Bold | Title 2 | Page and section titles |
| Section Heading | 20px | Bold | Title 3 | Section breaks within a page |
| Card Title | 17px | Semibold | Headline | Card and component headers |
| Body | 15px | Regular | Body | Standard readable content |
| Label | 13px | Medium | Callout | Buttons, tags, form labels |
| Caption | 12px | Regular | Caption | Secondary info, timestamps |
| Micro / Meta | 11px | Medium | Caption 2 | Badges, eyebrow labels, tracking text |
| Tab Label | 10px | Medium | Caption 2 | Navigation tabs |

### 3.3 Tracking & Spacing

- Eyebrow labels (e.g. "MONTHLY MONEY", "COMING UP") are set in **Micro** with `+1.0–1.5px` letter-spacing and **ALL CAPS**.
- Body and Label styles use default tracking (0).
- Invite codes and reference numbers use `+2px` tracking for readability.

### 3.4 Rules

- Text is always left-aligned in lists and cards. Centre-alignment is reserved for auth screens, empty states, and modal confirmations only.
- Minimum scale factor of `0.72` is allowed for hero text that might overflow. Never truncate hero figures.
- Line limit of `1` on labels and captions. Body and descriptions allow `2–3` lines, with expansion controls where needed.

---

## 4. Spacing

### 4.1 Core Scale

| Token | Value | Usage |
|---|---|---|
| Micro | 4px | Tightest gaps, icon-to-label |
| xs | 6px | Compact row gaps |
| sm | 8px | Standard inline gaps |
| md | 12px | Component internal padding |
| lg | 16px | Card padding, section gaps |
| xl | 20px | Large section padding |
| xxl | 24px | Block separation |
| xxxl | 32px | Page-level separation |

### 4.2 Layout Constants

| Token | Value | Notes |
|---|---|---|
| Page Horizontal Inset | 16px | Left/right margin on all screens |
| Card Padding | 16px | Default padding inside cards |
| Card Padding Large | 20px | Hero cards and prominent surfaces |
| Screen Bottom | 32px | Safe area bottom clearance |
| Tab Content Bottom Inset | 20px | Additional scroll clearance above tab bar |
| Status Bar Inset | 6px | Additional top clearance below status bar |

### 4.3 Rules

- All spacing values must come from the scale above. Arbitrary pixel values are not permitted.
- Nested components (a card inside a card) reduce inset by one step (e.g. 16px outer → 12px inner).
- Horizontal lists and rails use `8px` gap between items.
- Vertical content stacks inside cards use `8–12px` gap between rows.

---

## 5. Shape & Corner Radius

### 5.1 Radius Scale

| Token | Value | Usage |
|---|---|---|
| xs | 8px | Small buttons, chips, badges |
| sm | 10px | Input fields, toggles, minor elements |
| md | 14px | Standard cards, list rows |
| lg | 18px | Larger cards, bottom sheets |
| xl | 22px | Hero sections, prominent feature cards |
| Full / Pill | 999px | Capsule buttons, avatar circles, progress pills |

### 5.2 Curve Style

All rounded shapes use a **continuous curve** (equivalent to iOS `squircle` or CSS `path-based` rounding). This produces smoother transitions at the corners compared to standard circular rounding and is the defining geometric characteristic of Roost's visual language.

### 5.3 Rules

- Never mix standard circular rounding with continuous curves in the same component.
- Icon containers are always circles (radius `full`) unless part of a card grid.
- Sheet/modal containers use `xl` radius on top corners only.
- Buttons use `xs–sm` for inline/compact sizes, `md` for standard height.

---

## 6. Iconography

### 6.1 System

Icons are sourced from **SF Symbols** (Apple's system icon library). This ensures visual consistency with platform conventions and automatic support for weight and scale variations.

On non-Apple platforms (web, future Android), equivalent icons should be sourced from **Lucide** (lucide.dev), which maps 1:1 to the SF Symbols vocabulary used in Roost.

### 6.2 Sizing

| Context | Size |
|---|---|
| Tab bar icons | 22–24px |
| Card / section action icons | 20px |
| Row leading icons | 18–20px |
| Badge / meta icons | 12–14px |
| Hero/empty state icons | 28–40px |
| Auth logo glyph | 36px |
| Auth logo mark | 60px |
| Navigation (close/back) | 16–18px |

### 6.3 Icon Containers

Icons in cards and rows are placed in **circle containers** with a tinted background:

- Container size: 30–56px depending on context (30px for row icons, 42px for section icons, 56px for setup/onboarding)
- Background: feature tint or semantic colour at `0.10–0.13` opacity
- Icon colour: feature tint or semantic colour at full opacity
- Container shape: circle (radius `full`)

### 6.4 Feature Icons

| Feature | Icon |
|---|---|
| Home | `house.fill` |
| Money | `dollarsign.circle.fill` or `chart.bar.fill` |
| Shopping | `cart.fill` |
| Chores | `checkmark.circle.fill` |
| Calendar | `calendar` |
| Pinboard | `pin.fill` |
| Settings | `gearshape.fill` |

### 6.5 Rules

- Icons in primary actions (buttons, CTAs) always sit to the **left** of the label.
- Never use an icon alone in a tappable element without either a label or an accessibility label.
- Icon weight matches the surrounding text weight where possible (e.g. `.medium` body text → `.medium` icon weight).

---

## 7. Motion & Animation

### 7.1 Philosophy

All animation uses **spring physics** as the default model. Springs feel physical and alive — they overshoot slightly and settle naturally. Ease-in/out curves are reserved for progress fills and loading states only.

All animations must be disabled or replaced with simple opacity fades when `accessibilityReduceMotion` is active.

### 7.2 Named Animations

| Name | Response | Damping | Usage |
|---|---|---|---|
| Page Transition | 0.42s | 0.84 | Full screen transitions, major state changes |
| Modal Transition | 0.32s | 0.88 | Bottom sheets, modal presentations |
| Button Press | 0.18s | 0.62 | Scale-down on press, immediate |
| Button Release | 0.26s | 0.68 | Scale-up on release, hint of life |
| List Appear | 0.38s | 0.82 | List item insertions, content loads |
| Progress Fill | 0.50s | 0.84 | Progress bars and rings |
| Tab Switch | 0.30s | 0.76 | Tab bar pill sliding |
| Checkmark | 0.28s | 0.52 | Completion bounce (chores, shopping) |

**Aliases for common use:**
- `smooth` → Page Transition
- `snappy` → Button Release
- `easeOut` → Modal Transition
- `spring` → Button Press

### 7.3 Entrance Patterns

Content entering the screen animates with:
- **Opacity:** 0 → 1
- **Vertical offset:** +18–20px below final position → 0
- **Scale:** 0.98 → 1.0 (optional, used in cards and modals)
- **Stagger:** 0.04s delay multiplier per item index

List-based content staggers entrance so items appear sequentially from top to bottom. Maximum practical stagger is 6 items (items beyond this appear immediately).

### 7.4 Interaction Feedback

- **Button tap:** Scale to `0.96–0.98` on press, spring back on release
- **Checkmark completion:** Scale pulse `1.0 → 1.15 → 1.0`, success colour flash
- **Deletion:** Slide out with opacity fade, vertical collapse of space
- **Toggle:** Spring-driven thumb translation
- **Tab switch:** Pill slides horizontally to new position

### 7.5 Loading & Progress

- Circular progress rings animate on appearance with a 0.8s ease-out after a 100ms delay (waits for cached data before animating)
- Progress bar fills animate with the Progress Fill spring
- Skeleton loaders are static (no shimmer) — simple card-coloured rectangles

### 7.6 Haptics

| Event | Haptic Type |
|---|---|
| Button tap | Impact — Light |
| Destructive action | Impact — Medium |
| Toggle, checkbox | Selection |
| Success confirmation | Notification — Success |
| Error / validation fail | Notification — Error |
| Warning | Notification — Warning |

---

## 8. Components

### 8.1 Cards

The primary container for all content groups. Cards sit on the `Card` surface colour against the `Background` colour.

**Anatomy:**
- Background: `Card`
- Border: 1px `Hairline`
- Corner radius: `md` (14px) standard, `xl` (22px) for hero cards
- Padding: 16px standard, 20px large
- Shadow: `black @ 3.5% opacity`, `10px radius`, `4px y-offset`

Cards never nest more than one level deep. A card inside a card uses a `Muted` background instead.

### 8.2 Page Headers

Every screen has a consistent header structure:

- **Title:** Large Greeting or Page Title weight
- **Subtitle:** Body weight, Muted Foreground colour
- **Action (optional):** Right-aligned CTA button (primary colour, label weight)

Headers are not navigation bars — they scroll with the content. The top of the screen uses a 3px gradient accent line in the feature's tint colour (opacity `0.72 → 0.28`, left to right).

### 8.3 Hero Cards

The primary feature summary card at the top of Money, Shopping, and Chores home screens.

**Anatomy:**
- 3px top gradient accent line (feature tint `0.72 → 0.28`)
- Eyebrow label (Micro, ALL CAPS, +1px tracking, feature tint)
- Hero figure (Hero Number, 34px bold)
- Supporting stats in smaller rows below
- Progress ring or bar (right-aligned or below)
- Subtle blob: feature tint at `0.11` opacity, `32px` blur, offset top-trailing
- Border: 1px hairline
- Radius: `xl` (22px)

### 8.4 Stat Tiles

Small information tiles used in status rails and dashboards.

- Size: flexible width, fixed height ~70px
- Icon circle: 30px, tinted background `0.10` opacity
- Value: Card Title weight
- Label: Micro weight, Muted Foreground
- Padding: 12px
- Radius: `lg` (18px)
- Border: 1px hairline

### 8.5 Action Buttons

**Primary:**
- Background: feature tint or primary terracotta
- Text: Card (inverse foreground)
- Height: 44px
- Radius: `sm–md` depending on context
- Weight: Label (13px medium)

**Ghost / Outline:**
- Background: transparent
- Border: feature tint at `0.20–0.30` opacity
- Text: feature tint
- Same height and radius as primary

**Destructive:**
- Background: destructive red at `0.10` opacity
- Text: destructive red
- Used in confirmations and context menus only

**Pill / Capsule:**
- Radius: `full` (999px)
- Used for filter chips, status badges, and biometric prompts

### 8.6 Filter Pills

Horizontal scrolling row of category/status filters.

- Selected: feature tint background, Card foreground text
- Unselected: transparent background, Muted Foreground text
- Padding: `6px × 12px`
- Radius: `full`
- Gap between pills: `8px`

### 8.7 List Rows

Standard item rows within cards or lists.

- Height: 44–52px typical
- Leading: 36–42px icon circle
- Content: title (Label weight) + optional subtitle (Caption, Muted Foreground)
- Trailing: optional badge, chevron, or action button
- Divider: `Hairline` colour, 1px, offset left by icon width + gap
- Context menu on long-press for destructive actions

### 8.8 Form Fields

- Height: 44px
- Background: `Input` colour
- Radius: `sm` (10px)
- Padding: 12px horizontal
- Label above field: Caption weight, Muted Foreground
- Error state: destructive border, error message below in Caption

### 8.9 Empty States

Shown when a list or section has no content.

- Icon circle: 40px, tinted background `0.10` opacity
- Message: Body weight, Muted Foreground, centred
- Optional CTA below
- Full card background with hairline border

### 8.10 Progress Rings

Circular progress used in hero cards.

- Outer track: `Muted` colour, 8px stroke width
- Progress arc: feature tint, 8px stroke, rounded line caps
- Start angle: -90° (12 o'clock)
- Animation: 0.8s ease-out on appearance
- Centre content: percentage or key figure in Card Title weight

### 8.11 Bottom Sheets / Modals

- Radius: `xl` on top two corners only
- Background: `Card`
- Handle: 36px × 4px, `Muted` colour, centred at top with 8px top padding
- Shadow: `black @ 15%`, 60px radius, 20px y-offset
- Dismiss: drag down or tap outside (where appropriate)

### 8.12 Toast Notifications

- Capsule shape (radius `full`)
- Background: Foreground colour
- Text: Card colour (inverted)
- Position: bottom of screen, above tab bar + content inset
- Duration: 3s auto-dismiss
- Appear/disappear with opacity + vertical spring

---

## 9. Feature-Specific Design Language

### 9.1 Auth & Onboarding

- Always displayed in **dark mode**, regardless of system setting
- Full-screen atmospheric background: three floating gradient orbs (terracotta and amber) with slow drift animations (`18–28s` duration loops)
- Staggered entrance: hero content appears first (0.05s delay), form card second (0.18s), action buttons last (0.28s)
- Form cards use frosted glass treatment: `Card` background at `88%` opacity + `1px white border @ 7%` opacity + soft shadow
- Auth logo: wordmark centred at top, 60px mark + 36px glyph
- Setup/onboarding flow uses progress dots (8px active, 6px inactive) at top of screen
- Step transitions: asymmetric — current step exits left, new step enters from right

### 9.2 Home Dashboard

- Greeting with time-of-day personalisation (Good morning / afternoon / evening)
- Quick-access tiles for all features in a 2×2 or scrolling grid
- Each tile carries the feature accent colour

### 9.3 Money

- Hero card with remaining budget as the primary figure (Hero Number size)
- Stat rows below: Income, Spent, Remaining, Estimated Surplus
- Circular progress ring (right side of hero): tracks % of income spent
- Colour coding of remaining amount: green (>30% remaining) → amber (10–30%) → red (<10% or over)
- Category spending bars below: filled to % of budget
- "Scramble mode" banner when amounts are hidden
- Balance strip when a settlement is outstanding between household members

### 9.4 Shopping

- Hero card: item completion count + progress ring (items in basket / total)
- Items grouped by category, each category collapsible
- Item rows: checkbox (tappable) left, name + quantity centre, assigned-to right
- "All in basket" state: category header shows cart icon with success tint
- Next shop date shown as urgency chip: red if overdue, amber if ≤3 days, tint if future
- Completed items dock at bottom of list

### 9.5 Chores

- Items grouped by status: Upcoming → Due Today → Overdue → Completed
- Assignment shown as "Me" or partner name badge
- Checkmark completion triggers bounce animation + success haptic
- Overdue items highlighted with destructive colour
- "Suggest chores" AI flow uses a modal bottom sheet

### 9.6 Calendar

- Month navigator: previous/next arrow buttons in circle containers
- Weekday column headers: single character (M, T, W...), Micro weight, Muted Foreground
- Day cells: 34px circles
  - Today: primary tint outline stroke
  - Selected: primary tint filled background, Card text
  - Other month: reduced opacity
- Event dots beneath each day cell: up to 3, colour-coded by event type
- Event rows below calendar: icon circle left, title + date centre, status badge right
- Overdue events: left red accent bar

### 9.7 Pinboard

- Status rail: "Live" count + "Unseen" count as stat tiles
- Note rows inside cards
- Unacknowledged notes: left accent bar in primary tint
- Acknowledged notes: left accent bar in hairline colour
- Author name + audience icon at top of each note
- Long notes truncate with "See more / See less" toggle
- Notes from a partner include an acknowledgement action button

---

## 10. Accessibility

### 10.1 Contrast

- All body text on its background meets WCAG AA minimum (4.5:1).
- Muted foreground text meets WCAG AA for large text (3:1).
- Avoid placing Muted Foreground text on Muted backgrounds (insufficient contrast).

### 10.2 Touch Targets

- All interactive elements are at minimum `44 × 44px`.
- Icon-only buttons that appear smaller visually must have their hit area expanded to 44px via content shape or padding.

### 10.3 Reduce Motion

When the system's `Reduce Motion` accessibility setting is enabled:
- All spring entrance animations are disabled
- Content appears instantly at full opacity
- Progress rings appear at their final state without animation
- Pulsing effects (loading shields, animated orbs) become static
- Stagger delays are removed

### 10.4 Dynamic Type

All type styles map to a Dynamic Type relative category (see §3.2). Layouts must not clip or truncate text when the system font size is increased. Use minimum scale factors as a last resort, not a first.

### 10.5 Labels & Semantics

- Every icon-only interactive element has an accessibility label.
- Progress indicators have descriptive accessibility labels (e.g. "65% of budget spent").
- Destructive actions in context menus are marked as destructive.
- Tab bar items have labels (not just icons) even when the label is visually small.

---

## 11. Dark Mode

- Dark mode uses deep warm charcoal (`#0F0D0B` background), not neutral grey or black.
- All colour tokens have explicit light and dark values — no automatic opacity inversions.
- Feature accent colours are slightly lighter in dark mode to maintain vibrancy against dark backgrounds (e.g. Money blue shifts from `#337DD6` to `#5B9BE8`).
- Auth screens are always dark, regardless of system setting.
- Cards and surfaces maintain their warm undertone in dark mode (`#1A1816`).
- Hairline borders reduce opacity in dark mode (15% → 10%) to avoid harshness.

---

## 12. Writing Style (UI Copy)

- **Concise.** Labels, buttons, and headings are as short as possible while remaining clear.
- **Warm, not cute.** Copy is friendly and direct. It is never sarcastic, never uses excessive exclamation marks, never talks down to the user.
- **Sentence case** on all UI text except eyebrow labels (which are ALL CAPS).
- **No full stops** on labels, buttons, or single-line headings.
- **Full stops used** in body copy, descriptions, and multi-sentence explanations.
- Empty states are descriptive and action-oriented: "No chores yet — tap + to add one." not just "No items."
- Error messages tell the user what to do, not just what went wrong.

---

## 13. What Roost Does Not Do

These are explicit anti-patterns. If a design proposal involves any of these, it should be challenged.

- No pure white or pure black surfaces
- No San Francisco / system font in product UI
- No arbitrary spacing values (use the scale)
- No decoration without function (gradients, blurs, and shadows only appear where they serve depth or hierarchy)
- No cold colour temperatures in backgrounds or cards
- No non-spring ease curves for interactive elements
- No icon-only buttons without accessibility labels
- No shadows stronger than `black @ 15%` on surfaces
- No full-screen overlays without a clear dismiss action
- No feature accent colours appearing in a different feature's UI

---

*End of document. All changes to this design language should be reflected here before being applied in product.*
