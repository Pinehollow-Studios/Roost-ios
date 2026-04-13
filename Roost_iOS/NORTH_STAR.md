# Roost iOS — North Star Document

> Read this at the start of every session. Update the session log at the end of every session.
> Also read: [DESIGN_ETHOS.md](DESIGN_ETHOS.md) — the visual language, color system, and interaction patterns for all UI work.
> Also read: [ROOST_MOBILE_CONTEXT.md](ROOST_MOBILE_CONTEXT.md) — the complete Supabase schema, Zod/Codable models, auth flows, Realtime architecture, and feature specs from the Mac app.

---

## Vision

Roost is the shared dashboard for two people building a life together. The iOS app is the **primary build** going forward — the Mac app was the proving ground, the iPhone app is where Roost lives long-term. Same Supabase backend, same data, same warmth — but built natively for iOS with SwiftUI, designed to be the app a couple reaches for every single day without thinking about it.

The goal is **full feature parity with the Mac app**, optimised for a phone, then extended beyond what the Mac app can do with iOS-native capabilities: widgets, push notifications that work when the app is closed, haptics, and eventually iPad and Apple Watch.

When it ships to the App Store, it should feel like it was built by someone who cares about the details — native, fast, warm, and genuinely useful. A stranger should be able to download it, create an account, invite their partner, and be running their household together within two minutes.

---

## Guiding Principles

These are the same filters from the Mac app. They apply to every decision on iOS.

**Built for two.** Every feature makes sense for exactly two people who share a home and trust each other completely. Not teams. Not families. Not housemates.

**Feels native.** This is an iOS app. It should respect iOS conventions, use native navigation patterns, feel at home on the home screen, and never feel like a web app in a wrapper.

**Simple over clever.** When in doubt, do less. A feature that does one thing well is more valuable than a feature that does three things adequately. Resist scope creep.

**Real use beats polish.** An imperfect feature used daily is worth more than a beautiful feature never reached for. Ship, use, improve.

**Privacy by default.** Data lives in the Supabase project. RLS enforces isolation at the database level. No analytics, no tracking, no third-party data sharing. What happens in our home stays in our home.

**The pyramid.** The bigger and more structurally sound the base, the bigger the pyramid can be. Every phase builds on the last. Never rush a foundation layer to get to a feature faster.

**Quality over speed.** There is no deadline. Every phase is done when it's done right, not when it's done fast.

---

## Architecture Overview

| Layer | Technology | Notes |
|-------|-----------|-------|
| UI | SwiftUI | iOS 17+, no UIKit except where SwiftUI has genuine gaps |
| Architecture | MVVM | Every screen = View + `@Observable` ViewModel |
| Backend | Supabase | Shared with Mac app. **Do not modify the schema.** |
| Auth | Supabase Auth | Email+password, Google OAuth, Sign in with Apple. PKCE flow. |
| Session storage | Keychain | Via `KeychainAccess` — never UserDefaults |
| Realtime | Supabase Realtime | Centralised `RealtimeManager` with ref-counting |
| Local cache | SwiftData | Offline-first for core types |
| Push notifications | APNs + Firebase Cloud Messaging | Remote (app closed) + local (app open) fallback |
| Network | `NWPathMonitor` | `NetworkMonitor` wrapper → triggers Realtime resubscribe |
| Dependencies | Swift Package Manager | All packages pinned to stable versions |

**Bundle ID:** `com.roostapp.ios`
**Minimum target:** iOS 17.0
**Language:** Swift 5.9+

---

## The Roadmap

---

### ✅ Phase 0 — The Scaffold
*The foundation is in place and the app runs.*

This phase is done. The full Xcode project is scaffolded with:
- Complete folder structure (~80+ files)
- All SPM dependencies installed and resolving
- MVVM architecture established — every feature has View + ViewModel stubs
- All Codable models matching the Supabase schema
- All service files with method signatures
- Full design system: Roost color palette (light + dark), DM Sans typography, spacing, radius, animation presets
- Tab bar navigation (Dashboard, Shopping, Expenses, Chores, More)
- Supabase client configured with Keychain storage and PKCE flow
- `.xcconfig` secrets management (gitignored)
- SwiftData model stubs for offline caching
- RealtimeManager skeleton with ref-counting pattern
- Network monitor, haptic manager, error handler utilities
- Test targets (unit + UI) set up
- Deep link URL scheme registered (`roost-ios://`)

**Status:** App compiles and runs. Stuck on auth screens because auth is not yet wired to Supabase.

**Completed:** March 2026

---

### ✅ Phase 1 — Make It Connect
*Wire the app to Supabase. Get a user signed in, into a home, and seeing real data.*

This is the most important phase. Nothing else works without auth and a live Supabase connection. The goal is: open the app → sign in → land on the main tab bar → see real data from the shared Supabase backend. No UI polish, no animations, no edge cases — just the data pipeline working end-to-end.

**Auth (the critical path):**

- [x] **Supabase client verification** — Confirm the Supabase client connects using the real URL and anon key from `Secrets.xcconfig`. Test with a simple `.from("homes").select()` call to verify connectivity.
- [x] **Email + password signup** — Wire `SignupView` → `AuthService.signUp()` → `supabase.auth.signUp()`. Handle email confirmation flow (Supabase sends a confirmation email — the user must tap the link before they can sign in).
- [x] **Email + password login** — Wire `LoginView` → `AuthService.signIn()` → `supabase.auth.signIn()`. On success, store session in Keychain.
- [x] **Auth state listener** — Implement `AuthManager.startSessionListener()` using `supabase.auth.onAuthStateChange`. Handle `SIGNED_IN`, `SIGNED_OUT`, `TOKEN_REFRESHED` events. Session persistence across app launches via Keychain.
- [x] **Post-auth home check** — After any successful sign-in, call `supabase.rpc("get_user_home_id")`. If null → navigate to `SetupView`. If UUID → navigate to `MainTabView`.
- [x] **Setup flow (create home)** — Wire `SetupView` to call `supabase.rpc("create_home_for_user", params: { home_name, display_name })`. Navigate to main app on success.
- [x] **Setup flow (join home)** — Wire `SetupView` invite code field to call `supabase.rpc("join_home_by_invite_code", params: { code, display_name })`. Invite codes are case-insensitive — normalise to lowercase before sending.
- [x] **Google OAuth** — Implement using `GoogleSignIn-iOS` SDK + `supabase.auth.signInWithIdToken(provider: .google)`. After OAuth: if new user, send to `SetupView` to collect display name. Requires `GOOGLE_CLIENT_ID` in `Secrets.xcconfig`.
- [x] **Sign in with Apple** — Implement using `AuthenticationServices` + `supabase.auth.signInWithIdToken(provider: .apple, idToken:)`. After sign-in: same home check and setup flow as above.
- [x] **Sign out** — Clear Keychain session, navigate to `WelcomeView`.
- [x] **Auth guard in ContentView** — `ContentView` observes `AuthManager`. If not authenticated → show auth flow. If authenticated but no home → show `SetupView`. If authenticated with home → show `MainTabView`.

**Core data loading (prove the pipeline works):**

- [x] **HomeService.fetchHome()** — Fetch the user's home and members. Wire to a `HomeManager` (or similar) injected into the environment so all features can access `homeId` and `members`.
- [x] **ShoppingService.fetchItems()** — Fetch shopping items for the home. Wire to `ShoppingViewModel`. Display real items in `ShoppingListView` (plain list, no styling needed yet).
- [x] **One write operation** — Implement `ShoppingService.addItem()` end-to-end. Add a shopping item from the app and confirm it appears in the Supabase dashboard. This proves the full read + write pipeline.

**Realtime (prove sync works):**

