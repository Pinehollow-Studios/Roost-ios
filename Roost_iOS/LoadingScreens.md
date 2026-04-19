# Roost — Loading Screens Handoff

Two SwiftUI loading screens, ported from `Roost Loading Screens.html`.
Both use the existing `AppIcon` asset — **do not redraw the icon**; use `Image("AppIcon")` (or whatever the asset is named in `Assets.xcassets`).

All colors come from `DesignSystem.Color` in `DesignSystem.swift`. All fonts come from DM Sans (already registered).

---

## 1 · `LoadingView` — general-purpose loading

**Intent:** calm, "settling in" feel. Shown whenever the app is fetching data, resolving state, etc. Loops indefinitely.

**Composition (stacked Zs, bottom to top):**
1. Warm cream radial-gradient background (center top-ish, fades to `background`).
2. Subtle film grain overlay (3–5% opacity, screen or overlay blend).
3. **Window-light shaft** — a wide diagonal soft-edged band of warm light (`#FFEDD2` with alpha). Rotated ~-18°, animates from offscreen top to offscreen bottom over ~8s, looping. Uses a radial/linear gradient with transparent edges so it feels like sun through a window.
4. **Sage wisp** — a single thin curved line (`secondaryInteractive`, ~1.4pt) drifting slowly left-to-right behind the icon. Use a `Path` with two quadratic curves. Animate its `offset(x:)` over ~12s, opacity fades in/out.
5. **Soft halo** — radial gradient (terracotta at ~14% alpha → clear), centered behind the icon, gently pulsing (scale 0.96 → 1.04 over 4.4s).
6. **App icon** — `Image("AppIcon")`, 108×108, cornerRadius 24, with a warm terracotta-biased shadow. Breathes: `scaleEffect` 1.0 → 1.025 over 4.4s, `easeInOut`, autoreverse, repeat forever.
7. **Status line** — 14pt DM Sans Regular, color `mutedForeground`. Text is a configurable string (default "Settling in") followed by animated dots (1 → 2 → 3 → 1 every 500ms). Opacity pulses 0.62 → 1.0 in sync with the icon breath.

**API:**
```swift
struct LoadingView: View {
    var statusText: String = "Settling in"
    // ...
}
```

**Reduce motion:** if `accessibilityReduceMotion` is true, skip the light-shaft, sage wisp, halo pulse, and icon breathe. Keep only the dot animation.

---

## 2 · `AuthLoadingView` — one-shot auth intro

**Intent:** "coming home" moment. Shown once, for ~3.5s, after the user signs in but before the main UI is ready. Does NOT loop — it plays through and holds on the final state.

**Composition:**
1. **Dawn gradient background** — top-down linear gradient:
   - `#F6E8D3` (cream) at top
   - `#EBD4B8` (warm sand) at ~40%
   - `#DCA88A` (warm terracotta) at ~75%
   - `primary` (`#D4795E`) at bottom
2. **Sun glow** — radial gradient ellipse behind the horizon (warm `#FFD7AA` at ~85% alpha → clear). Positioned at bottom-center, ~420×420pt, blurred ~6pt. Fades in + scales 0.6 → 1.0 over 0.8s starting at 0.2s.
3. **Horizon arc** — two thin terracotta curves (`#B8563C`) drawn with `.trim(from:to:)` animation. The main arc is 1.5pt, drawing over 1.8s starting at 0.2s. A secondary arc below it is 0.8pt at 50% opacity, drawing over 2s starting at 0.4s. Use `Path` with a quadratic curve across the screen, dipping down toward the center (slight smile).
4. **Grain** — same subtle overlay.
5. **App icon** — 96×96, cornerRadius 22, with a strong warm shadow. Rises in from below:
   - Start: offset y +24pt, scale 0.82, blur 6pt, opacity 0.
   - End (at 1.3s + 1.4s duration): offset 0, scale 1, blur 0, opacity 1.
   - Spring: `.interpolatingSpring(mass: 0.8, stiffness: 120, damping: 14)` or equivalent.
