# Roost Figma Handoff: Home + Shopping

Use this as the single source of truth when redesigning the `Home` and `Shopping` screens in Figma AI.

The goal is to improve hierarchy, composition, and polish without changing the app's visual language.

## 1. Non-Negotiables

- Do not redesign the bottom tab bar.
- Do not change the app's fonts.
- Do not invent a new spacing system.
- Do not invent a new color palette.
- Do not add new navigation patterns or gestures.
- Do not make the pages feel like a different app.
- Keep everything feasible for SwiftUI on iPhone.

## 2. Visual Direction

Roost is:
- warm
- domestic
- tactile
- calm
- practical
- premium but not flashy

Avoid:
- cold fintech UI
- glossy gradients everywhere
- glassmorphism
- neon accents
- oversized hero art
- overly playful grocery-app styling
- ultra-dense productivity dashboards

## 3. Locked Design Tokens

### Colors

- Background: `#EBE3D5`
- Foreground: `#3D3229`
- Card: `#F2EBE0`
- Primary: `#D4795E`
- Secondary: `#9DB19F`
- Muted: `#DDD4C6`
- Muted text: `#6B6157`
- Accent: `#E8D5BC`
- Success: `#7FA087`
- Warning: `#E6A563`
- Destructive: `#C75146`

### Typography

Use only:
- `DM Sans Regular`
- `DM Sans Medium`

Type scale:
- Page title: `26`
- Section heading: `20`
- Card title: `17`
- Body: `15`
- Label: `13`
- Caption: `12`
- Meta / micro: `11`
- Tab label: `10`

### Radius

- Small controls: `10`
- Standard cards: `14`
- Large hero cards: `18`
- Pills: full

### Spacing

Only use this spacing rhythm:
- `8`
- `12`
- `16`
- `20`
- `24`
- `32` only when clearly needed between major blocks

### Sizing

- Frame width: `390`
- Minimum tap target height: `44`
- Bottom tab bar height: `49`
- Side padding for page content: `20`

## 4. Shell Rules

These must stay consistent with the rest of the app.

- Keep the existing bottom tab bar exactly as-is.
- Respect iPhone safe areas.
- Leave visual breathing room above the tab bar.
- The page content sits inside a `390pt` wide phone frame.
- Use `20pt` horizontal page padding.
- Keep a warm neutral background, not white.
- Cards should feel soft, layered, and understated.
- Borders should be subtle.
- Shadows should be soft and low contrast.

## 5. Motion Rules

Design with these motion intentions in mind:
- Screen transitions should feel soft and purposeful.
- Card and list entrances can use subtle stagger.
- Tab switching is a pill slide, not a hard jump.
- Button press feedback should feel tight and tactile.
- Check/toggle interactions should feel springy, not bouncy-cartoon.

Do not design interactions that depend on complex custom gestures.

## 6. Existing Component Language To Match

Match these patterns:
- rounded cards with subtle border and soft shadow
- calm page headers with strong title and lighter subtitle
- warm terracotta used as the main emphasis color
- muted sage and amber used as secondary support colors
- list rows with gentle surfaces, not flat separators only
- pills/chips for status and counts
- 44pt minimum controls

## 7. What Can Change

Figma AI is allowed to improve:
- hierarchy
- composition
- section ordering
- card layouts
- stat block layout
- shopping category grouping
- empty states
- density and breathing room
- visual rhythm

Figma AI is not allowed to change:
- overall app shell
- tab bar pattern
- font family
- core color palette
- spacing scale
- radius language
- primary interaction model

## 8. Screen-Specific Guidance

### Home

The Home screen should feel like a polished shared household overview.

Priorities:
- clearer top-level hierarchy
- stronger hero block for the most important household state
- cleaner grouping of money, shopping, chores, and recent activity
- reduce the feeling of stacked generic cards
- make the screen feel intentional, editorial, and calm

Home should communicate:
- what matters today
- what needs attention next
- shared household status at a glance

### Shopping

The Shopping screen should feel practical, fast, and satisfying to scan.

Priorities:
- clearer hierarchy between next shop date, item groups, and actions
- better category grouping
- better treatment for incomplete vs complete items
- stronger empty and all-done states
- improved row rhythm so the list feels designed, not default

Shopping should communicate:
- what to buy now
- how close the list is to done
- when the next shop is
- household context, but without clutter

## 9. Figma Frame Setup

Create one reusable base frame before generating concepts:

- iPhone frame width: `390`
- background fill: `#EBE3D5`
- top safe area respected
- side padding guides at `20`
- reserve bottom area for the existing tab bar
- keep content clear of the bottom bar

Then generate all Home and Shopping concepts inside that same shell.

## 10. Deliverable Format

Ask Figma AI for:
- 2 Home screen concepts
- 2 Shopping screen concepts
- all concepts inside the same shell
- same tokens across every concept
- same tab bar and page width

Then choose one direction and refine it, rather than mixing multiple directions.

## 11. Copy-Paste Prompt For Figma AI

```text
Redesign the Home and Shopping screens for an existing iOS app called Roost.

Important: this is a redesign inside an existing design system, not a new visual identity.

Follow these rules exactly:

- Keep the current app shell and bottom tab bar pattern unchanged.
- Use only DM Sans Regular and DM Sans Medium.
- Use this color system:
  - Background #EBE3D5
  - Foreground #3D3229
  - Card #F2EBE0
  - Primary #D4795E
  - Secondary #9DB19F
  - Muted #DDD4C6
  - Muted text #6B6157
  - Accent #E8D5BC
  - Success #7FA087
  - Warning #E6A563
  - Destructive #C75146
- Use only these radii:
  - 10 for controls
  - 14 for cards
  - 18 for hero cards
- Use only these spacing values:
  - 8, 12, 16, 20, 24, 32
- Use a 390pt iPhone frame.
- Keep page side padding at 20pt.
- Keep controls at 44pt minimum height.
- Respect iPhone safe areas.
- Leave room for an existing 49pt bottom tab bar.
- Keep the app feeling warm, calm, domestic, tactile, and premium.
- Do not introduce a new visual style.
- Do not use cold fintech styling, glassmorphism, neon accents, or generic startup gradients.
- Keep everything feasible to implement in SwiftUI.

Design goals for Home:
- create a stronger sense of hierarchy
- improve composition and grouping
- make the shared household overview feel premium and intentional
- make “today”, key stats, and recent activity easier to scan

Design goals for Shopping:
- improve list scanability
- create stronger category grouping
- better separate active vs completed states
- make the next shopping date and progress feel more intentional
- improve empty and all-done states

Output:
- 2 Home screen concepts
- 2 Shopping screen concepts
- all in the same visual system
- keep the tab bar and shell consistent across all concepts
```

## 12. Refinement Prompt After You Pick A Direction

Use this after choosing one concept:

```text
Refine this concept without changing the visual system.

Keep:
- same shell
- same tab bar
- same fonts
- same colors
- same spacing scale
- same radii

Improve:
- alignment consistency
- spacing rhythm
- visual hierarchy
- scanability
- clarity of primary actions
- consistency with a warm, premium household app

Do not invent new components unless necessary.
Prefer improving composition using the existing language.
```