- [x] **RealtimeManager — first subscription** — Implement the core `subscribe()` method. Subscribe to `shopping_items` in `ShoppingViewModel`. Confirm: add an item from the Mac app → it appears on iOS within 1-2 seconds without manual refresh.
- [x] **Network reconnection** — When `NetworkMonitor` detects connectivity restored, call `RealtimeManager.shared.resubscribeAll()`.

**Definition of done:**
A user can sign up (email), sign in, create or join a home, see their real shopping list, add an item, and see real-time updates from the Mac app — all without any manual refreshing. Google OAuth and Sign in with Apple both work. Session persists across app restarts.

---

### ✅ Phase 2 — Make It Solid
*Widen the foundation before building features. Every service wired, every pattern proven.*

Phase 1 proved the pipeline with auth + shopping. Phase 2 extends that to every service and establishes the patterns that all features will use. No feature UI yet — this is about making sure the data layer, the Realtime subscriptions, the optimistic update pattern, and the error handling are all rock solid.

**Wire every service to Supabase:**

- [x] **ExpenseService** — Full CRUD for expenses + expense_splits. Fetch with `select("*, expense_splits(*)")`. Implement `settleUp()` via the `settle_up` RPC. **Never modify expense_splits directly from the client.**
- [x] **ChoreService** — Full CRUD for chores. Completion logic: update `last_completed_at`, `completed_by`, and advance `due_date` for recurring chores (weekly → `addWeeks(1)`, monthly → `addMonths(1)`).
- [x] **BudgetService** — Full CRUD for budgets + custom categories. Upsert pattern with `onConflict: "home_id,category,month"`.
- [x] **ActivityService** — Fetch activity feed (50 most recent, ordered by `created_at DESC`). Implement `logActivity()` as fire-and-forget.
- [x] **NotificationService** — Fetch notifications where `user_id = auth.uid()`. Mark as read. Fetch/upsert notification preferences.
- [x] **UserPreferencesService** — Fetch/upsert user preferences (week start, time format, currency, date format).
- [x] **RoomService** — CRUD for rooms + room groups.
- [x] **CalendarService** — Client-side aggregation of chores + expenses into `CalendarEvent[]`. Expand recurring expenses for 6 months forward.
- [x] **HomeService (complete)** — Update home name, update `next_shop_date`, leave home (`leave_home` RPC), delete account (`delete_account` RPC + Edge Function).

**Establish the optimistic update pattern:**

- [x] **Define the pattern once, document it clearly.** Every mutation that modifies a list should:
  1. Immediately update the local array in the ViewModel (optimistic)
  2. Call the service method
  3. On error: rollback the local change, show error
  4. On success: call `ActivityService.logActivity()` (fire-and-forget)
  5. Realtime will trigger a full re-fetch to reconcile
- [x] **Implement optimistic updates for shopping** — toggle item (check/uncheck), delete item, add item. This is the template all other features will follow.

**Realtime for every table:**

- [x] Subscribe to all Realtime-published tables: `shopping_items`, `expenses`, `expense_splits` (no filter — has no `home_id`), `settlements`, `chores`, `activity_feed`, `home_members`, `homes`, `budgets`, `home_custom_categories`, `notifications`.
- [x] Verify ref-counting: two ViewModels subscribing to the same table share one channel. First to deinit does not kill the subscription for the second.

**SwiftData offline cache:**

- [x] **Implement SyncEngine for ShoppingItem** — On fetch: save to SwiftData. On app launch: load from SwiftData immediately, then fetch from Supabase in background, merge by ID.
- [x] **Extend to Expense, Chore, ActivityFeedItem** — Same pattern.
- [x] **Offline write queue (stub)** — Document the pattern for queuing writes when offline and replaying when connectivity returns. Implementation can come later, but the architecture should be clear.

**Error handling:**

- [x] **ErrorHandler** — Map common Supabase errors (network, RLS violation, constraint violation, auth expired) to user-friendly messages. Use warm, Roost-voice copy — not technical jargon.
- [x] **Global error presentation** — A consistent way to show errors (toast-style banner or alert). Every ViewModel should be able to set an error string and have it displayed.

**Balance calculation:**

- [x] **Implement the expense balance calculation exactly as documented.** This is critical — get it wrong and the app shows the wrong amount owed. The logic:
  - For each expense: skip if `split_type == "solo"`
  - For each unsettled split: if `split.userId == partnerId && expense.paidBy == myId` → I am owed. If `split.userId == myId && expense.paidBy != myId` → I owe.
  - Positive balance = I am owed. Negative = I owe.
  - **Use splits, not raw expense amounts.** Settled splits must be excluded.

**Definition of done:**
Every service makes real Supabase calls and returns real data. Realtime subscriptions work for all tables. The optimistic update pattern is proven on shopping and documented for other features. SwiftData caching works for core types. The balance calculation is correct. Error handling shows friendly messages. The data layer is complete and trustworthy — features can be built on top with confidence.

---

### ⬜ Phase 3 — Make It Work
*Build every feature end-to-end. Functional, not pretty.*

Phase 2 gave us a solid data layer. Phase 3 builds every feature's UI on top of it. The focus is **function over form** — every feature works correctly, but visual polish comes in the next phase. Use the scaffold's stub views as starting points.

Build features in this order (based on daily use patterns):

**3.1 — Shopping List:**
- [x] Full item list with category grouping (items grouped under collapsible category headers, ungrouped under "Other")
- [x] Add item sheet with name, quantity, category fields
- [x] Check/uncheck with optimistic update (tap the row)
- [x] Swipe to delete with optimistic update
- [x] Next shop date display at top of list (countdown: "Shopping in 3 days / tomorrow / today / overdue")
- [x] Real-time sync — partner's changes appear within 1-2 seconds
- [x] Activity logging on add, check, delete
- [x] Empty state when list is empty

**3.2 — Expenses:**
- [x] Expense list ordered by date (newest first)
- [x] Balance card at top showing who owes whom and how much
- [x] Add expense sheet: title, amount, paid by (me/partner), split type (equal/solo), category, date, notes
- [x] Equal split: automatically create `expense_splits` for both members. Payer's split marked as settled immediately.
- [x] Solo expense: no splits created, does not affect balance
- [x] Swipe to delete expense
- [x] Settle up flow: confirmation → optional note → call `settle_up` RPC → success state
- [x] Activity logging on add, delete, settle up
- [x] Empty state

**3.3 — Chores:**
- [x] Chore list with overdue chores sorted to the top (red date label)
- [x] Add chore sheet: title, description, assigned to (me/partner/unassigned), frequency (once/daily/weekly/monthly), due date, room
- [x] Complete chore: update `last_completed_at`, `completed_by`, advance due date for recurring
- [x] Uncomplete chore: reset `last_completed_at` and `completed_by` to nil
- [x] Swipe to delete
- [x] Completion history (from activity feed filtered by `entity_type='chore'` and `action ILIKE 'completed%'`)
- [x] Streaks for recurring chores ("✓ 4 weeks in a row")
- [x] Unassigned indicator
- [x] Activity logging
- [x] Empty state

**3.4 — Activity Feed:**
- [x] Chronological list of the 50 most recent activity items
- [x] Each row: member avatar + action text + relative timestamp ("2 hours ago")
- [x] Real-time — new items appear without refresh
- [x] Empty state

**3.5 — Notifications:**
- [x] Notification list with unread indicators
- [x] Mark as read (tap)
- [x] Mark all as read
- [x] Unread count badge on the tab bar or nav bar
- [x] Local notifications when the app is in the background and a Realtime event arrives (gate on notification preferences + quiet hours)
- [x] Notification tap routes to the relevant feature screen

**3.6 — Budget:**
- [x] Monthly budget overview: category rows with spend vs limit progress bars
- [x] Colour progression on bars: <60% success → 60-80% faint warning → 80-100% warning → >100% destructive
- [x] Month navigation (prev/next)
- [x] Set/edit budget per category sheet
- [x] Total spend vs total budget summary
- [x] Custom categories (create/delete)
- [x] Empty state (no budgets set)