6. **Icon shimmer** — a one-time diagonal light sweep across the icon face, starting at 2.4s, over 1.4s. Implement as an overlay with a linear gradient masked by the icon's rounded rect; animate its `offset(x:)` from right-off to left-off.
7. **Wordmark "Roost"** — 32pt DM Sans Bold, color `foreground`. Each letter drops in individually:
   - Start: offset y -18pt, opacity 0
   - End: offset y 0, opacity 1
   - Spring curve, 0.55s duration
   - Staggered: letter i starts at `2.5 + i*0.07`s
8. **Tagline** — "your home, together", 13pt DM Sans Regular, color `foreground` at 62% alpha. Fades in + rises 6pt starting at 3.0s.
9. **Sage breeze** — a thin horizontal sage line (`secondaryInteractive`) that sweeps across the mid-scene once, starting at 1.8s, 3.2s duration.
10. **Progress indicator** (bottom, ~72pt from bottom):
    - Rotating status text (12pt, uppercase, letter-spaced, 55% alpha), crossfading every 1.8s:
      - "Unlocking your home"
      - "Gathering the nest"
      - "Almost there"
    - Thin progress bar: 120×2pt, `#B8563C` at 22% alpha track, `#B8563C` indicator sliding left→right (40% width, 1.8s duration, repeats).
    - Both fade in at 3.3s.

**API:**
```swift
struct AuthLoadingView: View {
    var onComplete: (() -> Void)? = nil   // fire when user is ready to transition out
    // ...
}
```

**Reduce motion:** crossfade the final composition in over 0.4s instead of animating each element. Still show the wordmark + tagline; just no drops/sweeps/shimmer.

**Typical usage:**
```swift
.fullScreenCover(isPresented: $showingAuthLoading) {
    AuthLoadingView(onComplete: {
        // wait for your auth future + a minimum dwell (~3s) before dismissing
        showingAuthLoading = false
    })
}
```

---

## Color tokens to use

| HTML value | SwiftUI |
| --- | --- |
| `#D4795E` terracotta | `DesignSystem.Color.primary` |
| `#B8563C` deep terracotta | new: `primaryDeep` — add to `DesignSystem.swift` |
| `#F2EBE0` cream | `DesignSystem.Color.card` |
| `#EBE3D5` bg | `DesignSystem.Color.background` |
| `#3D3229` text | `DesignSystem.Color.foreground` |
| `#6B9673` sage interactive | `DesignSystem.Color.secondaryInteractive` |

If `primaryDeep` doesn't exist yet, add it:
```swift
static let primaryDeep = Color(hex: 0xB8563C)
```

---

## Font

All text uses DM Sans (already bundled):
- Status / tagline: `DMSans-Regular`
- Wordmark: `DMSans-Bold`
- Uppercase status: `DMSans-Medium`, tracking +0.6, `.uppercase`

Use whatever DM Sans accessor you already have in `DesignSystem.Typography`.

---

## Motion durations (in seconds, at speed = 1.0)

Both views should accept a `speedMultiplier: Double = 1.0` param for testing/accessibility. Divide all durations by it.

### LoadingView (loops)
| Element | Duration |
| --- | --- |
| windowLight | 8.0 |
| sageWisp | 12.0 |
| halo pulse | 4.4 |
| icon breathe | 4.4 |
| status fade | 4.4 |
| dots | 0.5 per step |

### AuthLoadingView (one-shot)
| Element | Delay | Duration |
| --- | --- | --- |
| sun glow | 0.2 | 0.8 |
| horizon arc 1 | 0.2 | 1.8 |
| horizon arc 2 | 0.4 | 2.0 |
| icon rise | 1.3 | 1.4 |
| sage breeze | 1.8 | 3.2 |
| icon shimmer | 2.4 | 1.4 |
| wordmark letters | 2.5 + i·0.07 | 0.55 each |
| tagline | 3.0 | 0.8 |
| status / progress in | 3.3 | 0.6 |

Full sequence ends around 4.0s. Hold state = icon + wordmark + tagline + looping progress.

---

## Reference

The source-of-truth HTML prototype is in this project: `Roost Loading Screens.html`. Open it to see the animations play. The JSX for each screen is in `loading.jsx` — timings and easing curves there match this spec exactly.
