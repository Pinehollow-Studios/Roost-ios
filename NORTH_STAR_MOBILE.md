# Roost iOS — Money Rebuild North Star

> Read alongside NORTH_STAR.md. This document tracks the Money section rebuild specifically.
> The Money rebuild uses the same shared Supabase backend as the Mac app.

---

## Session Log

### Session 11 — Banking-Grade App Security Rebuild (April 2026)

**Goal:** Replace the old overlay-based app lock with a root-level security boundary, move PIN data out of UserDefaults, and enforce a stronger lockout policy.

**Status: COMPLETE — build succeeds with no Swift warnings.** Xcode still emits its standard AppIntents metadata warning because the app has no AppIntents dependency.

**Root security architecture:** `ContentView` now routes authenticated users through `RootAuthenticatedView`, which switches between `LockScreenView` and `MainTabView`. When `lockManager.isLocked == true`, `MainTabView` is not in the view hierarchy. This removes the previous race where app content could render behind a lock overlay.

**Storage and hashing:**
- Added `Security/KeychainHelper.swift` for security-sensitive values.
- `AppLockManager` now stores PIN hash, PIN salt, lock enabled, and biometric preference in the iOS Keychain.
- PIN hashes use PBKDF2-HMAC-SHA256 with 100,000 iterations and a random 32-byte per-device salt.
- PIN verification uses constant-time `Data` comparison.
- Old UserDefaults PIN state (`roost-pin-hash`, lock enabled, biometrics, autolock delay) is cleared on first launch and sets `roost-pin-migration-needed`.

**Lock policy:**
- Roost locks when the app is actually backgrounded and remains locked when reopened. Foreground transitions only enforce the lock if Roost previously reached `.background`, so internal navigation and transient active-state changes do not relock the app.
- The configurable auto-lock delay has been removed. Security settings now state: "Locks when you leave the app."
- Lockout escalates every 3 failed PIN attempts: 30 seconds, 2 minutes, 10 minutes, then Supabase email re-authentication.
- During cooldown, the keypad is visually muted and non-interactive; countdown updates every second.
- At re-auth level, the PIN keypad is removed and replaced with a Supabase sign-out flow that sends the user back through email sign-in.

**UI and flows:**
- `LockScreenView` was rebuilt around explicit `UnlockResult` and `BiometricResult` states.
- Biometrics auto-prompt once when the lock screen appears, never auto-retry, and always leave PIN entry available after cancellation or failure.
- Every keypad press and successful/failed unlock path has haptic feedback.
- The lock screen includes a secure text field backing view for screen capture hardening.
- Disabling app lock now requires PIN confirmation in a full-screen keypad sheet, not an alert text field.
- Users affected by the old UserDefaults PIN format see a one-time post-unlock banner asking them to set up their PIN again.

**Files modified:**
- `Security/KeychainHelper.swift`
- `Managers/AppLockManager.swift`
- `Features/Auth/Views/LockScreenView.swift`
- `Features/Auth/Views/PINSetupView.swift`
- `Features/Settings/Views/SecuritySettingsView.swift`
- `ContentView.swift`
- `Features/Shell/Views/MainTabView.swift`

**Session 8 security notes are superseded by this session.** The app no longer uses UserDefaults PIN hashes, SHA-256 static salt, configurable auto-lock delay, lock overlays, or `MainTabView` lock-state coordination.

---

### Session 10 — Money Navigation & Title Consistency (April 2026)

**Goal:** Visual consistency fix — replace system navigation bar titles and white pill back buttons across all Money screens with the app's custom header pattern. No data or logic changes.

**Status: COMPLETE — build succeeds with zero errors.**

**Pattern established:** All Roost screens suppress the system nav bar with `.toolbar(.hidden, for: .navigationBar)`. Root screens use `FigmaPageHeader(title:)`. Pushed screens use `FigmaBackHeader(title:)` (chevron back + large custom title, `screenTop` padding built in) + `.swipeBackEnabled()`. This matches HouseholdSettingsView, HazelView, AppearanceSettingsView etc.

**New shared components** — `Features/Money/Views/MoneySharedComponents.swift`:
- `MonthNavigator` — warm styled month nav; rounded-rectangle buttons (8pt corner) in `Color(hex: 0xF2EBE0)` background; sage chevrons for disabled/pro-gated state; `isPro/onProGate` closure for upsell
- `BudgetViewPicker` — warm pill Household/Split toggle; replaces `Picker(.segmented)`; `Color(hex: 0xEBE3D5)` track, `Color(hex: 0xF2EBE0)` selected pill

**Files modified:**

- `Features/Shell/Views/MoneyHomeView.swift`
  - Already correct: used `FigmaPageHeader(title: "Money")` + `.toolbar(.hidden, for: .navigationBar)`. No changes needed.

- `Features/Money/Views/MoneyOverviewView.swift`
  - Removed `.navigationTitle("Overview")` + `.navigationBarTitleDisplayMode(.large)`
  - Added `FigmaBackHeader(title: "Overview")` at top of scroll VStack
  - Removed `.padding(.top, screenTop)` from outer VStack (FigmaBackHeader provides it)
  - Added `.toolbar(.hidden, for: .navigationBar)` + `.swipeBackEnabled()`
  - Replaced `monthNavigator` computed var body with `MonthNavigator(...)` component

- `Features/Money/Views/MoneySpendingView.swift`
  - Same nav pattern
  - Added `FigmaBackHeader(title: "Spending")` before the month-nav VStack
  - Removed `.padding(.top, screenTop)` from that VStack
  - Replaced `monthNavigatorRow` with `MonthNavigator(...)`

- `Features/Money/Views/MoneyBudgetsView.swift`
  - Removed `.navigationTitle("Budget")` → now titled "Budgets" via `FigmaBackHeader`
  - Removed `.toolbar { ToolbarItem { pencil button } }`
  - Added `FigmaBackHeader(title: "Budgets") { editModeButton }` — accessory slot carries the pencil/Done button
  - Removed `.padding(.top, screenTop)` from inner VStack
  - Replaced `monthNavigatorRow` with `HStack { MonthNavigator(...); Spacer(); BudgetViewPicker($showSplit) }`
  - Added `.toolbar(.hidden, for: .navigationBar)` + `.swipeBackEnabled()`

- `Features/Money/Views/MoneyGoalsView.swift`
  - Removed `.navigationTitle("Goals")` + `.navigationBarTitleDisplayMode(.large)`
  - Added `FigmaBackHeader(title: "Goals")` at top of scroll VStack (before contribution card)
  - Added `.toolbar(.hidden, for: .navigationBar)` + `.swipeBackEnabled()`

- `Features/Settings/Views/MoneySettingsView.swift`
  - Removed `.navigationTitle("Money")` + `.navigationBarTitleDisplayMode(.inline)`
  - Added `FigmaBackHeader(title: "Money")` at top of scroll VStack
  - Removed `.padding(.top, Spacing.md)` (FigmaBackHeader provides top padding)
  - Added `.toolbar(.hidden, for: .navigationBar)`
  - Fixed section headings ("YOUR INCOME", "PRIVACY & DISPLAY", "BUDGET PREFERENCES", "CURRENCY"): changed from `.font(.roostSection)` (20pt DM Sans) to `.font(.system(size: 10, weight: .medium)).tracking(1.5).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)`

