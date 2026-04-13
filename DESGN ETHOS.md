# Roost Design Ethos

**A comprehensive guide to the design philosophy, visual language, and interaction patterns that make Roost feel like home.**

---

## Philosophy

Roost is a household management app for couples that prioritizes **warmth over sterility, comfort over corporate, and coziness over clinical**. The design is inspired by the video game *Hozy*, embodying the feeling of a well-lived home—soft, inviting, organic, and human. Every design decision, from color to spacing to animation timing, reinforces the idea that managing a household together should feel joyful and effortless, not like work.

---

## Color System

### Inspiration
The color palette is drawn from warm, earthy tones found in cozy homes: terracotta pottery, sage plants on windowsills, cream linen, warm wood, and natural light filtering through curtains.

### Light Mode Palette

**Foundation Colors:**
- **Background:** `#ebe3d5` - A noticeably warm cream, never pure white. This is the canvas that wraps everything in warmth.
- **Foreground:** `#3d3229` - Warm dark brown instead of black. Text feels organic and printed, not digital.
- **Card:** `#f2ebe0` - Very creamy off-white for elevated surfaces. Still warm, never stark.

**Semantic Colors:**
- **Primary (Terracotta):** `#d4795e` - The heart of the app. A warm coral-terracotta that feels inviting and approachable, never aggressive or loud. Used for CTAs, active states, and moments of importance.
- **Secondary (Sage):** `#9db19f` - A soft, muted sage green that brings balance and calm. Used for secondary actions and supportive UI elements.
- **Muted:** `#ddd4c6` - Warm neutral background for subtle emphasis.
- **Muted Foreground:** `#6b6157` - For secondary text that needs to recede gently.
- **Accent:** `#e8d5bc` - A warm peachy-amber for hover states and subtle highlights.

**Status Colors:**
- **Success:** `#7fa087` - Forest green, natural and reassuring.
- **Warning:** `#e6a563` - Warm amber that suggests attention without alarm.
- **Info:** `#9db19f` - Uses the sage secondary color.
- **Destructive:** `#c75146` - A muted terracotta-red. Even destruction feels warm, not harsh.

**Chart Colors:**
1. `#d4795e` - Terracotta
2. `#9db19f` - Sage
3. `#e6a563` - Warm amber
4. `#b88b7e` - Clay pink
5. `#7fa087` - Forest green

### Dark Mode Palette

**Foundation Colors:**
- **Background:** `#0f0d0b`
- **Foreground:** `#f2ebe0`
- **Card:** `#1a1816`

**Semantic Colors:**
- **Primary:** `#d4795e`
- **Secondary:** `#7a8c7c`
- **Muted:** `#2a2623`
- **Muted Foreground:** `#a39a8f`
- **Accent:** `#2a2623`

---

## Typography

### Font Family
**DM Sans** with a fallback stack of `'DM Sans', system-ui, -apple-system, sans-serif`.

### Font Weights
- **Medium (500):** headings, labels, buttons, emphasis
- **Normal (400):** body text and inputs

### Type Scale
- `h1`: 2xl
- `h2`: xl
- `h3`: lg
- `h4`: base
- `label`: base, medium
- `button`: base, medium
- `input`: base, normal

**Line height:** `1.5`

---

## Spacing & Layout

### Border Radius
- **Base radius:** `0.875rem` (14px)
- **sm:** 10px
- **md:** 12px
- **lg:** 14px
- **xl:** 18px

### Spacing Philosophy
Generous spacing, substantial card padding, calm vertical rhythm, and breathable layouts.

---

## Motion & Animation

### Timing
- **Page transitions:** 0.4s
- **Modals/dialogs:** 0.25s
- **Interactive elements:** 0.15-0.2s
- **List items:** 0.3s

### Curves
- **Smooth:** `[0.43, 0.13, 0.23, 0.96]`
- **Snappy:** `[0.34, 1.56, 0.64, 1]`
- **Ease-out:** `[0.16, 1, 0.3, 1]`

### Principles
Subtle over flashy, consistent timing, spring physics for interactive moments, and respect for reduced motion.

---

## Components & Patterns

- Buttons use terracotta, sage, outline, ghost, and destructive variants.
- Cards rely on borders and warm surfaces more than shadows.
- Inputs use slightly darker cream backgrounds and soft terracotta focus rings.
- Navigation should feel calm, tactile, and warm.
- Empty states should be encouraging, not clinical.
- Loading states should prefer skeletons over spinners.

---

## Voice & Tone

- Warm and conversational
- Encouraging, never scolding
- Clear and direct
- Human, not corporate

When in doubt, ask: *Does this feel like home?*