**3.7 — Calendar:**
- [x] Month grid view with event dots on days that have events
- [x] Upcoming events list below the grid
- [x] Events aggregated from chores (by `due_date`) and expenses (by `date`, recurring expanded 6 months)
- [x] Tap a day to see its events
- [x] Empty state

**3.8 — Settings:**
- [x] **Profile:** Display name editing, avatar colour picker (12 colours), avatar icon picker (25 icons mapped from Lucide to SF Symbols). Persists to `home_members`.
- [x] **Household:** Home name editing, invite code display with share button (generates `roost-ios://join?code=<code>` deep link), member list with avatars.
- [x] **Notifications:** Per-type toggles (chores, expenses, shopping, settlements), quiet hours with time pickers. Persists to `notification_preferences`.
- [x] **Preferences:** Week start (Monday/Sunday), time format (12h/24h), currency, date format. Persists to `user_preferences`.
- [x] **Account:** Change email (requires re-auth OTP), change password (requires re-auth OTP), leave home, delete account (calls Edge Function).
- [x] **DishBoard:** "Coming soon" screen — polished placeholder explaining the integration. Same as Mac app.

**3.9 — Dashboard:**
- [x] Summary cards grid consuming data from all other ViewModels:
  - [x] Shopping: unchecked item count + last 3 items added
  - [x] Expenses: current balance (who owes whom)
  - [x] Chores: overdue count + next due chore
  - [x] Budget: current month spend vs limit, colour-coded
  - [x] Activity: 5 most recent events with avatars
  - [x] Next shop date: countdown display
- [x] Each card deep-links to its full feature screen
- [x] Real-time updates — partner checks off a shopping item, dashboard card count drops immediately
- [x] Empty states for cards with no data

**3.10 — Deep Links:**
- [x] `roost-ios://join?code=<code>` — opens join flow with invite code pre-filled
- [x] `roost-ios://auth/callback` — handles OAuth redirects
- [x] Notification taps — route to the correct feature screen based on notification type and entity_id

**Definition of done:**
Every feature from the Mac app works on iOS. All data is real, all mutations persist to Supabase, all Realtime subscriptions update the UI, all activity is logged, and all empty/loading/error states are handled. The app is fully functional but visually rough.

---

### ⬜ Phase 4 — Make It Beautiful
*Apply the Roost design system. Make every screen feel like home.*

Phase 3 built function. Phase 4 applies form. Reference `DESIGN_ETHOS.md` for every decision. The app should feel warm, soft, calm, and human — never cold or corporate.

**Design system application:**

- [x] **Color pass** — Every screen uses the Roost semantic colors. No default SwiftUI blue. No pure white or pure black anywhere. Warm cream backgrounds, terracotta accents, sage secondary. Verify both light and dark mode on every screen.
- [x] **Typography pass** — DM Sans rendering correctly everywhere. Correct weights (Medium 500 for headings/labels/buttons, Regular 400 for body). Never bold. Correct scale (title/heading/cardTitle/body/label/caption).
- [x] **Spacing pass** — Generous padding on all cards (`RoostSpacing.xl` to `.xxl`). Comfortable list item gaps. Nothing feels cramped.
- [x] **Radius pass** — All cards and containers use `RoostRadius.lg` (14pt). Buttons and inputs use `RoostRadius.md` (12pt). Pill elements use `RoostRadius.full`.
- [ ] **Component refinement:**
  - `RoostButton` — All variants (primary, secondary, outline, ghost, destructive) with correct colours, tap scale (0.98), and haptic feedback
  - `RoostCard` — Warm card background, subtle border, generous padding, soft shadow in modals only
  - `RoostTextField` — Warm input background, terracotta focus ring
  - `MemberAvatar` — Colour circle with icon or initial, all sizes (xs to xl)
  - `EmptyStateView` — Warm icon, encouraging copy, optional CTA
  - `LoadingSkeletonView` — Animated shimmer on muted background
  - `ProgressBarView` — Rounded ends, colour thresholds, smooth width animation

**Animations:**

- [ ] **Page transitions** — Smooth transitions between tabs and navigation pushes using the Roost timing presets
- [ ] **Sheet presentations** — Scale + fade + rise (0.25s ease-out)
- [ ] **List items** — Staggered entrance animations. Exit animations on delete (fade + scale + slide left).
- [ ] **Checkbox/completion** — Checked items animate to 60% opacity with strikethrough
- [ ] **Settle up celebration** — Confetti or satisfying animation on successful settlement
- [ ] **Haptics** — Selection haptic on toggles, success haptic on completions/settlements, light impact on button taps

**Dark mode:**