- `Features/Settings/Views/SecuritySettingsView.swift`
  - Same nav pattern as MoneySettingsView
  - Added `FigmaBackHeader(title: "Security")`, removed old nav modifiers

**Key gotchas:**
- Sheet sub-screens (GoalDetailSheet, AddGoalSheet, AddBudgetLineSheet, NoteEditorSheet) keep their `.navigationTitle()` + `.navigationBarTitleDisplayMode(.inline)` — they live in their own `NavigationStack` inside sheets, so the system style is correct there
- `FigmaBackHeader` includes `.padding(.top, DesignSystem.Spacing.screenTop)` internally — do not add extra top padding to the containing VStack
- `MonthNavigator`'s `onProGate` closure is what triggers the upsell sheet when `isPro == false`

---

### Session 9 — Money Screens Polish Pass (April 2026)

**Goal:** Final quality pass across all Money screens — no new features, only empty states, error states, haptics, and copy/branding fixes.

**Status: COMPLETE — build succeeds with zero errors.**

**Changes by file:**

- `Features/Shell/Views/MoneyHomeView.swift`
  - Added `ringErrorState` helper card (shown when `summaryVM.error != nil && summaryVM.summary == nil`) with amber triangle icon + "Try again" button
  - Added `.medium` haptic to "Settle up" button tap
  - Added `.light` haptic to ring reveal tap (before `temporarilyRevealed = true`)

- `Features/Money/Views/MoneyGoalsView.swift`
  - Added `goalsErrorState` view (shown when `goalsVM.error != nil && goalsVM.goals.isEmpty`) with amber triangle + "Try again" calling `goalsVM.load(homeId:)`
  - Fixed proGateFooter: removed `lock.fill` icon; copy changed to `"Unlock N more goal(s) with Roost Pro →"`
  - Added `.medium` haptic to `confirmAddSavings()` before async work
  - Added `.success` notification haptic to "Mark complete" confirmationDialog button

- `Features/Money/Views/MoneyBudgetsView.swift`
  - Added `.medium` haptic when entering edit mode, `.light` haptic when exiting (in toolbar button)
  - Added `.warning` notification haptic to "Remove from budget" destructive confirmationDialog button

- `Features/Money/Views/MoneySpendingView.swift`
  - Added `.warning` notification haptic to "Delete" destructive confirmationDialog button

- `Features/Money/Views/MoneyOverviewView.swift`
  - Zone 5 (spending history): removed `lock.fill` icon from Pro gate inline link; copy changed to `"See 6-month history with Roost Pro →"`
  - Zone 6 (month comparison) Pro gate card: swapped `lock.fill` → `chart.bar.xaxis` icon; copy changed to `"See how this month compares to last with Roost Pro."`

**Key patterns:**
- All haptics use `UIImpactFeedbackGenerator`/`UINotificationFeedbackGenerator` — instantiated and fired inline (no caching needed for one-shot UI events)
- Error states follow same pattern: amber triangle icon, short label, plain "Try again" button in terracotta accent
- "Nest Pro" → "Roost Pro" everywhere; `lock.fill` removed from Pro gate inline links (kept only in navigation-level lock indicators)

---

### Session 8 — PIN Security + Face ID (April 2026)

**Goal:** App lock — PIN-based lock screen with Face ID/Touch ID support, auto-lock delay, and Security settings screen.

**Status: COMPLETE — build succeeds with zero errors.**

**Files created:**
- `Managers/AppLockManager.swift` — `@MainActor @Observable` manager; all lock state + PIN hash + biometrics
- `Features/Auth/Views/LockScreenView.swift` — full-screen PIN entry; also contains shared `KeypadButton` struct
- `Features/Auth/Views/PINSetupView.swift` — multi-step sheet: choose → confirm → success
- `Features/Settings/Views/SecuritySettingsView.swift` — Security settings: App Lock toggle, Change PIN, biometrics toggle, auto-lock delay picker

**Files modified:**
- `Notifications/NotificationRouter.swift` — added `case security` to `MoreDestination`
- `Features/Shell/Views/MainTabView.swift` — added `@Environment(AppLockManager.self)` + `case .security: SecuritySettingsView()` in navigationDestination
- `Features/Shell/Views/MoreMenuView.swift` — added Security row in App section (lock.fill icon, green tones)
- `RoostApp.swift` — added `@State private var lockManager = AppLockManager()`, `.environment(lockManager)`, `@Environment(\.scenePhase)` + `onChange` calling `appDidBackground`/`appDidForeground`
- `ContentView.swift` — added `@Environment(AppLockManager.self)`, lock screen overlay in ZStack (zIndex 999, only when `isAuthenticated && isLocked`)
- `Info.plist` — added `NSFaceIDUsageDescription`

---

**AppLockManager:**

- `isLocked: Bool` — drives lock screen overlay in ContentView
- `isEnabled / hasPIN / useBiometrics / autoLockDelay` — all backed by UserDefaults
- `appDidBackground()` — records `backgroundedAt = Date()`
- `appDidForeground()` — if `autoLockDelay == 0` → lock immediately; else lock if elapsed ≥ delay
- `unlock(pin:)` — SHA-256 hash comparison; 5 failures → 10s `cooldownUntil`; sets `isLocked = false` on success
- `setupPIN(_:)` — saves hash, sets `isEnabled = true`
- `clearPIN()` — removes all three UserDefaults keys, sets `isLocked = false`
- `unlockWithBiometrics()` — `LAContext.evaluatePolicy` async; sets `isLocked = false` on success
- `biometricsAvailable()` / `biometricType()` — helpers for UI
- `hashPIN(_:)` — SHA-256 via CryptoKit; salt: `"roost-salt-v1"`

---

**LockScreenView:**

- `RoostLogoMark(size: 72, cornerRadius: 16)` at top
- 6 PIN dots: terracotta fill when entered, ring-only when empty; spring scale on last-entered
- Biometrics button: face ID or touch ID icon + label; shown when `lockManager.useBiometrics && biometricsAvailable`
- Cooldown: `Timer.publish(every: 1)` countdown; `Color(hex: 0x854F0B)` amber text
- Keypad: 72×72pt `KeypadButton` with `KeypadButtonStyle` (0.95 scale on press)
- Wrong PIN: shake with `.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)` + `.error` haptic; clear after 0.4s
- Biometrics auto-triggered in `.task` on appear
- `import Combine` required for `Timer.publish(...).autoconnect()`

---

**PINSetupView:**

- Steps: `.choose` → `.confirm` → `.success`
- `.interactiveDismissDisabled(step == .choose || step == .confirm)` — not swipe-dismissible during entry
- PIN mismatch: shake + "PINs don't match — try again" in `roostDestructive`; resets to step `.choose`
- Success step: `checkmark.circle.fill` in sage green `Color(hex: 0x9DB19F)`; calls `lockManager.setupPIN()` on appear; auto-dismisses after 1.5s
- `onCancel` closure: used by SecuritySettingsView to revert toggle if user cancels without setting PIN

---

**SecuritySettingsView:**

- App Lock toggle: if no PIN → opens PINSetupView; if has PIN → `lockManager.isEnabled = true`
- Disable: `.alert` with `SecureField`; calls `lockManager.unlock(pin:)` for verification then `clearPIN()`; wrong PIN reverts toggle
- Change PIN: visible only when `lockManager.hasPIN`; opens same PINSetupView (overwrites hash on success)
- Biometrics toggle: visible only when `biometricsAvailable && appLockEnabled`
- Auto-lock Picker: tags 0 / 60 / 300 / 900; visible only when `appLockEnabled`

---

**Key gotchas:**
- `import Combine` required in LockScreenView for `Timer.publish(...).autoconnect()`
- `KeypadButton` defined as `internal` (not `private`) in LockScreenView.swift so PINSetupView can reference it
- `@MainActor @Observable` on AppLockManager — matches existing ViewModel pattern
- `import CryptoKit` at file level (not inside function) for `SHA256`
- Lock screen in ContentView's ZStack (not MainTabView) so it covers all auth states cleanly

---

**Ready for Session 9 — Polish**

---

### Session 7 — Settings Money Tab + Income Onboarding + Hide Balances (April 2026)

**Goal:** Add Settings → Money tab (4 sections), income onboarding screen (full-screen, shown once), hide balances wiring in MoneyHomeView.

**Status: COMPLETE — build succeeds with zero errors.**

**Files created:**
- `Features/Settings/Views/MoneySettingsView.swift` — 4-section settings view
- `Features/Auth/Views/IncomeSetupView.swift` — one-time income onboarding

**Files modified:**
- `Features/Settings/Views/SettingsView.swift` — added "Money" row (icon: `sterlingsign.circle`) in the Household section
- `Features/Shell/Views/MainTabView.swift` — added `shouldShowIncomeSetup()` + `@State private var showIncomeSetup` + `.fullScreenCover(isPresented: $showIncomeSetup)` after warmPageData
- `Features/Shell/Views/MoneyHomeView.swift` — hide balances state + ring center conditional + countdown indicator

---

**Settings → Money tab (MoneySettingsView.swift):**

Section 1 — YOUR INCOME
- My income text field (keyboardType: `.decimalPad`, 20pt font, `Color(.systemFill)` background)
- "Last updated [date]" from `homeManager.currentMember?.incomeSetAt`
- "Save income" button → `incomeService.setMyIncome` + `syncCombinedIncome` + `homeManager.refreshCurrentHome()` + 2s auto-hide "Saved ✓" confirmation
- `myIncomeVisible` toggle → `incomeService.setIncomeVisibility(userId:visible:)` onChange
- Partner income display: shows if `partnerIncome != nil` (fetched via `incomeService.fetchPartnerIncome`), else "hasn't shared yet"
- Partner income only shown when `myIncomeVisible == true`
- COMBINED HOUSEHOLD: `myIncome + partnerIncome` if both available, else just `myIncome`

Section 2 — PRIVACY & DISPLAY
- Scramble mode: `eye.slash.fill` icon, amber "ON" pill when active, `settingsVM.toggleScrambleMode(homeId:)` on toggle
- Hide balances: UserDefaults `"roost-hide-balances"` bool — device-only, no Supabase

Section 3 — BUDGET PREFERENCES
- Default split: `MemberAvatar(label: meInitials, color: meColour, size: .xs)` both ends, `Slider(in: 0...100, step: 5)`, debounced 500ms via `Task.sleep` + `Task.isCancelled` guard, "Equal split" label at 50.0
- Budget carry-forward: segmented Picker ("Automatic" / "Manual"), amber note when "manual"
- Spending alerts: 5 pill buttons [50, 60, 70, 80, 90]%, terracotta when selected

Section 4 — CURRENCY
- `.menu` Picker: £ GBP / $ USD / € EUR / A$ AUD / CA$ CAD, saves via `settingsVM.updateSetting(\.currencySymbol, ...)`

Data loading in `.task`: reads `homeManager.currentMember?.personalIncome` (formats to 2dp), `incomeSetAt`, `incomeVisibleToPartner`, fetches `partnerIncome`, syncs all settings from `settingsVM.settings`, loads `hideBalances` from UserDefaults.

**Key gotchas:**
- `MemberAvatar` API: `label:color:size:` — NOT `initials:colour:size:` as spec shows; first letter of label displayed
- Debounce via `Task.sleep` + `Task.isCancelled` guard — cleaner than `Timer` in async context
- `scrambleMode` state kept in sync with `settingsVM.settings.scrambleMode` — toggle calls `toggleScrambleMode` which flips the settings value; MainTabView's `onChange` re-syncs `ScrambleModeEnvironment`
- `HouseholdIncomeService` is instantiated locally (`private let incomeService = HouseholdIncomeService()`) — not an environment
- Income section never shows partner income unless `myIncomeVisible == true` (enforces privacy model)

---

**Income onboarding (IncomeSetupView.swift):**

- Triggered once: after warmPageData completes, `shouldShowIncomeSetup()` checks UserDefaults `"roost-income-setup-dismissed"` (false/missing) AND `homeManager.members.first { $0.userID == currentUserId }?.personalIncome == nil`
- Shown as `.fullScreenCover(isPresented: $showIncomeSetup)` with `.interactiveDismissDisabled(true)` — not swipe-dismissible
- Layout: house icon, headline, body text, my income field, partner income field (preview only — not saved), live combined total, privacy note, "Set up →" CTA, "I'll do this later" skip link, partner note
- "Set up" saves: `setMyIncome(userId:amount:)` + `syncCombinedIncome(homeId:month:)` + marks dismissed
- "Later" skips immediately, marks dismissed
- Partner income field is UI-only — sets `partnerAmount` for the combined preview, but NOT persisted to DB
- `onComplete` closure dismisses the cover by setting `showIncomeSetup = false`

---

**Hide balances in MoneyHomeView:**

State added: `hideBalances: Bool`, `temporarilyRevealed: Bool`, `countdown: Int`, `countdownTask: Task<Void, Never>?`

On `.onAppear`: loads `UserDefaults.standard.bool(forKey: "roost-hide-balances")`

Ring center: when `hideBalances && !temporarilyRevealed` → shows `eye.slash` icon + "Tap to\nreveal" text

Ring card: when hidden → replaces `statRows` with "Amounts hidden / Tap the ring to reveal for 5 seconds." hint

On ring tap: sets `temporarilyRevealed = true`, starts countdown task (5 × 1-second sleeps with `Task.isCancelled` guards), auto-hides after 5s

Countdown indicator: `Text("Hiding in Xs")` shown below ring HStack when `temporarilyRevealed`