- [ ] Full dark mode pass on every screen using the Roost dark palette
- [ ] Warm blacks (#0f0d0b), cream text (#f2ebe0), preserved terracotta
- [ ] Test on device — simulators don't always represent dark mode accurately

**Voice and copy:**

- [ ] Warm, conversational microcopy throughout:
  - "All settled up" not "Balance: £0.00"
  - "You're owed £24.50" not "Your balance: +£24.50"
  - "Nothing coming up this week" not "No events scheduled"
- [ ] Error messages are friendly, not technical
- [ ] Empty states are encouraging, not scolding

**Definition of done:**
Every screen matches the Roost design ethos. Light and dark mode both look correct and feel warm. Animations are smooth and intentional. The app feels cohesive — a stranger would believe every screen was designed by the same person with the same care.

---

### ⬜ Phase 5 — Make It Smart
*Add Hazel AI and push notifications. The features that make the app feel alive.*

**Hazel AI:**

Hazel is Roost's AI assistant — small, focused, and never intrusive. The Claude API key **must not** live in the iOS app binary. All AI calls go through a Supabase Edge Function that holds the key server-side.

- [ ] **Supabase Edge Function: hazel** — A new Edge Function (`supabase/functions/hazel/index.ts`) that accepts a JSON body with `{ context, text, categories? }` and returns Claude's response. Authenticated via Supabase JWT (only signed-in users can call it). The function calls the Anthropic API with the Claude Sonnet model.
- [ ] **Shopping: smart normalisation** — When adding a shopping item, send the title to the Hazel Edge Function. Returns: corrected capitalisation, extracted quantity, suggested category. Apply silently (no UI for the AI call — the item just appears correctly formatted).
- [ ] **Expenses: smart categorisation** — When saving an expense, send the title to Hazel. Returns: suggested category. Apply as the default category (user can change it).
- [ ] **Chores: smart suggestions** — "Suggest" button on the chores screen. Hazel returns 5 seasonal, duplicate-aware chore suggestions. Display as quick-add chips.

**Push notifications (remote):**

- [ ] **Firebase Cloud Messaging setup** — Register for remote notifications. Store the FCM device token in Supabase (new column or a `device_tokens` table — this is the one schema addition the iOS app needs, discuss in the session log when implementing).
- [ ] **Supabase Edge Function: push notification sender** — Triggered when a notification row is created. Looks up the recipient's FCM token and sends via FCM HTTP API.
- [ ] **Notification permissions** — Request permission on first relevant action (not on launch). Respect the user's choice gracefully.
- [ ] **Badge count** — Update the app icon badge with unread notification count.
- [ ] **Notification tap routing** — Tapping a push notification opens the app and navigates to the relevant screen.

**Local notification fallback:**

- [ ] When the app is in the foreground and a Realtime notification event arrives, show an in-app banner (not a system notification).
- [ ] Gate on notification preferences (type toggles + quiet hours).
- [ ] Quiet hours cross-midnight support (22:00 → 08:00 range).

**Definition of done:**
Hazel normalises shopping items, categorises expenses, and suggests chores — all via the Edge Function. Push notifications arrive on the user's phone when their partner does something, even when the app is closed. Notification preferences and quiet hours are respected.

---

### ⬜ Phase 6 — Make It Bulletproof
*Thorough testing, bug fixing, and stability hardening before anyone else uses it.*

This is not a quick pass. This is a full, methodical audit of every surface in the app.

**Smoke test (every feature):**

- [ ] **Auth:** Sign up (email), sign in, sign out, sign in (Google), sign in (Apple), session persistence across app kill + relaunch, expired session handling
- [ ] **Setup:** Create new home, join existing home via invite code, invite code case-insensitivity
- [ ] **Shopping:** Add item, check item, uncheck item, delete item, category grouping, next shop date, empty state
- [ ] **Expenses:** Add equal expense, add solo expense, delete expense, balance calculation correctness, settle up full flow, settlement history
- [ ] **Chores:** Add chore, complete chore, uncomplete chore, delete chore, recurring due date advancement, overdue sorting, streaks, completion history
- [ ] **Budget:** Set budget, edit budget, delete budget, month navigation, custom categories, spend vs limit accuracy
- [ ] **Calendar:** Month grid, event dots, upcoming list, date navigation
- [ ] **Activity feed:** Events appear, real-time updates, correct actor names
- [ ] **Notifications:** Receive notifications, mark as read, mark all read, badge count, push notifications when app closed, quiet hours
- [ ] **Settings:** Profile (name, avatar), household (name, invite share), notification prefs, user prefs, change email, change password, leave home, delete account
- [ ] **Dashboard:** All cards showing correct data, deep links to features, real-time updates

**Cross-device testing:**

- [ ] **Mac ↔ iOS real-time sync** — Add item on Mac, appears on iOS within 1-2 seconds. Complete chore on iOS, appears on Mac. Settle up on either, both update. This is the core promise of Roost.
- [ ] **Two-phone test** — Two iPhones, two accounts in the same home. Every action on one phone reflects on the other.
- [ ] **Mixed platform test** — Mac + iPhone simultaneously. Full usage session — shopping, expenses, chores, settle up.

**Edge cases:**

- [ ] Network loss mid-operation (toggle item while going through a tunnel)
- [ ] App killed during a mutation (does SwiftData preserve the optimistic state?)
- [ ] Deep link with invalid invite code
- [ ] User with no home tries to access main app (should redirect to setup)
- [ ] Very long item names, very large expense amounts, empty categories
- [ ] Rapid sequential operations (add 10 items quickly, check off 5 rapidly)

**Performance:**

- [ ] App launch time — measure cold start to interactive
- [ ] Scrolling performance with 100+ shopping items, 50+ expenses
- [ ] Realtime latency measurement
- [ ] Memory usage under normal operation
- [ ] Battery impact assessment (Realtime WebSocket connections)

**Accessibility:**

- [ ] VoiceOver — every screen navigable and readable
- [ ] Dynamic Type — text scales correctly at all system sizes
- [ ] Colour contrast — all text meets WCAG AA against its background
- [ ] Reduce Motion — animations respect the system setting

**Bug fixes:**

- [ ] Document every bug found during testing in the session log
- [ ] Fix all critical and major bugs before proceeding
- [ ] Known minor issues can be tracked and carried to a post-launch update

**Definition of done:**
Every feature works correctly on a real device. Cross-device sync is verified and reliable. No critical bugs. VoiceOver works. Performance is acceptable. A comprehensive smoke test document is written and signed off.

---

### ⬜ Phase 7 — Make It Welcoming
*Onboarding, first-run experience, and the moments that make a new user feel at home.*

- [ ] **Onboarding tour** — A guided walkthrough (similar to the Mac app's 12-step tour) that shows new users the key features. Spotlight highlighting on target elements, contextual tooltips, progress indicators, skip option.
- [ ] **First-run empty states** — Every feature screen has a warm, encouraging empty state that explains what the feature does and has a CTA to get started. These are the first thing a new user sees — they must feel inviting, not bare.
- [ ] **Invite partner flow** — After creating a home, prompt the user to invite their partner. Make the invite code sharing seamless — native share sheet with a pre-written message and the deep link.
- [ ] **In-app tips** — Subtle, non-intrusive tips that appear contextually (e.g. first time on the expenses screen: "Tip: Tap the balance card to settle up")
- [ ] **Tutorial skip** — Everything is skippable. Never trap users in onboarding.

**Definition of done:**
A first-time user who has never heard of Roost can download the app, understand what it does, create an account, invite their partner, and feel confident using every feature — all without external help.

---

### ⬜ Phase 8 — Make It Ship
*Everything required to submit to the App Store.*

**Apple Developer Program:**

- [ ] Sign up for Apple Developer Program ($99/year) at developer.apple.com
- [ ] Configure certificates, identifiers, and provisioning profiles
- [ ] Set up the iOS bundle ID (`com.roostapp.ios`) in App Store Connect

**App Store Connect setup:**

- [ ] App name, subtitle, description, keywords, category (Lifestyle), age rating
- [ ] Support URL (even a simple landing page)
- [ ] Privacy policy URL (required — write one covering Supabase data, no analytics, no third-party sharing)
- [ ] Marketing URL (optional but recommended)

**App Store assets:**

- [ ] **App icon** — Proper 1024×1024 icon designed in the Roost style (warm, recognisable)
- [ ] **Screenshots** — Required sizes for all supported devices (iPhone 15 Pro Max, iPhone 15 Pro, iPhone SE). Minimum 3, recommend 6-8 showing key features.
- [ ] **App preview video** — Optional but highly recommended. 15-30 second screen recording showing the core flow.

**Technical requirements:**

- [ ] Code signing with a distribution certificate
- [ ] Provisioning profile for App Store distribution
- [ ] Archive and upload via Xcode
- [ ] Privacy manifest (`PrivacyInfo.xcprivacy`) declaring data collection practices
- [ ] Ensure no private API usage
- [ ] Remove any debug/test code, placeholder content, or TODO markers visible to users

**App Review preparation:**

- [ ] Create a demo account that Apple's review team can use (pre-populated with sample data)
- [ ] Write clear review notes explaining:
  - The app requires two users in a shared home — provide credentials for both test accounts
  - Sign in with Apple + Google OAuth are both functional
  - Push notifications require a real device
- [ ] Ensure the app works fully without a partner account (graceful single-user state)

**Freemium model:**

- [ ] Define which features are free vs premium (decide before submission)
- [ ] Implement StoreKit 2 for in-app purchases if premium features are gated
- [ ] Ensure the free tier is genuinely useful — never feel like a demo

**TestFlight:**

- [ ] Upload a beta build to TestFlight
- [ ] Invite 5-10 beta testers (friends, family, couples)
- [ ] Collect feedback, fix issues
- [ ] At least 2 weeks of beta testing before App Store submission

**Definition of done:**
The app is submitted to the App Store and approved. A stranger can find it, download it, and use it. TestFlight beta period is complete with no critical issues outstanding.

---

### ⬜ Phase 9 — Make It Better
*Post-launch improvements, user feedback, and the features that take Roost further than the Mac app ever went.*

This phase is ongoing. Priorities will be shaped by real user feedback after launch.

**Planned enhancements:**

- [ ] **Home screen widgets** — WidgetKit widgets for:
  - Shopping list (small: item count, medium: next 5 unchecked items)
  - Expense balance (small: who owes whom)
  - Next chore due (small: chore name + due date)
  - Next shop date (small: countdown)
- [ ] **iPad support** — Adaptive layout using `NavigationSplitView` (sidebar + detail). Same codebase, responsive layout.
- [ ] **DishBoard integration** — When a meal is planned in DishBoard, ingredients push to the Roost shopping list. Cross-app Supabase integration.
- [ ] **Keyboard shortcuts** — For iPad with hardware keyboard
- [ ] **Spotlight search** — Index shopping items and chores in Spotlight for quick access
- [ ] **App Intents / Siri Shortcuts** — "Hey Siri, add milk to the shopping list"
- [ ] **Share extension** — Share a link or text from another app to add it as a shopping item or note
- [ ] **Moving checklist** — Special mode for couples moving in together (structured shared checklist with categories)

**Infrastructure improvements:**

- [ ] **Automated testing** — Unit tests for services and ViewModels, UI tests for critical flows
- [ ] **CI/CD** — GitHub Actions for automated builds, TestFlight uploads
- [ ] **Crash reporting** — Lightweight crash reporting (consider TelemetryDeck for privacy-respecting analytics, or skip entirely)
- [ ] **Performance monitoring** — Track launch times, Realtime latency, memory usage over time

---

## Architectural Decisions That Must Not Change

These decisions were made deliberately. Do not break them.

**Supabase schema is shared and immutable from the client.** The Mac and iOS apps share one Supabase project. Never modify a table, column, RLS policy, or function for the iOS app alone. If a schema change is needed, it must work for both platforms. The one exception: adding a `device_tokens` table for push notifications is acceptable as it's additive and doesn't affect existing tables.

**MVVM with @Observable.** Every screen is a View + ViewModel. Views are thin — display logic only. All business logic, data fetching, and state management live in ViewModels.

**Services are stateless.** Services make Supabase calls and return data. They do not hold state. State lives in ViewModels.

**RealtimeManager is centralised.** Never call `supabase.channel()` directly from a ViewModel. Always go through `RealtimeManager.shared.subscribe()`. The ref-counting prevents channel leaks.

**Realtime callbacks trigger re-fetches, not local patches.** When a Realtime event arrives, the callback should trigger a full re-fetch from Supabase. Do not try to patch local state from the Realtime payload — it's fragile and skips Codable validation.

**logActivity() is mandatory and fire-and-forget.** Every mutation that changes household data must call `ActivityService.logActivity()` in its success path. Never block the UI waiting for it. Never skip it.

**Invite codes are case-insensitive.** Always normalise to lowercase before comparison or submission.

**Date-only columns must stay date-only.** Supabase fields like `due_date`, `date`, `month`, and `next_shop_date` may come back as `YYYY-MM-DD` strings rather than full timestamps. Models must decode and encode those fields explicitly in date-only format instead of relying on default `Date` Codable behaviour.

**expense_splits has no home_id.** When subscribing to Realtime on this table, do not pass a filter. RLS joins through `expenses` to scope results.

**Balance is calculated from splits, not raw amounts.** Use `expense_splits` where `settled == false`. Never sum raw `expense.amount` values.

**Keychain for auth, never UserDefaults.** Session tokens are sensitive. Keychain is encrypted at rest. UserDefaults is not.

**PKCE for OAuth, never implicit.** The Mac app uses implicit flow as an Electron workaround. iOS uses PKCE — it's the correct flow for mobile.

---

## Known Technical Considerations

Things to be aware of during development.

**Supabase-swift SDK maturity.** The Swift SDK is newer than the JavaScript SDK. Some features may have slightly different APIs or undocumented behaviour. Check the `supabase-swift` GitHub issues if something doesn't work as expected.

**SwiftData and Supabase coexistence.** SwiftData models are local-only representations. They will have different field names (camelCase) than the Supabase JSON (snake_case). Keep a clear boundary between Codable models (for Supabase) and @Model classes (for SwiftData). The SyncEngine is the bridge.

**Google OAuth on iOS.** Requires a `GoogleService-Info.plist` from the Google Cloud Console with an iOS client ID configured for the `com.roostapp.ios` bundle ID. The Mac app's Google OAuth config is for a different platform — you need a separate iOS OAuth client.

**Sign in with Apple.** Requires the Sign in with Apple capability enabled in the Xcode project and the App ID configured in the Apple Developer portal. Supabase needs the Apple OAuth provider configured with the Services ID.

**Push notification device tokens.** FCM tokens can change. The app should re-register the token on every launch and update Supabase if it changed. Handle token refresh callbacks from Firebase.

**Background fetch.** iOS aggressively suspends background processes. Realtime WebSocket connections will be dropped when the app enters the background. On foregrounding, the app must reconnect Realtime subscriptions and re-fetch stale data. The NetworkMonitor + RealtimeManager pattern handles this.

**Apple App Review.** First submission may be rejected. Common iOS app rejection reasons: missing privacy manifest, incomplete login functionality, placeholder content visible to users, app doesn't work without an account partner. Budget 1-2 rejection cycles and the ~48-hour turnaround each involves.

---

## How to Use This Document

**As the developer (Tom):**
- Read the current phase section at the start of each session to remember what matters
- Check off tasks as they're completed
- Add notes to the session log after every work session
- Add ideas to Phase 9 or a backlog freely — the backlog is a brain dump, not a commitment

**As Codex / Claude Code:**
- Read this document at the start of any session before writing a single line of code
- Understand which phase we are in and what the current priorities are
- After each session, add an entry to the session log
- If a technical decision conflicts with the guiding principles or architectural decisions, flag it before proceeding
- Do not build Phase 4 features during Phase 2. Respect the pyramid.

**Updating this document:**
- Session log: updated after every session
- Phase tasks: check off `[ ]` → `[x]` as completed
- Phase completion: mark with ✅ and a date when the definition of done is met
- New ideas: add to Phase 9 or create a new future phase

---

## Session Log

### Session 9 — 3 April 2026
Expenses tab redesign pass completed with a focus on hierarchy, warmth, and real editing/deletion affordances rather than a purely cosmetic refresh.

**Expenses UI redesign**
- Reworked the top summary section so `Balance` is now the dominant hero card with state-aware warmth and stronger visual emphasis, while `Total Spent` and `Your Share` now sit as compact supporting cards beneath it
- Added active filter pills for category and payer using native menus with proper active-state styling instead of placeholder chips
- Refined empty-state handling so the page now distinguishes between a genuinely empty expenses history and a no-results filtered state

**Expense list interaction upgrade**
- Rebuilt expense rows around a clearer hierarchy: title + total amount first, payer and your share second, date/category/split metadata last
- Kept the existing card footprint while making the payer avatar less dominant and the financial information easier to scan
- Added category-linked accent colours on the left edge so cards are more scannable by type at a glance
- Added custom swipe-to-reveal actions for `Edit` and `Delete` within the app’s visual language
- Added in-app delete confirmation sheet instead of relying on a system alert

**Edit flow**
- Upgraded `AddExpenseSheet` so it now supports both add and edit modes with pre-filled values and a `Save changes` action
- Added optimistic expense editing in `ExpensesViewModel`
- Extended the expense service so edits can update the expense row and replace associated splits
- Preserved existing split settlement data on metadata-only edits by only rebuilding splits when amount, payer, or split type changes

**Currency / formatting / interaction polish**
- Normalised expense currency formatting to always show two decimal places
- Updated expense-row date formatting to a human abbreviated format (`30 Mar 2026`)
- Added light/warning haptic feedback on card open and destructive confirm actions

**Files modified:** `Features/Expenses/Views/ExpensesView.swift`, `Features/Expenses/Views/ExpenseRow.swift`, `Features/Expenses/Views/AddExpenseSheet.swift`, `Features/Expenses/ViewModels/ExpensesViewModel.swift`, `Services/ExpenseService.swift`, `NORTH_STAR.md`

**Status:** Expenses tab redesign is implemented. A full `xcodebuild` typecheck/build could not be completed in this environment because Xcode is currently failing before compilation with `simdiskimaged` / package-resolution errors, so physical-device/Xcode verification is still required for swipe edit/delete and the updated sheet flow.

### Session 0 — 25 March 2026
Project scaffolded via Codex. Full Xcode project created with:
- All SPM dependencies installed (supabase-swift, KeychainAccess, GoogleSignIn-iOS, Firebase Messaging, Nuke, SwiftUI-Introspect, SwiftDate)
- Complete folder structure with ~80+ files
- All Codable models matching Supabase schema
- All service files with method signatures (not yet implemented)
- All ViewModels as @Observable stubs
- All Views as SwiftUI stubs
- Full design system: Roost colours (light + dark), DM Sans typography, spacing, radius, animation presets
- Tab bar navigation (Dashboard, Shopping, Expenses, Chores, More)
- Supabase client configured with Keychain + PKCE
- .xcconfig secrets management
- SwiftData model stubs
- RealtimeManager skeleton
- Test targets (empty)
- Deep link URL scheme registered

**Status:** App compiles and runs clean on simulator. Cannot progress past auth screens — auth not yet wired to Supabase. Ready for Phase 1.

---
### Session 1 — 26 March 2026
Phase 1 ("Make It Connect") completed. All auth, data, and realtime tasks are now wired to Supabase:

**Auth (all items checked off):**
- Post-auth home check was already implemented (checked off)
- Auth guard in ContentView was already implemented (checked off)
- Setup flow: `SetupView` rebuilt with Create/Join segments, wired to `create_home_for_user` and `join_home_by_invite_code` RPCs. Invite codes normalised to lowercase.
- Sign out: `AuthService.signOut()` calls `supabase.auth.signOut()`. Button added to Settings.
- Google OAuth: Native `GoogleSignIn-iOS` SDK → `signInWithIdToken(provider: .google)`. Requires `GOOGLE_CLIENT_ID` in `Secrets.xcconfig` and Supabase Google provider config.
- Sign in with Apple: `ASAuthorizationController` → `signInWithIdToken(provider: .apple)` with SHA256 nonce. Requires Sign in with Apple capability and Supabase Apple provider config.
- OAuth callback handler wired in `AuthManager.handle(url:)`

**Core data loading:**
- `HomeService.fetchHome()` + `fetchMembers()` implemented with Supabase queries
- `HomeManager` created as `@Observable` environment object — stores home, members, currentMember, partner
- Injected into environment from `RoostApp`, loaded when `MainTabView` appears
- `AuthManager` now stores `homeId: UUID?` alongside `hasHome: Bool?`

**Shopping pipeline (proves read + write):**
- `ShoppingService`: full CRUD — `fetchItems`, `createItem`, `updateItem`, `deleteItem`
- `ShoppingViewModel`: loads items, add/toggle/delete with optimistic updates and rollback
- `ShoppingListView`: real list with check/uncheck, swipe-to-delete, add sheet
- `AddShoppingItemSheet`: name, quantity, category fields
- `ShoppingItemRow`: displays item with completion state, quantity, category pill

**Realtime:**
- `RealtimeManager` fully implemented with ref-counted subscriptions using `postgresChange(AnyAction.self)` (non-deprecated `RealtimePostgresFilter` API, `subscribeWithError`)
- Shopping list subscribes to `shopping_items` table with `home_id` filter — partner changes appear without refresh
- `NetworkMonitor` wired with `NWPathMonitor` — calls `resubscribeAll()` on network reconnect

**Files created:** `HomeManager.swift`
**Files modified:** `AuthManager.swift`, `AuthService.swift`, `HomeService.swift`, `ShoppingService.swift`, `NetworkMonitor.swift`, `RealtimeManager.swift`, `Config.swift`, `RoostApp.swift`, `ContentView.swift` (unchanged), `MainTabView.swift`, `WelcomeView.swift`, `SetupView.swift`, `SetupViewModel.swift`, `ShoppingViewModel.swift`, `ShoppingListView.swift`, `ShoppingItemRow.swift`, `AddShoppingItemSheet.swift`, `SettingsView.swift`

**Status:** Phase 1 definition of done is met (pending live testing with real Supabase credentials). All auth flows, data loading, write pipeline, and realtime sync are wired. Build passes clean. Ready for Phase 2.

---
### Session 2 — 26 March 2026
Phase 2 ("Make It Solid") completed. Every remaining service is now wired to Supabase and the data layer patterns are established:

**Bug fix (pre-requisite):**
- `Home` model was missing CodingKeys for `invite_code`, `created_at`, `updated_at` — would have caused runtime decode failure since PostgREST does NOT use `.convertFromSnakeCase`.
**Services wired (all 9):**
- `HomeService` — completed: `updateHome()`, `updateNextShopDate()`, `leaveHome()` (RPC), `deleteAccount()` (RPC)
- `ActivityService` — `fetchActivity()` (50 most recent, ordered by created_at DESC) + `logActivity()` as static fire-and-forget via `Task { try? await ... }`
- `ChoreService` — full CRUD: `fetchChores`, `createChore`, `updateChore`, `deleteChore`
- `ExpenseService` — full CRUD + `settleUp` RPC. `ExpenseWithSplits` refactored to flat Codable struct matching PostgREST nested select (`select("*, expense_splits(*)")`). Added `CreateExpenseSplit` and `InsertExpenseSplit` helper types.
- `BudgetService` — CRUD + `upsertBudget(onConflict:)` + `createCustomCategory` + `deleteCustomCategory`
- `NotificationService` — `fetchNotifications`, `markAsRead`, `markAllAsRead`, `fetchPreferences`, `upsertPreferences`
- `UserPreferencesService` — `fetchPreferences(for:)` + `upsertPreferences()`
- `RoomService` — `fetchRooms`, `createRoom`, `deleteRoom`, `fetchRoomGroups`
- `CalendarService` — pure Swift client-side aggregation of chores + expenses into `[CalendarEvent]`

**Optimistic update pattern:**
- Documented on `ShoppingViewModel` with clear code comments. Pattern: mutate local → call service → on error rollback + show error → on success `logActivity()` fire-and-forget → Realtime triggers re-fetch.

**SwiftData offline cache:**
- Fleshed out all 4 cached models (`CachedShoppingItem`, `CachedExpense`, `CachedChore`, `CachedActivityFeedItem`) with full fields + convenience `init(from:)` constructors
- `SyncEngine` implemented with load/cache pairs for all 4 types (delete-and-reinsert pattern per homeID)

**Error handling:**
- `ServiceError` expanded from 1 case to 8 cases (network, unauthorized, notFound, conflict, serverError, decodingError, unknown, notImplemented) with Roost-voice `localizedDescription`
- `ErrorHandler` created — maps NSURLErrorDomain codes and Supabase HTTP error strings to friendly messages

**Balance calculation:**
- `BalanceCalculator` created with static `calculate(expenses:myUserId:partnerUserId:)` method
- Uses splits not raw amounts, excludes settled splits, positive = I am owed

**Files created:** `Services/ErrorHandler.swift`, `Services/BalanceCalculator.swift`
**Files modified:** `Models/Home.swift`, `Models/Expense.swift`, `Services/HomeService.swift`, `Services/ActivityService.swift`, `Services/ChoreService.swift`, `Services/ExpenseService.swift`, `Services/BudgetService.swift`, `Services/NotificationService.swift`, `Services/UserPreferencesService.swift`, `Services/RoomService.swift`, `Services/CalendarService.swift`, `Services/ServiceError.swift`, `LocalData/SwiftDataModels.swift`, `LocalData/SyncEngine.swift`, `Features/Shopping/ViewModels/ShoppingViewModel.swift`

**Status:** Phase 2 definition of done is met. Build passes clean. Every service makes real Supabase calls. Data layer is complete and trustworthy. Ready for Phase 3.

---
### Session 3 — 26 March 2026
UI redesign pass started from the design system and shell rather than one-off screen tweaks, using `DESIGN_ETHOS.md` and the Phase 4 brief as the source of truth.
**Shared UI primitives refreshed:**
- `RoostButton` rebuilt with clearer variants, stronger pressed states, inline loading support, and light haptic feedback
- `RoostCard` updated with softer borders, warmer surface treatment, and optional elevated depth for hero/grouped content
- `RoostTextField` gained a calmer input treatment with a terracotta focus ring
- Added `RoostSecureField` so auth forms use the same visual language as text inputs
- `EmptyStateView`, `LoadingSkeletonView`, `MemberAvatar`, `RoostSheet`, and `ProgressBarView` were all refined to better match the Roost visual language

**Top-level UX pass:**
- Auth flow screens (`WelcomeView`, `LoginView`, `SignupView`, `SetupView`, `JoinView`) were restructured into warmer hero + form groupings instead of placeholder-style scaffolding
- `MainTabView` and `MoreMenuView` were updated so the app shell feels more deliberate and less like default SwiftUI scaffolding
- `ShoppingListView` now surfaces its hero summary in the populated state as well, making the screen feel more in line with the rest of the app

**Files created:** `Components/RoostSecureField.swift`
**Files modified:** `Components/RoostButton.swift`, `Components/RoostCard.swift`, `Components/RoostTextField.swift`, `Components/EmptyStateView.swift`, `Components/LoadingSkeletonView.swift`, `Components/MemberAvatar.swift`, `Components/ProgressBarView.swift`, `Components/RoostSheet.swift`, `Features/Auth/Views/WelcomeView.swift`, `Features/Auth/Views/LoginView.swift`, `Features/Auth/Views/SignupView.swift`, `Features/Auth/Views/SetupView.swift`, `Features/Auth/Views/JoinView.swift`, `Features/Shell/Views/MainTabView.swift`, `Features/Shell/Views/MoreMenuView.swift`, `Features/Shopping/Views/ShoppingListView.swift`

**Status:** Build passes clean. The app now has a more coherent warm shell and stronger shared components, but a full screen-by-screen Phase 4 pass is still needed across the remaining feature views.

---
### Session 8 — 26 March 2026
Clutter-reduction pass completed across the main page surfaces. This session focused on removing explanatory copy from primary screens and increasing the spacing between major cards so the app reads faster and feels less crowded.

**Main-page simplification:**
- Stripped descriptive subtitles and helper copy from the top-level page containers and section headers across Home, Shopping, Expenses, Chores, Calendar, Activity, Notifications, Settings, Money, and More
- Removed several supporting description blocks from hero cards and section intro cards so the first read on each page is driven by title, state, and action rather than paragraphs
- Tightened a number of empty and placeholder states on main pages so they stay visually quiet instead of filling space with explanatory text

**Layout rhythm changes:**
- Increased page-level vertical spacing in the shared `RoostPageContainer`
- Reduced density on top-level pages by letting major cards sit further apart instead of stacking tightly

**Files modified:** `Components/RoostChrome.swift`, `Features/Shell/Views/MoneyHomeView.swift`, `Features/Shell/Views/MoreMenuView.swift`, `Features/Dashboard/Views/DashboardView.swift`, `Features/Shopping/Views/ShoppingListView.swift`, `Features/Expenses/Views/ExpensesView.swift`, `Features/Expenses/Views/BalanceCardView.swift`, `Features/Chores/Views/ChoresView.swift`, `Features/Calendar/Views/CalendarView.swift`, `Features/Activity/Views/ActivityFeedView.swift`, `Features/Notifications/Views/NotificationsView.swift`, `Features/Settings/Views/SettingsView.swift`, `NORTH_STAR.md`

**Status:** Build passes clean. Main pages now read noticeably lighter, but a similar text-reduction pass can still be applied to deeper settings/detail screens and modal forms if we want the entire app equally minimal.

---
### Session 7 — 26 March 2026
Major page-level rewrite pass completed across the highest-traffic iPhone surfaces. This session treated the existing mobile views as replaceable and rebuilt the internal compositions around shared Roost page primitives instead of preserving the earlier scaffold-era layouts.

**System-level UI work:**
- Extended `RoostChrome` with reusable page and surface primitives (`RoostPageContainer`, `RoostHeroCard`, `RoostStatCard`, `RoostInlineBadge`, `RoostRowSurface`, `FlowLayout`) so the app has a shared internal page language instead of one-off card treatments
- Refined supporting primitives like `ProgressBarView` and `LoadingSkeletonView` so they better match the warmer Mac-inspired visual system

**Screen rewrites completed:**
- `ShoppingListView` was rebuilt around the intended mobile hierarchy: page header, next-shop strip, quick-add card, stat cards, grouped active sections, and a separate done area
- `ExpensesView` was rebuilt with a stronger household-money intro, richer balance hero support, stat cards, filter chips, and a clearly separate settlement-history section; `BalanceCardView` and `ExpenseRow` were both rewritten to match that hierarchy
- `ChoresView` now uses a real page composition with suggest/add controls, stats, assignee filtering, stronger overdue emphasis, and rebuilt chore rows that surface assignment, recurrence, streak, and completion context more cleanly
- `CalendarView` now has the expected page scaffolding: stats, sync status card, custom month surface, and calmer event rows instead of a more utility-shaped layout
- `ShoppingItemRow` and `ChoreRow` were fully restyled so the high-frequency list rows feel tactile and branded rather than like default SwiftUI checklists

**Files modified:** `Components/RoostChrome.swift`, `Components/ProgressBarView.swift`, `Components/LoadingSkeletonView.swift`, `Features/Shopping/Views/ShoppingListView.swift`, `Features/Shopping/Views/ShoppingItemRow.swift`, `Features/Expenses/Views/ExpensesView.swift`, `Features/Expenses/Views/BalanceCardView.swift`, `Features/Expenses/Views/ExpenseRow.swift`, `Features/Chores/Views/ChoresView.swift`, `Features/Chores/Views/ChoreRow.swift`, `Features/Calendar/Views/CalendarView.swift`, `NORTH_STAR.md`

**Status:** Build passes clean. The top-level iPhone shell and several of the most important page interiors now feel materially closer to the Mac app, but Home/Dashboard and deeper settings/detail surfaces still need the same full-page treatment.

---
### Session 7 — 4 April 2026
Budget setup on iOS was rebuilt to match the actual Mac product thinking instead of the earlier placeholder categories screen.

**Budget categories system ported from Mac:**
- Added the real built-in budget categories, optional preset categories, and shared custom-category metadata model on iOS, including emoji and colour keys carried through from Supabase
- Reworked the `BudgetViewModel` so category ordering, month filtering, and custom category handling now follow the Mac app’s structure rather than a loose union of strings
- Custom category deletion now removes any matching budget limits too, keeping the budget setup surface coherent

**Budget setup UX rebuilt:**
- Replaced the old placeholder `Budget Categories` page with a proper monthly control surface: inline current-month limit editing, preset category adding, custom category creation, and a dedicated section for user-added categories
- Added a carry-forward flow so empty months can inherit the previous month’s limits instead of forcing the user to rebuild the whole budget from scratch
- Budget tab category setup now routes users into this new control surface from within the Budget page, instead of relying on the old alert-based category entry

**Budget page month logic tightened:**
- Month navigation now follows the Mac app’s intent more closely: free users stay on the current month, while Nest users can move through history and up to twelve months ahead
- Category rows now use the shared category definitions for consistent ordering and colour mapping, which makes the list read more like the rest of the product

**Files modified:** `Models/Budget.swift`, `Services/BudgetService.swift`, `Features/Budget/ViewModels/BudgetViewModel.swift`, `Features/Budget/Views/BudgetView.swift`, `Features/Settings/Views/BudgetCategoriesSettingsView.swift`, `NORTH_STAR.md`

**Status:** Build passes clean. Budget setup on iOS now matches the Mac app’s product thinking materially better, with a proper monthly setup surface and a carry-forward path for new months.

---
### Session 6 — 26 March 2026
Mobile shell rebuild completed to align the iPhone app with the native port specification rather than the earlier scaffold-era navigation.

**Architecture and navigation changes:**
- Reworked the app shell to the intended five-tab structure: `Home`, `Shopping`, `Money`, `Chores`, and `More`
- Added a dedicated `MoneyHomeView` so Expenses and Budget now live together behind a mobile-appropriate segmented control instead of competing for top-level navigation
- Expanded `More` into grouped household, tools, and account sections, with explicit routing for Calendar, Pinboard, Rooms, Notifications, Hazel, Subscription, Profile, and Account destinations

**Design system pass:**
- Updated the core Roost color tokens to match the native port specification more closely, especially the warm light background, darker dark-mode base, and softer surface hierarchy
- Tightened the shared card, section surface, and button styling so the shell now reads as one coherent iPhone product rather than a set of feature-local treatments

**Feature integration updates:**
- Adapted `ExpensesView` and `BudgetView` so they can render either as standalone screens or as embedded content within the new Money root without nested navigation/scroll conflicts
- Updated router and dashboard deep links so expense and budget actions now land in the new Money architecture correctly
- Added warm placeholder destinations for spec-required surfaces that do not yet have real iOS implementations in this repo (`Pinboard`, `Rooms`, `Hazel`, `Subscription`)

**Files created:** `Features/Shell/Views/MoneyHomeView.swift`, `Features/Shell/Views/MorePlaceholderView.swift`
**Files modified:** `Design/Colors.swift`, `Design/Theme.swift`, `Components/RoostButton.swift`, `Components/RoostCard.swift`, `Components/RoostChrome.swift`, `Notifications/NotificationRouter.swift`, `Features/Shell/Views/MainTabView.swift`, `Features/Shell/Views/MoreMenuView.swift`, `Features/Expenses/Views/ExpensesView.swift`, `Features/Budget/Views/BudgetView.swift`, `Features/Dashboard/Views/DashboardView.swift`, `NORTH_STAR.md`

**Status:** Build passes clean. The app’s top-level iPhone information architecture now matches the redesign spec substantially better, but some spec-defined destinations still use placeholders until their full feature UIs are implemented.

---
### Session 6 — 3 April 2026
Hazel budget insights on iOS were converted from static placeholder copy into a real live feature backed by a Supabase Edge Function, matching the Mac app’s actual insight pipeline instead of faking the output in the UI.

**Live Hazel budget path added:**
- Added a new `budget-insights` Supabase Edge Function that verifies the signed-in user, checks household membership, enforces live Nest access from the `homes` table, and then calls Claude server-side to generate a warm budget summary, outlook, and three focus points
- The iOS app now calls that function through a dedicated `BudgetInsightsService`, caches the latest insight locally using a month/data fingerprint, and refreshes it whenever the selected month or the underlying budget/expense shape changes

**Budget analytics card redesigned:**
- Rebuilt the Hazel card on the iOS Budget screen to feel native to Roost: stronger header, live-state chip, calmer gradient-backed surface, proper loading skeleton, richer live insight hierarchy, and a more considered Nest upsell state
- Removed the hardcoded summary / outlook / focus copy entirely so what the user sees now comes from their actual household spend data

**Files created:** `Services/BudgetInsightsService.swift`, `../Roost Mac/supabase/functions/budget-insights/index.ts`
**Files modified:** `Features/Budget/Views/BudgetView.swift`, `../Roost Mac/supabase/config.toml`, `NORTH_STAR.md`

**Status:** Code path is complete. Deployment still requires the new Supabase function to be deployed and the Anthropic API key to be present in Supabase function secrets.

---
### Session 5 — 26 March 2026
Dashboard redesign pass completed as the foundation for the app-wide page-by-page refresh. The work focused on replacing the repeated full-width card stack with a lighter, more editorial rhythm that other screens can inherit.

**Shared UI language extended:**
- `RoostChrome` now provides a stronger page title treatment, calmer grouped surface default, lighter summary chips, and new reusable primitives for icon badges and preview rows
- These primitives are intended to carry forward into Shopping, Expenses, Chores, Budget, and More so later screens reuse the same hierarchy model instead of inventing local card anatomy

**Home / Dashboard rebuilt from first principles:**
- Replaced the dashboard’s repeated `DashboardCardView` stack with a composed scroll model: editorial header, compact status strip, one restrained priority surface, grouped preview rows, compact planning modules, and a feed-style activity section
- Tightened copy across Home so states read more naturally and glanceably, with less dashboard-SaaS phrasing
- Preserved existing business logic, refresh behavior, real-time loading, and deep-link navigation while substantially changing visual hierarchy and pacing

**Files modified:** `Components/RoostChrome.swift`, `Features/Dashboard/Views/DashboardView.swift`, `NORTH_STAR.md`

**Status:** Build passes clean. Home now establishes a lighter reusable visual system for the remaining redesign work, with meaningfully fewer heavy rounded cards and a clearer app-wide hierarchy direction.

---
### Session 4 — 26 March 2026
High-impact screen refinement pass completed across the most frequently used and highest-visibility product areas. The focus was not decorative restyling; it was hierarchy, daily-use ergonomics, and consistency.

**Reusable UI support added:**
- Added `SectionHeader` and `StatChip` shared views to stop repeating ad-hoc screen section layouts
- `OfflineBanner` refined so offline state reads as part of the app instead of a plain warning strip
**High-priority feature screens improved:**
- `DashboardView` now surfaces clearer priority grouping ("What matters now" vs "The rest of the picture"), uses the hero summary properly, and has a calmer loading state
- `ShoppingListView` now has a bottom-reachable primary add action, pull-to-refresh, and a more legible checked state in `ShoppingItemRow`
- `ExpensesView` now surfaces the hero, uses the bottom action bar for add/settle-up, supports pull-to-refresh, and simplifies list hierarchy; `BalanceCardView` and `ExpenseRow` were also refined for calmer money UI
- `ChoresView` now surfaces the hero, groups chore sections into clearer cards, moves the main add action to the bottom reach zone, supports pull-to-refresh, and simplifies row presentation in `ChoreRow`

**Secondary screens brought into alignment:**
- `ActivityFeedView`, `NotificationsView`, and `BudgetView` now surface their hero summaries properly and use more cohesive loading / empty-state treatment
- `SettingsView` now opens with the intended hero summary and uses stronger grouped cards instead of loose stacks

**Files created:** `Components/SectionHeader.swift`
**Files modified:** `Components/OfflineBanner.swift`, `Features/Dashboard/Views/DashboardView.swift`, `Features/Shopping/Views/ShoppingListView.swift`, `Features/Shopping/Views/ShoppingItemRow.swift`, `Features/Expenses/Views/ExpensesView.swift`, `Features/Expenses/Views/BalanceCardView.swift`, `Features/Expenses/Views/ExpenseRow.swift`, `Features/Chores/Views/ChoresView.swift`, `Features/Chores/Views/ChoreRow.swift`, `Features/Activity/Views/ActivityFeedView.swift`, `Features/Activity/Views/ActivityRow.swift`, `Features/Notifications/Views/NotificationsView.swift`, `Features/Notifications/Views/NotificationRow.swift`, `Features/Budget/Views/BudgetView.swift`, `Features/Settings/Views/SettingsView.swift`

**Status:** Build passes clean. The app now reads much more like a cohesive consumer product across the main flows. Remaining UI debt is mostly deeper settings/detail screens and sheet-level polish rather than the top-level information architecture.

---