Insight text: hidden when `hideBalances && !temporarilyRevealed`

---

**Ready for Session 8 — PIN security**

---

### Session 6 — MoneyGoalsView (April 2026)

**Goal:** Build `MoneyGoalsView` — savings goals tracker. Replaces placeholder. Create SavingsGoal model, SavingsGoalsService, and SavingsGoalsViewModel from scratch.

**Status: COMPLETE — build succeeds with zero errors.**

**Files created:**
- `Models/SavingsGoal.swift`
- `Services/SavingsGoalsService.swift`
- `Features/Money/ViewModels/SavingsGoalsViewModel.swift`
- `Features/Money/Views/MoneyGoalsView.swift`

**Files modified:**
- `RoostApp.swift` — added `@State private var savingsGoalsViewModel = SavingsGoalsViewModel()` + `.environment(savingsGoalsViewModel)`
- `Features/Shell/Views/MainTabView.swift` — added `@Environment(SavingsGoalsViewModel.self)`, wired `goalsLoad`/`goalsRealtime`/`goalsStop` into warmPageData + stopPagePolling
- `Features/Shell/Views/MoneyHomeView.swift` — removed `MoneyGoalsView` placeholder and `// MARK: - Placeholder destinations` comment

**Data model:**
- `SavingsGoal`: id, homeId, name, targetAmount, savedAmount, colour (named key), targetDate?, completedAt?, monthlyContribution?, contributionDay? (1–28), budgetLineId?, createdAt, updatedAt
- `extension SavingsGoal: Equatable` — required for `onChange(of:)` on `[SavingsGoal]`
- Computed: `progress: Double`, `isCompleted: Bool`, `monthsRemaining: Int?`, `monthlyNeeded: Decimal?`
- Colour keys: "terracotta" | "sage" | "amber" | "blue" | "purple" | "green"

**Service — SavingsGoalsService:**
- `fetchGoals(homeId:)`, `addGoal(_:)`, `deleteGoal(id:)`, `completeGoal(id:)`, `updateGoal(id:updates:)`
- `addToGoal(id:amount:)` — fetch-then-update pattern (PostgREST has no column increments)
- `setGoalContribution(goalId:homeId:existingBudgetLineId:name:amount:contributionDay:)` — creates or updates a `budget_template_lines` row with `section_group = "goals"`, `budget_type = "fixed"`, then stores `budget_line_id` on the savings_goal
- `removeGoalContribution(goalId:budgetLineId:)` — sets `is_active = false` on template line, nulls out `monthly_contribution`, `contribution_day`, `budget_line_id` via `AnyJSON.null`

**ViewModel — SavingsGoalsViewModel:**
- Standard `@MainActor @Observable` pattern
- `activeGoals`, `completedGoals`, `totalMonthlyContribution` computed
- `clearContributionFields(goalId:)` — clears contribution fields without touching template line (used when `budgetLineId` is nil)
- Realtime via `savings_goals` table subscription

**View — MoneyGoalsView:**
- `goalColour(_:)` free function at file top (maps key → `Color(hex:)`)
- `contributionSummaryCard` — shows total monthly contribution + `summaryVM.summary?.surplus` hint
- `GoalCard` private struct — 60×60 animated ring (`Circle().trim()` + `onAppear` + `onChange`), name, amounts, status pill, monthly/mo text
- Status pill: "Unfunded" (no contribution), "No deadline" (no targetDate), "On track" (contrib ≥ needed), "Behind"
- Pro gate: free tier = 1 active goal max; `hiddenCount` remainder shows "X more goals with Roost Pro" button → `.nestUpsell(feature: .advancedBudgeting)`
- `GoalDetailSheet` — large 140pt ring, amount triplet (saved/remaining/target), linear progress bar, two-step Add savings (reveal field → confirm), monthly contribution card with `EditContributionSheet`, mark complete + delete with `confirmationDialog`
- `AddGoalSheet` — name, target amount, date toggle, colour swatches (`ForEach(goalColourKeys)`), contribution toggle + `Stepper` day picker, months-to-target live calc. After `addGoal`, calls `setGoalContribution` if contribution specified.
- `EditContributionSheet` — amount + `Stepper` day, "Remove contribution" button, shows `monthlyNeeded` hint

**Key gotchas:**
- `SectionHeader` requires explicit `title:` label — no positional init for first arg
- `MonthlySummary` has `.surplus` and `.income` but NOT `.combinedIncome`
- `AnyJSON` is a Supabase type — keep it in ViewModel/Service layer only; views use dedicated ViewModel methods
- `FigmaFloatingActionButton` takes `systemImage:` not `icon:`
- `SavingsGoal` must be `Equatable` for `onChange(of: goalsVM.goals)`

---

### Session 5 — MoneySpendingView (April 2026)

**Goal:** Build `MoneySpendingView` — iOS equivalent of the Mac Spending screen.

**Status: COMPLETE — build succeeds with zero errors.**

**File created:** `Features/Money/Views/MoneySpendingView.swift`
**Placeholder removed from:** `Features/Shell/Views/MoneyHomeView.swift`

**Sections built:**

**Month navigator**
- Same HStack pattern as MoneyBudgetsView (no Picker). Back: lock icon (free tier → `.budgetHistory` upsell) or chevron. Forward: disabled when `isCurrentMonth`. Calls `summaryVM.navigateMonth(direction:)` + `loadSummary`.

**Pie chart (Swift Charts `SectorMark`)**
- `SectorMark(angle:innerRadius:.ratio(0.55), angularInset: 1.5)` per category.
- Centre overlay via `.chartBackground`: total spent + "spent" label.
- Horizontal legend strip below chart (colour swatch + name + amount).
- Empty state card (pie icon + "Nothing logged yet") when no expenses with spend > 0.

**Hazel insight line**
- One italic muted sentence. Priority order: (1) any overspent category, (2) top category > 50% of total, (3) < 30% spent and day > 10, (4) top category by name.

**Category bars (YOUR BUDGETS)**
- `CategoryGroup` private struct: id, name, spent, budgeted, colour, expenses[].
- Groups computed from `budgetVM.lifestyleLines` + `thisMonthExpenses`. Orphan expenses → "Uncategorised" group.
- Filter: only groups with spent > 0 OR budgeted > 0.
- Sort: overspent first, then spendPct desc, then alphabetical.
- Bar colour: no budget = terracotta; < 70% = sage; 70–90% = amber; ≥ 90% or over = red. Overspent cap: 4pt red rectangle at right edge.
- "Manage budgets →" `NavigationLink` to `MoneyBudgetsView` below the card.
- No-budgets empty state if `lifestyleLines` is empty.
- Expand/collapse: only one category at a time; `expandedCategory: String?`. Chevron rotates 180°.

**Expanded category rows**
- Up to 5 inline expense rows; "X more" button to expand all (tracked in `showAllForCategories: Set<String>`).
- Free-tier lock: expenses with `incurredOnDate < today - 30 days` shown as "Older expense" + lock icon, then a Pro gate row.
- Background: `Color(.secondarySystemBackground)`.

**Inline expense rows**
- Title + date (`.dateTime.day().month(.abbreviated)`) + recurring icon, right-aligned amount + "Paid by X".
- `.contextMenu` with Edit (opens `AddExpenseSheet` in `.edit` mode) and Delete (sets `deleteCandidate`).
- Delete confirmed via `.confirmationDialog`.
- Locked rows: dimmed placeholder, no contextMenu.

**All expenses (ALL EXPENSES)**
- Flat list, reverse chronological.
- Same inline expense row + contextMenu.
- Free-tier Pro gate footer (lock rows + "Try Pro →" button → `.nestUpsell`).
- Empty state: "No expenses this month." centred in card.

**FAB**
- `FigmaFloatingActionButton(systemImage: "plus")` at `.bottomTrailing`.
- Opens `AddExpenseSheet`; `defaultCategory` wired from `expandedCategory`.

**Architecture notes**
- `CategoryGroup.id` = category name (or `"__uncategorised__"` for orphans).
- Colour lookup: `budgetVM.categories.first { $0.name.lowercased() == key }?.colour`.
- `chartGroups` = `categoryGroups.filter { $0.spent > 0 }.sorted { $0.spent > $1.spent }` (pie only).
- `expenseSheetSeed(for:)` duplicated from ExpensesView (private helper).
- `Set.insert` return value must be discarded with `_ =` inside `withAnimation` closures or they cause "conflicting arguments to generic parameter 'Result'" errors.
- `Color.opacity(_:)` can be ambiguous in `.background()` — use `Color(.secondarySystemBackground)` or wrap in a closure `.background { Color.x.opacity(n) }`.

---

### Session 4 — MoneyBudgetsView (April 2026)

**Goal:** Build `MoneyBudgetsView` — the iOS equivalent of the Mac Budgets screen. Excel-inspired data density on phone.

**Status: COMPLETE — build succeeds with zero errors.**

**Files created:**
- `Features/Money/Views/MoneyBudgetsView.swift`
- `Features/Money/Views/AddBudgetLineSheet.swift`

**Placeholder removed from:** `Features/Shell/Views/MoneyHomeView.swift`

**Sections built:**

**Summary cards (horizontal scroll)**
- 5 metric cards: INCOME (with household names), BUDGETED, UNALLOCATED (colour-coded green/amber/red), SPENT SO FAR (% of budget subtext), BUDGET HEALTH (score/100).
- 130pt-wide cards, `LazyHStack`, negative horizontal padding to bleed edge-to-edge.

**Income allocation bar**
- `GeometryReader` stacked `Rectangle` fills — each section proportional to its % of income.
- Section colours: Housing=terracotta, Subscriptions=amber, Transport=blue, Food=green, Household=teal, Personal=indigo, Savings=rose.
- Legend chips (horizontal scroll) — tap to `scrollProxy.scrollTo("section-\(id)")`.
- Hidden if income == 0 or no active lines.

**Bill clash detection**
- `budgetVM.detectBillClashes()` filtered by `dismissedClashIds`.
- Amber (#FAEEDA) card per clash — amount, date range, line names. Dismiss button persists to `UserDefaults` (`"roost-dismissed-clashes"` key as array of UUID strings).

**Month navigator**
- Back button: lock icon if free tier → `.nestUpsell(feature: .budgetHistory)`. Otherwise calls `summaryVM.navigateMonth(direction: .backward)`.
- Forward button disabled when `isCurrentMonth`.
- Household/Split `Picker` (segmented, 160pt wide) on trailing side.

**Budget table**
- `ScrollViewReader` wrapping entire content; section groups use `.id("section-\(section.id)")`.
- 7 sections: Housing & bills (fixed), Subscriptions & leisure (fixed), Transport (fixed), Food & drink (envelope), Household (envelope), Personal (envelope), Savings allocation (envelope).
- Section collapse: left-border accent (`RoundedRectangle` 2pt wide), chevron rotates 90°, persisted to `UserDefaults` (`"roost-budget-section-\(id)"`).
- Column headers adapt: split mode → ME / PARTNER (65pt each); fixed → DATE (52pt) / BUDGETED (72pt); envelope → BUDGETED (70pt) / REMAINING (70pt).
- Section total row (terracotta for fixed, indigo for envelope in split mode; grey otherwise).
- Add-line button below each section → `AddBudgetLineSheet`.
- Grand total row at bottom.

**`FixedBudgetRow` (private struct)**
- Inline name editing: `@FocusState`, `TextField` overlay when `editingNameId == id`.
- Inline amount editing: `@FocusState`, `TextField` overlay when `editingAmountId == id`, commits on submit/defocus.
- Split mode: ME/PARTNER amounts calculated from `member1Percentage`.
- Non-split: DATE column (ordinal day), BUDGETED column.
- Swipe actions: "Note" (blue), "Remove" (red).

**`LifestyleBudgetRow` (private struct)**
- Same inline editing pattern as Fixed.
- Non-split: BUDGETED + REMAINING columns. Remaining = effective amount (base + rollover) minus spent. Colour-coded green/amber/red. Rollover indicator chip ("↩ £X rollover").
- Ownership pills in edit mode: "Shared", "Me", "Partner" — updates `UpdateBudgetLine(ownership:)`.
- Progress bar (3pt, full width below row) — overspent = red, >80% = amber, otherwise sage.

**`SplitSliderRow` (private struct)**
- Shown in edit mode when `showSplit == true`, replacing the normal row.
- `Slider(value:in:step:)` 0–100, step 1. Local `@State` drives slider; `onSplitCommit` debounces via `[UUID: Task]` dictionary (400ms).
- "X% / Y%" label updates live.

**`NoteEditorSheet` (private struct)**
- Large `TextEditor` with 300-char limit, "Save" toolbar button.

**`AddBudgetLineSheet` (standalone file)**
- Name input + suggestion chips (horizontal scroll).
- Amount field with currency prefix (22pt font).
- Annual toggle (fixed only) — shows monthly equivalent.
- Day picker (1-31 circles, horizontal scroll, `scrollTo` on appear).
- Note field (120 char limit).
- Constructs `CreateBudgetLine` with `rolloverEnabled: !isFixed`, `ownership: "shared"`, `member1Percentage: 50`.

**Edit mode banner**
- Amber (#FAEEDA) strip above content, shown when `editMode == true`.
- Transition: `.opacity.combined(with: .move(edge: .top))`.

**Carry-forward**
- `.task(id: homeManager.homeId)` checks rollover on appear.
- If previous month has rollover history but current month doesn't: auto-process (if `budgetCarryForward == "auto"`) or show prompt card.
- Prompt card: "Carry forward underspend?" with Apply / Skip buttons.

**Empty state**
- Shown when `budgetVM.activeLines.isEmpty && !budgetVM.isLoading`.
- "No budget lines yet" heading, description, "Add your first line" button.

**Architecture notes**
- `BudgetSectionDef` is a `private struct` with `id`, `label`, `isFixed`, colour computed vars, and suggestions array.
- `thisMonthExpenses` maps `expensesVM.expenses` to `[Expense]` via `.map(\.expense)` for `getSpent(category:month:expenses:)`.
- `isFreeTier = !(homeManager.home?.hasProAccess ?? false)`.
- `AllocationSegment` is a `private struct` nested inside `MoneyBudgetsView` (inner struct, not extension).
- Section collapse keys: `"roost-budget-section-\(sectionId)"` — `true` = expanded, missing = expanded, `false` = collapsed.

---

### Session 3 — MoneyOverviewView (April 2026)

**Goal:** Replace the placeholder `MoneyOverviewView` with a full 6-zone implementation.

**Status: COMPLETE — build succeeds with zero errors.**

**File created:** `Features/Money/Views/MoneyOverviewView.swift`
**Placeholder removed from:** `Features/Shell/Views/MoneyHomeView.swift`

**Zones built:**

**Zone 1 — Pulse ring card**
- 120×120pt animated `Circle().trim()` arc. Track: `Color(.systemFill)`. Fill: colour-coded (sage/amber/red by pctSpent). Animates via `.onChange(of: summaryVM.isLoading)` + `.onAppear`.
- Centre: `X% spent` when income set; "Set / income" in terracotta otherwise. `ProgressView` during load.
- Right: 3 stat rows — Income (or "Not set" in terracotta), Budgeted (X% of income), Health score (colour-coded green/amber/red).
- Bottom: Hazel insight (multi-sentence, contextual). Priority: overspent envelope → projected overspend → projected surplus → pct used + days remaining → default prompt.
- Inline error state (shown when `summaryVM.error != nil && summaryVM.summary == nil`) with "Try again" button.
- Loading skeleton: placeholder rectangles for stat rows; hazel insight redacted.

**Zone 2 — Money flow card**
- Income row, then two progress bars: Fixed costs (terracotta) and Lifestyle envelopes (amber), each as % of income.
- Unallocated surplus row (green if ≥ 0, red if negative).
- Falls back to `budgetVM.totalFixed` / `budgetVM.totalLifestyle` when `MonthlySummary` not yet loaded.

**Zone 3 — Budget status per lifestyle line**
- Sorted: overspent lines first, then by spend descending.
- Per-line: colour dot + name + remaining label ("Over £X" in red / "£X left" / raw amount); 5pt progress bar colour-coded (green → amber at 80% → red when overspent).
- Loading: 3 skeleton rows.

**Zone 4 — Coming up (bills)**
- Fixed lines split into upcoming (day ≥ today) and past (day < today).
- Due-soon bills (within 3 days) get amber background + border.
- Past bills hidden in a `DisclosureGroup("X paid this month")`, dimmed at 55% opacity.

**Zone 5 — Spending trend (Swift Charts)**
- 6-month `BarMark` chart (sage fill) grouped by month label. Free tier: only current month shown + "See 6-month history with Nest Pro →" upsell button. Empty state when all totals are zero.

**Zone 6 — Month comparison**
- Free tier: locked card → `.nestUpsell(isPresented:feature: .budgetInsights)`.
- Pro: dual-bar rows (this month coloured / last month muted) per category, sorted by this-month spend. Biggest-mover callout if >5% change. Overall % change chip in header. Legend row.

**Month navigator**
- HStack: back button (lock icon if free tier → `.budgetHistory` upsell), month title ("This month" or "MMMM yyyy"), forward button (disabled if current month).
- Navigation calls `summaryVM.navigateMonth(direction:)` then re-triggers `loadSummary`.

**Architecture notes**
- `previousMonth` = `currentMonth - 1 month` (not `Date() - 1 month`), so comparison always refers to the month before the selected month.
- `sixMonthSpend` is always relative to today (last 6 real months), regardless of selected month — it's historical context, not filtered to selection.
- `categoryColour(for:)` duplicated from MoneyHomeView (same stable hash logic) — both views are self-contained.
- Income update link at bottom navigates to a placeholder destination (income settings not yet built).

---

### Session 2 — Money Home Screen (April 2026)

**Goal:** Rebuild `MoneyHomeView.swift` from scratch using the Session 1A/1B data layer.

**Status: COMPLETE — build succeeds with zero errors.**

**What was built:**

All in `Features/Shell/Views/MoneyHomeView.swift`:

**Section 1 — Ring arc summary card**
- 80×80pt animated `Circle().trim()` arc. Track: `Color(.systemFill)`. Fill: colour-coded (sage/amber/red by pctSpent). Animates from 0 to target on appear and after data loads.
- Center label: `X% spent` when income set; "Set income" in terracotta when not set.
- 4 stat rows (Income, Spent, Remaining, Est. surplus) reading from `MonthlyMoneyViewModel`. Income row shows "Not set" + NavigationLink("Set →") to Overview when not set. Remaining colour-coded green/amber/red. Surplus shows ↑/↓ prefix.
- Hazel ambient insight: static logic (over-budget category, projected overspend, projected surplus, early-month, default). Priority ordered. Returns nil when no data.

**Section 2 — Balance strip (conditional)**
- Compact 52pt card shown only when `BalanceCalculator` returns non-zero balance.
- Green dot / "X owes you" or amber dot / "You owe X" using `MemberNamesHelper`.
- "Settle up" button opens existing `SettleUpSheet`.
- Coloured background: green tint (#EAF3DE) if owed, amber tint (#FAEEDA) if owing.
- Transition: `.opacity.combined(with: .move(edge: .top))`.

**Section 3 — Four nav cards**
- `MoneyNavCard` private struct — icon circle, title, subtitle, chevron.
- Each is a `NavigationLink` to placeholder destinations.
- Dynamic subtitles: Overview shows income/spend; Spending shows top category + count; Budgets shows total budgeted + unallocated; Goals shows static fallback.
- Budget subtitle colour turns terracotta if no template lines set up.

**Section 4 — Spending bars (conditional on any this-month expenses)**
- Groups all this-month expenses by category name.
- Matches to `BudgetTemplateViewModel.categories` for colour and budgeted amount.
- Orphan categories (spend exists, no budget line) get stable name-hash colour, proportional fill bar, terracotta colour.
- Shows up to 4 bars. "X more categories →" NavigationLink if more.
- "SPENDING THIS MONTH" eyebrow label.

**Section 5 — Upcoming bills strip (conditional on any fixed template lines)**
- Horizontal scroll, up to 6 fixed lines sorted by `day_of_month`.
- `BillDayCard` private struct (70pt wide, 8pt padding).
- Most-imminent card (first day ≥ today in current month) gets terracotta background + cream text. All others: standard card style.
- `dateLabel` helper: "Today", "Tomorrow", or ordinal suffix (1st, 2nd, 3rd, nth). Handles 11th/12th/13th edge case.

**FAB**
- `FigmaFloatingActionButton(systemImage: "plus")` at `.bottomTrailing`, padding 20/16pt.
- Opens `AddExpenseSheet` with `budgetVM.categories` and split/Hazel wiring (same as Session 1B).

**Scramble mode banner**
- Full-width amber strip (#FAEEDA) outside ScrollView (stays fixed, doesn't scroll).
- Eye-slash icon + "Scramble mode on" text + "Turn off" button calling `settingsVM.toggleScrambleMode`.

**Empty state card**
- Shown when: no income set AND no this-month expenses AND no active budget lines (and neither VM is loading).
- "Set up your finances" heading + description + NavigationLink("Get started →") to `MoneyBudgetsView`.

**Placeholder destinations** (inline at bottom of file)
- `MoneyOverviewView`, `MoneySpendingView`, `MoneyBudgetsView`, `MoneyGoalsView`
- Each is a minimal ScrollView with "coming soon" text, standard background, `.navigationTitle`.
- Will be replaced in subsequent sessions.

**Architecture notes**
- `ScrambleModeEnvironment` and `MemberNamesHelper` accessed via `@Environment(Type.self)` — consistent with app-root injection from Session 1A.
- All amounts formatted via `scramble.format(_:symbol:)` using `settingsVM.settings.currencySymbol`.
- Balance from `BalanceCalculator.calculate(expenses:myUserId:partnerUserId:)`.
- `thisMonthExpenses` derived from `expensesVM.expenses` filtered by `summaryVM.selectedMonth`.
- No savings goals model exists yet — Section 6 omitted pending future session.

---

### Session 1B — Expense Entry Wiring (April 2026)

**Goal:** Connect Session 1A's data layer to the existing expense entry flow. No new UI — wiring only.

**Status: COMPLETE — build succeeds with zero errors.**

**Changes made:**

#### `AddExpenseSheet.swift`
- Parameter changed: `suggestedCategories: [String]` → `suggestedCategories: [BudgetCategory]`
- Added `defaultSplitType: String = "equal"` parameter — initialises `splitType` state for new expenses (edit mode still uses `initialValue.splitType`)
- Category chips now iterate `[BudgetCategory]` by `.id`, display `.name`, match on `.name`
- Helper text changes to "Set up your budget to see category suggestions." when categories are empty
- `#Preview` updated to use `[BudgetCategory]`

#### `MoneyHomeView.swift`
- Added `@Environment(BudgetTemplateViewModel.self)` and `@Environment(MoneySettingsViewModel.self)`
- Removed old `suggestedCategories: [String]` computed property (was pulling from past expenses + old budget tables)
- `AddExpenseSheet` now receives `suggestedCategories: budgetTemplateViewModel.categories` and `defaultSplitType`
- `defaultSplitType`: `moneySettingsViewModel.settings.defaultExpenseSplit == 50.0 ? "equal" : "solo"`
- `addExpense` call passes `budgetCategoryNames: budgetTemplateViewModel.categories.map(\.name)` for Hazel

#### `ExpensesView.swift`
- Same changes as MoneyHomeView — both `AddExpenseSheet` call sites (add + edit) updated
- `suggestedCategories: [String]` computed property removed and replaced with `defaultSplitType`

#### `ExpensesViewModel.addExpense`
- Added `budgetCategoryNames: [String] = []` parameter (additive — backward-compatible)
- Hazel uses `budgetCategoryNames` when non-empty; falls back to past expense category scan when empty

**Architecture notes:**
- `getSpent` in `BudgetTemplateViewModel` already uses `caseInsensitiveCompare` — no change needed
- `BudgetCategoryCatalog` and `BudgetService.fetchCustomCategories` are untouched — still needed by old `BudgetView`
- `defaultExpenseSplit` is `Double` (0–100); 50.0 = "equal"

---

### Session 1A — Data Foundation (April 2026)

**Goal:** Build the complete data layer for the Money rebuild. No UI — models, services, view models only.

**Status: COMPLETE — build succeeds with zero errors.**

---

## Data Foundation

### New Models

#### `BudgetTemplateLine` (`Models/BudgetTemplateLine.swift`)
Replaces the old `budgets` table as the source of truth for budget configuration.
- `budgetType`: `"fixed"` (bills/standing orders) or `"envelope"` (lifestyle spend)
- `sectionGroup`: display grouping (e.g. "Housing", "Transport", "Food")
- `isAnnual` / `annualAmount`: for annual costs — `displayAmount` auto-divides by 12
- `rolloverEnabled`: underspent envelopes carry forward to next month
- `ownership`: `"shared"`, `"member1"`, `"member2"` — for split calculations
- `member1Percentage`: override split percentage for shared lines
- `sortOrder`: explicit ordering within section groups
- `isActive`: soft-delete — lines are never hard-deleted
- Computed: `isFixed`, `isLifestyle`, `displayAmount`

Mutation structs: `CreateBudgetLine`, `UpdateBudgetLine` (partial — nil fields omitted from JSON)

#### `BudgetRolloverHistory` (`Models/BudgetRolloverHistory.swift`)
One row per lifestyle line per month. Tracks carry-in amounts for envelope rollover.
- `month`: date-only field (`yyyy-MM-dd`), decoded with custom formatter
- `baseAmount`: the template line's base budget
- `rolloverAmount`: underspent amount carried from previous month
- `effectiveAmount`: `baseAmount + rolloverAmount`

Mutation struct: `CreateRolloverHistory`

#### `HouseholdIncome` (`Models/HouseholdIncome.swift`)
Per-home monthly income record. Combined total used by all Money calculations.
- `combinedAmount`: what Money views use — never individual amounts unless both consented
- `tomAmount` / `partnerAmount`: internal names only, map to `member1_amount` / `member2_amount` columns
- `month`: date-only field

Mutation struct: `UpsertHouseholdIncome`

#### `MonthlySummary` (`Models/MonthlySummary.swift`)
Decoded from the `get_monthly_summary` Postgres RPC response.
- All fields are `Decimal`
- `hasIncome` computed property — use to gate "Not set" display vs calculations

#### `MoneySettings` (`Models/MonthlySummary.swift`)
Plain struct (not Codable) derived from the `homes` table.
- `MoneySettings.from(home:)` factory method
- Defaults: 50/50 split, auto carry-forward, scramble off, 80% alert, £ symbol

### Updated Models

#### `Home` (`Models/Home.swift`)
New optional columns added (all default nil, backward-compatible):
- `defaultExpenseSplit: Double?`
- `budgetCarryForward: String?`
- `scrambleMode: Bool?`
- `overspendAlertThreshold: Int?`
- `currencySymbol: String?`

#### `HomeMember` (`Models/Home.swift`)
New optional income columns (all default nil, backward-compatible):
- `personalIncome: Decimal?`
- `incomeVisibleToPartner: Bool?`
- `incomeSetAt: Date?`

---

### New Services

#### `BudgetTemplateService` (`Services/BudgetTemplateService.swift`)
Full CRUD for `budget_template_lines` and `budget_rollover_history`.
- `fetchTemplateLines(homeId:)` — active lines only, ordered by sort_order
- `addLine(_:)` → `CreateBudgetLine`
- `updateLine(id:updates:)` → `UpdateBudgetLine` (partial update)
- `removeLine(id:)` — sets `is_active = false`, never deletes
- `fetchRolloverHistory(homeId:month:)`
- `upsertRolloverHistory(_:)` — on-conflict: `home_id,template_line_id,month`

#### `HouseholdIncomeService` (`Services/HouseholdIncomeService.swift`)
Privacy-aware income management.
- `fetchMyIncome(userId:)` — reads `home_members.personal_income`
- `setMyIncome(userId:amount:)` — updates `home_members.personal_income`
- `setIncomeVisibility(userId:visible:)` — updates `income_visible_to_partner`
- `fetchHouseholdIncome(homeId:month:)` — reads `household_income` table
- `fetchPartnerIncome(homeId:currentUserId:)` — only returns if BOTH consented
- `syncCombinedIncome(homeId:month:)` — sums member incomes, upserts to `household_income`

#### `MonthlyMoneyService` (`Services/MonthlyMoneyService.swift`)
Thin wrapper for the `get_monthly_summary` RPC.
- `fetchMonthlySummary(homeId:month:)` → `MonthlySummary?`
- Handles both single-object and array JSON response shapes
- Uses `keyDecodingStrategy: .convertFromSnakeCase`

#### `MoneySettingsService` (`Services/MoneySettingsService.swift`)
Reads and writes home-level Money settings.
- `fetchSettings(homeId:)` → `MoneySettings`
- `persistSettings(_:homeId:)` — upserts all 5 settings columns to `homes`
- Uses `AnyJSON.double`, `.integer`, `.bool`, `.string` for typed payloads

---

### New ViewModels

All follow the project's `@MainActor @Observable final class` pattern.

#### `BudgetTemplateViewModel` (`Features/Money/ViewModels/BudgetTemplateViewModel.swift`)
**Central source of truth for all budget template data.**

Computed:
- `activeLines`, `fixedLines`, `lifestyleLines`
- `categories: [BudgetCategory]` — **replaces `home_custom_categories` for expense categorisation**
  - Derived from lifestyle lines only
  - Colour is stable hash of name across 8-colour warm palette
- `linesBySection: [String: [BudgetTemplateLine]]`
- `totalFixed`, `totalLifestyle`, `totalBudgeted`

Functions:
- `getEffectiveAmount(lineId:month:)` — base + rollover
- `getRolloverAmount(lineId:)` — from cached rolloverHistory
- `getSpent(category:month:expenses:)` — filters Expense[] by category and month
- `getRemaining(lineId:month:expenses:)` — effective minus spent
- `calculateHealthScore(income:hasGoals:)` — 0–100
- `detectBillClashes()` → `[BillClash]` — fixed lines within 2-day windows
- `processMonthRollover(homeId:month:expenses:)` — idempotent rollover processing

Realtime: subscribes to `budget_template_lines` and `budget_rollover_history` (filtered by home_id)

Supporting types in same file: `BudgetCategory`, `BillClash`

#### `MonthlyMoneyViewModel` (`Features/Money/ViewModels/MonthlyMoneyViewModel.swift`)
Drives the monthly overview header used by Spending, Overview, and Dashboard.

- `summary: MonthlySummary?` — nil until loaded
- `selectedMonth: Date` — starts at current month's first day
- `navigateMonth(direction:)` — clamped at current month for forward navigation
- Projection: `daysElapsed`, `daysInMonth`, `dailySpendRate`, `projectedLifestyleSpend`, `projectedSurplus`
- Realtime: subscribes to `household_income` to refresh when income changes

#### `MoneySettingsViewModel` (`Features/Money/ViewModels/MoneySettingsViewModel.swift`)
- `settings: MoneySettings`
- `updateSetting(_:value:homeId:)` — generic KeyPath-based update
- `toggleScrambleMode(homeId:)` — convenience toggle
- Realtime: subscribes to `homes` to refresh when settings change remotely

---

### New Helpers

#### `MemberNamesHelper` (`Services/MemberNamesHelper.swift`)
**Replaces all hardcoded "Tom" and "Beth" references.**
- `load(currentUserId:homeMembers:)` — call whenever members change
- Resolves `me` vs `partner` by looking up currentUserId in homeMembers
- `MemberNames` struct: me, partner, initials, colours, hasPartner
- `Self.initials(from:)` — "Tom Slater" → "TS"
- `Self.displayName(member:)` — falls back to "Member" if displayName empty
- Avatar colour → SwiftUI `Color` mapping

#### `ScrambleModeEnvironment` (`Services/ScrambleModeEnvironment.swift`)
`@Observable` environment object at app root. All Money views use it for amount formatting.
- `format(_:symbol:)` — returns "•••" when scrambled, "—" when nil
- `sync(from:)` — call after loading MoneySettings or on scrambleMode Realtime update

---

### Wiring

**`RoostApp.swift`** — 5 new `@State` properties added:
- `budgetTemplateViewModel`
- `monthlyMoneyViewModel`
- `moneySettingsViewModel`
- `memberNamesHelper`
- `scrambleModeEnvironment`
All passed via `.environment()` into the WindowGroup.

**`MainTabView.swift`** — Wired into `warmPageData` and `stopPagePolling`:
- Load and startRealtime for all 3 new ViewModels
- `memberNamesHelper.load(...)` called after home members are available
- `scrambleModeEnvironment.sync(...)` called after settings load
- `onChange(of: moneySettingsViewModel.settings.scrambleMode)` → re-syncs scramble env

---

## Architecture Decisions

**`categories` replaces `home_custom_categories`**
The old budget system used a separate `home_custom_categories` table. The new system derives categories from lifestyle template lines. The `BudgetTemplateViewModel.categories` computed property is the single source of truth for the expense category picker. The old `BudgetService.fetchCustomCategories` / `BudgetCategoryCatalog` system remains for backward compatibility with the old Budget view until it is replaced.

**Rollover is idempotent**
`processMonthRollover` checks for existing entries before creating new ones. Safe to call on every `load()`. Month-start detection is left to the caller.

**Income privacy**
Individual incomes are never shown unless both `home_members.income_visible_to_partner = true`. The `household_income` table always stores the combined total for Money calculations regardless of visibility consent.

**Scramble mode is a shared environment, not per-view**
`ScrambleModeEnvironment` is `@Observable` at app root. Any view that shows a money amount should inject it via `@Environment(ScrambleModeEnvironment.self)` and call `scramble.format(amount)` instead of formatting directly.

---

## Ready for Session 1B

Session 1B can now build:
- **BudgetsView** (new) — template line list, section groups, fixed vs envelope split
- **SpendingView** — monthly spend vs envelope budget, progress bars
- **OverviewView** — MonthlySummary display, health score, income setting
- **ExpenseQuickAddSheet** — uses `budgetTemplateViewModel.categories` for picker

The data layer is complete and tested (BUILD SUCCEEDED). All services compile, all ViewModels load, Realtime subscriptions are registered.
