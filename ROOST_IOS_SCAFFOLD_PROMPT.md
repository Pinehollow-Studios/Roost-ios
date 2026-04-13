# Roost iOS App — Full Scaffold Build

You are building the foundation for **Roost**, a native iOS app built in **Swift + SwiftUI**. Roost is a shared household dashboard for couples — exactly two people who share a home. It covers shopping lists, shared expenses with splitting, chores, budgets, a calendar, an activity feed, notifications, and settings. A fully functional Mac (Electron) app already exists and is used daily. The iOS app is a **new native frontend** that connects to the **same Supabase backend**. The database schema, RLS policies, Edge Functions, and Realtime subscriptions are all shared. **Do not modify the Supabase schema or backend in any way.**

This task is to build the **complete project scaffold** — the entire folder structure, every model, every service, every view and view model as stubs, all dependencies installed, the design system wired in, and the architecture locked down. No feature logic yet — but every file exists, every pattern is established, and the app compiles and runs showing a tab bar with placeholder screens. Think of this as building the widest, strongest possible foundation for a pyramid.

---

## Technical Decisions (Non-Negotiable)

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI (no UIKit except where SwiftUI has genuine gaps)
- **Minimum deployment target:** iOS 17.0
- **Architecture:** MVVM — every screen gets a View + ViewModel. ViewModels are `@Observable` classes (iOS 17 Observation framework). Views are thin — display logic only, all business logic in ViewModels.
- **Dependency management:** Swift Package Manager
- **Bundle ID:** `com.roostapp.ios`
- **Product name:** Roost

---

## Dependencies to Install (via SPM)

Add all of these as package dependencies. Pin to stable/recent versions.

### Core
- **supabase-swift** (`github.com/supabase/supabase-swift`) — Supabase client (auth, database, realtime, storage, functions). This is the primary backend SDK.
- **KeychainAccess** (`github.com/kishikawakatsumi/KeychainAccess`) — Secure session/token storage in the iOS Keychain.

### Auth
- **GoogleSignIn-iOS** (`github.com/google/GoogleSignIn-iOS`) — Google OAuth sign-in.
- Sign in with Apple uses the native `AuthenticationServices` framework (no external dependency).

### Networking & Data
- **SwiftData** — Apple's native persistence framework (built into iOS 17, no SPM needed). Used for local offline caching.

### UI & Design
- **Nuke** (`github.com/kean/Nuke`) — High-performance async image loading and caching (for any future avatar images or assets).
- **SwiftUI-Introspect** (`github.com/siteline/swiftui-introspect`) — Access underlying UIKit views for fine-tuning when SwiftUI falls short.
- **lucide-swift** — For avatar icons. If no maintained Swift port exists, include a `LucideIcon` enum in the design system that maps the 25 avatar icon names used by Roost to SF Symbols equivalents, with a comment noting each original Lucide name.

### Animation
- Use SwiftUI's native `.animation()`, `withAnimation()`, `.transition()`, `.matchedGeometryEffect`, and `PhaseAnimator` (iOS 17). No external animation libraries needed — SwiftUI's built-in system is powerful enough.

### Notifications
- **Firebase Cloud Messaging** (`github.com/firebase/firebase-ios-sdk`, only the `FirebaseMessaging` product) — For remote push notifications via APNs. This is the standard approach for apps with a custom backend. Local notifications use the native `UserNotifications` framework.

### Utilities
- **SwiftDate** (`github.com/malcommac/SwiftDate`) — Date manipulation and formatting (equivalent to `date-fns` on the Mac app). Handles relative timestamps ("2 hours ago"), recurrence calculations, and locale-aware formatting.

### Testing
- XCTest (built-in) — set up both a unit test target (`RoostTests`) and a UI test target (`RoostUITests`) with empty placeholder test files.

---

## Project Structure

Create this exact folder structure. Every file listed should exist. Files marked `(stub)` should contain the minimum compilable code — the struct/class definition, required protocol conformances, and TODO comments explaining what the file will do. **No feature logic yet.**

```
Roost/
├── Roost.xcodeproj
├── Roost/
│   ├── RoostApp.swift                          # App entry point, scene setup, environment injection
│   ├── ContentView.swift                       # Root view — auth gate (show auth flow or main tab bar)
│   │
│   ├── Config/
│   │   ├── Secrets.xcconfig                    # SUPABASE_URL, SUPABASE_ANON_KEY (gitignored)
│   │   ├── Config.swift                        # Reads values from xcconfig at build time
│   │   └── AppConstants.swift                  # Static constants — deep link schemes, default values, feature flags
│   │
│   ├── Design/
│   │   ├── Theme.swift                         # RoostTheme: all color tokens (light + dark), spacing, radius, typography
│   │   ├── Colors.swift                        # Color extension with all Roost semantic colors as static properties
│   │   ├── Typography.swift                    # Font extension for DM Sans — .roostHeading, .roostBody, .roostLabel, .roostCaption
│   │   ├── Spacing.swift                       # Spacing constants — .xs, .sm, .md, .lg, .xl, .xxl
│   │   ├── Animation+Roost.swift               # Animation presets — .roostSmooth, .roostSnappy, .roostEaseOut, .roostSpring
│   │   ├── IconMap.swift                       # Maps Lucide icon names (used in avatar_icon DB field) to SF Symbol names
│   │   └── Assets.xcassets/
│   │       ├── Colors/                         # Color assets for light/dark mode adaptive colors
│   │       ├── Fonts/                          # DM Sans .ttf files (Regular 400 + Medium 500)
│   │       └── AppIcon.appiconset/             # Placeholder app icon at all required sizes
│   │
│   ├── Models/
│   │   ├── Home.swift                          # Home, HomeMember — Codable, matches Supabase schema exactly
│   │   ├── ShoppingItem.swift                  # ShoppingItem, CreateShoppingItem
│   │   ├── Expense.swift                       # Expense, ExpenseSplit, ExpenseWithSplits, CreateExpense, Settlement
│   │   ├── Chore.swift                         # Chore, CreateChore
│   │   ├── Budget.swift                        # Budget, UpsertBudget, CustomCategory, CreateCustomCategory
│   │   ├── ActivityFeedItem.swift              # ActivityFeedItem
│   │   ├── AppNotification.swift               # AppNotification (named to avoid clash with system Notification)
│   │   ├── NotificationPreferences.swift       # NotificationPrefs with defaults
│   │   ├── UserPreferences.swift               # UserPreferences with UK defaults
│   │   ├── Room.swift                          # Room, CreateRoom, RoomGroup, CreateRoomGroup
│   │   └── CalendarEvent.swift                 # CalendarEvent (derived, not a DB table)
│   │
│   ├── LocalData/
│   │   ├── SwiftDataModels.swift               # SwiftData @Model versions of core types for offline cache
│   │   ├── LocalDataManager.swift              # ModelContainer setup + CRUD helpers for SwiftData
│   │   └── SyncEngine.swift                    # (stub) Orchestrates Supabase fetch → local cache update
│   │
│   ├── Services/
│   │   ├── SupabaseClient.swift                # Singleton Supabase client init with Keychain auth storage, PKCE flow
│   │   ├── AuthService.swift                   # Email signup/login, Google OAuth, Apple sign-in, session management, signout, delete account
│   │   ├── HomeService.swift                   # create_home_for_user RPC, join_home_by_invite_code RPC, get_user_home_id RPC, leave_home RPC, update home
│   │   ├── ShoppingService.swift               # CRUD for shopping_items table
│   │   ├── ExpenseService.swift                # CRUD for expenses + expense_splits, settle_up RPC
│   │   ├── ChoreService.swift                  # CRUD for chores table
│   │   ├── BudgetService.swift                 # CRUD for budgets + home_custom_categories
│   │   ├── ActivityService.swift               # Fetch activity_feed, logActivity() helper
│   │   ├── NotificationService.swift           # Fetch/update notifications, fetch/upsert notification_preferences
│   │   ├── UserPreferencesService.swift        # Fetch/upsert user_preferences
│   │   ├── RoomService.swift                   # CRUD for home_rooms + home_room_groups + room_group_members
│   │   ├── CalendarService.swift               # (stub) Client-side aggregation of chores + expenses into CalendarEvent[]
│   │   └── RealtimeManager.swift               # Centralised realtime subscription manager with ref-counting (port of Mac app pattern)
│   │
│   ├── Notifications/
│   │   ├── PushNotificationManager.swift       # APNs registration, FCM token management, permission requests
│   │   ├── LocalNotificationManager.swift      # UNUserNotificationCenter wrapper for local notifications
│   │   └── NotificationRouter.swift            # (stub) Routes notification taps to the correct screen/tab
│   │
│   ├── Features/
│   │   ├── Auth/
│   │   │   ├── Views/
│   │   │   │   ├── WelcomeView.swift           # Landing screen — app logo, sign in buttons, sign up link
│   │   │   │   ├── LoginView.swift             # Email + password login form
│   │   │   │   ├── SignupView.swift            # Email + password + display name signup form
│   │   │   │   ├── JoinView.swift              # Signup with invite code (partner joining)
│   │   │   │   └── SetupView.swift             # Post-auth setup — display name + create/join home
│   │   │   └── ViewModels/
│   │   │       ├── WelcomeViewModel.swift
│   │   │       ├── LoginViewModel.swift
│   │   │       ├── SignupViewModel.swift
│   │   │       ├── JoinViewModel.swift
│   │   │       └── SetupViewModel.swift
│   │   │
│   │   ├── Dashboard/
│   │   │   ├── Views/
│   │   │   │   ├── DashboardView.swift         # Summary cards grid — shopping, expenses, chores, budget, activity, next shop date
│   │   │   │   └── DashboardCardView.swift     # Reusable summary card component
│   │   │   └── ViewModels/
│   │   │       └── DashboardViewModel.swift
│   │   │
│   │   ├── Shopping/
│   │   │   ├── Views/
│   │   │   │   ├── ShoppingListView.swift      # Main shopping list with category grouping
│   │   │   │   ├── ShoppingItemRow.swift       # Single item row — checkbox, name, quantity, swipe to delete
│   │   │   │   └── AddShoppingItemSheet.swift  # Bottom sheet for adding new item
│   │   │   └── ViewModels/
│   │   │       └── ShoppingViewModel.swift
│   │   │
│   │   ├── Expenses/
│   │   │   ├── Views/
│   │   │   │   ├── ExpensesView.swift          # Expense list + balance header
│   │   │   │   ├── ExpenseRow.swift            # Single expense row
│   │   │   │   ├── AddExpenseSheet.swift       # Form for logging a new expense
│   │   │   │   ├── BalanceCardView.swift       # Who owes whom + settle up button
│   │   │   │   └── SettleUpSheet.swift         # Multi-step settle up flow
│   │   │   └── ViewModels/
│   │   │       └── ExpensesViewModel.swift
│   │   │
│   │   ├── Chores/
│   │   │   ├── Views/
│   │   │   │   ├── ChoresView.swift            # Chore list with overdue sorting
│   │   │   │   ├── ChoreRow.swift              # Single chore — title, assignee, due date, complete button
│   │   │   │   └── AddChoreSheet.swift         # Form for adding a new chore
│   │   │   └── ViewModels/
│   │   │       └── ChoresViewModel.swift
│   │   │
│   │   ├── Budget/
│   │   │   ├── Views/
│   │   │   │   ├── BudgetView.swift            # Monthly budget overview — category bars, totals
│   │   │   │   ├── BudgetCategoryRow.swift     # Single category — spend vs limit progress bar
│   │   │   │   └── SetBudgetSheet.swift        # Form for setting/editing a category budget
│   │   │   └── ViewModels/
│   │   │       └── BudgetViewModel.swift
│   │   │
│   │   ├── Calendar/
│   │   │   ├── Views/
│   │   │   │   ├── CalendarView.swift          # Month grid + event dots + upcoming list below
│   │   │   │   └── CalendarDayCell.swift       # Single day cell with event dot indicators
│   │   │   └── ViewModels/
│   │   │       └── CalendarViewModel.swift
│   │   │
│   │   ├── Activity/
│   │   │   ├── Views/
│   │   │   │   ├── ActivityFeedView.swift      # Chronological list of household events
│   │   │   │   └── ActivityRow.swift           # Single activity — avatar + action + timestamp
│   │   │   └── ViewModels/
│   │   │       └── ActivityViewModel.swift
│   │   │
│   │   ├── Notifications/
│   │   │   ├── Views/
│   │   │   │   ├── NotificationsView.swift     # Notification list with unread indicators
│   │   │   │   └── NotificationRow.swift       # Single notification row
│   │   │   └── ViewModels/
│   │   │       └── NotificationsViewModel.swift
│   │   │
│   │   └── Settings/
│   │       ├── Views/
│   │       │   ├── SettingsView.swift          # Settings hub — links to sub-pages
│   │       │   ├── ProfileSettingsView.swift   # Display name, avatar colour + icon picker
│   │       │   ├── HouseholdSettingsView.swift # Home name, invite code, member list
│   │       │   ├── NotificationSettingsView.swift  # Per-type toggles, quiet hours
│   │       │   ├── PreferencesSettingsView.swift   # Week start, time format, currency, date format
│   │       │   └── AccountSettingsView.swift   # Change email, change password, leave home, delete account
│   │       └── ViewModels/
│   │           └── SettingsViewModel.swift
│   │
│   ├── Components/
│   │   ├── RoostButton.swift                   # Styled button with variants: primary, secondary, outline, ghost, destructive
│   │   ├── RoostCard.swift                     # Warm card container with border and padding
│   │   ├── RoostTextField.swift                # Styled text input with warm background and focus ring
│   │   ├── RoostSheet.swift                    # Bottom sheet wrapper with consistent styling
│   │   ├── MemberAvatar.swift                  # Colored circle with icon or initial — sizes xs to xl
│   │   ├── EmptyStateView.swift                # Icon + heading + body + optional CTA
│   │   ├── LoadingSkeletonView.swift           # Animated shimmer placeholder
│   │   ├── OfflineBanner.swift                 # Slim warning banner when network is unavailable
│   │   ├── ProgressBarView.swift               # Budget/spend progress bar with colour thresholds
│   │   ├── DatePickerField.swift               # Tappable field that opens a styled date picker
│   │   ├── SegmentControl.swift                # Animated pill segment control (for settings toggles)
│   │   └── RelativeTimestamp.swift             # "2 hours ago" / "yesterday" text component
│   │
│   ├── Navigation/
│   │   ├── MainTabView.swift                   # Tab bar: Dashboard, Shopping, Expenses, Chores, More
│   │   ├── MoreMenuView.swift                  # "More" tab — links to Calendar, Activity, Budget, Settings
│   │   └── DeepLinkHandler.swift               # Handles roost-ios:// deep links (invite codes, notification taps)
│   │
│   ├── Utilities/
│   │   ├── NetworkMonitor.swift                # NWPathMonitor wrapper — publishes online/offline state
│   │   ├── HapticManager.swift                 # Centralised haptic feedback (success, error, selection)
│   │   ├── ErrorHandler.swift                  # Maps Supabase/network errors to user-friendly messages
│   │   ├── DateFormatting.swift                # Helpers respecting user's date_format and time_format preferences
│   │   ├── CurrencyFormatting.swift            # Formats amounts using user's currency preference
│   │   └── Logger.swift                        # Lightweight logging with subsystem categories
│   │
│   ├── Extensions/
│   │   ├── View+Extensions.swift               # Common view modifiers — .roostCard(), .roostSheet(), .shimmer()
│   │   ├── Color+Roost.swift                   # Convenience accessors for theme colors
│   │   └── Date+Extensions.swift               # date-fns equivalents — addWeeks, addMonths, startOfMonth, isOverdue, etc.
│   │
│   ├── Info.plist                              # Custom fonts declaration, URL schemes, background modes
│   └── Roost.entitlements                      # Push notifications, Keychain sharing, Sign in with Apple
│
├── RoostTests/
│   ├── RoostTests.swift                        # Placeholder unit test file
│   ├── ServiceTests/                           # Folder for future service layer tests
│   └── ViewModelTests/                         # Folder for future ViewModel tests
│
├── RoostUITests/
│   └── RoostUITests.swift                      # Placeholder UI test file
│
├── Secrets.xcconfig.example                    # Template showing required keys (committed to git)
├── .gitignore                                  # Includes Secrets.xcconfig, .DS_Store, xcuserdata, etc.
└── README.md                                   # Setup instructions for the project
```

---

## Design System Implementation

The attached **DESIGN_ETHOS.md** document is the authoritative design reference. Implement the design system in `Design/` files as follows:

### Colors (Colors.swift)

Define all colors as SwiftUI `Color` extensions with light/dark adaptive variants using Color Assets or programmatic `UIColor` with trait collections.

**Light mode:**
- `Color.roostBackground` → `#ebe3d5` (warm cream — never pure white)
- `Color.roostForeground` → `#3d3229` (warm dark brown — never black)
- `Color.roostCard` → `#f2ebe0` (creamy off-white)
- `Color.roostPrimary` → `#d4795e` (terracotta — CTAs, active states)
- `Color.roostPrimaryForeground` → `#f2ebe0` (text on primary)
- `Color.roostSecondary` → `#9db19f` (sage green)
- `Color.roostSecondaryForeground` → `#3d3229`
- `Color.roostMuted` → `#ddd4c6` (subtle backgrounds)
- `Color.roostMutedForeground` → `#6b6157` (secondary text)
- `Color.roostAccent` → `#e8d5bc` (hover/highlight)
- `Color.roostDestructive` → `#c75146` (muted red)
- `Color.roostDestructiveForeground` → `#f2ebe0`
- `Color.roostSuccess` → `#7fa087` (forest green)
- `Color.roostWarning` → `#e6a563` (warm amber)
- `Color.roostInfo` → `#9db19f` (sage)
- `Color.roostBorder` → `rgba(61, 50, 41, 0.15)`
- `Color.roostInputBackground` → `#e3d9ca`
- `Color.roostRing` → `rgba(212, 121, 94, 0.3)` (terracotta focus ring)

**Dark mode:**
- `Color.roostBackground` → `#0f0d0b` (near-black with warmth)
- `Color.roostForeground` → `#f2ebe0` (cream text)
- `Color.roostCard` → `#1a1816`
- `Color.roostPrimary` → `#d4795e` (terracotta unchanged)
- `Color.roostSecondary` → `#7a8c7c` (muted sage)
- `Color.roostMuted` → `#2a2623`
- `Color.roostMutedForeground` → `#a39a8f`
- `Color.roostBorder` → `rgba(242, 235, 224, 0.1)`
- `Color.roostInputBackground` → `#1f1c19`

**Chart colors** (same both modes): `[#d4795e, #9db19f, #e6a563, #b88b7e, #7fa087]`

### Typography (Typography.swift)

Bundle **DM Sans** (Regular 400 + Medium 500) as custom fonts.

Register in Info.plist under `UIAppFonts` / `Fonts provided by application`.

Define as `Font` extensions:
- `.roostTitle` → DM Sans Medium, 24pt (page titles)
- `.roostHeading` → DM Sans Medium, 20pt (section headings)
- `.roostCardTitle` → DM Sans Medium, 18pt (card titles)
- `.roostBody` → DM Sans Regular, 16pt (body text)
- `.roostLabel` → DM Sans Medium, 16pt (labels, buttons)
- `.roostCaption` → DM Sans Regular, 14pt (timestamps, helper text)

Line height: 1.5x throughout. **Never use bold weight** — medium (500) is the heaviest. Boldness feels aggressive against the warm palette.

### Spacing (Spacing.swift)

```swift
enum RoostSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}
```

### Border Radius

```swift
enum RoostRadius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 12
    static let lg: CGFloat = 14      // Base — cards, major containers
    static let xl: CGFloat = 18      // Prominent elements
    static let full: CGFloat = 999   // Pill shape
}
```

### Animations (Animation+Roost.swift)

Define reusable animation presets:
- `.roostSmooth` → `Animation.timingCurve(0.43, 0.13, 0.23, 0.96, duration: 0.4)` (page transitions)
- `.roostSnappy` → `Animation.timingCurve(0.34, 1.56, 0.64, 1, duration: 0.2)` (spring interactions)
- `.roostEaseOut` → `Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.25)` (opening elements)
- `.roostSpring` → `Animation.spring(response: 0.35, dampingFraction: 0.7)` (buttons, interactive elements)

Define reusable transition presets for:
- Page entrance: fade + slide up 8pt
- Sheet presentation: fade + scale from 0.95 + slide up 20pt
- List item entrance: fade + slide down 10pt + scale from 0.95
- List item exit: fade + scale to 0.9 + slide left 20pt

### Icon Mapping (IconMap.swift)

The Mac app uses 25 Lucide icons for user avatars (stored as strings in the `avatar_icon` DB column). Create a mapping enum:

```swift
enum RoostIcon: String, CaseIterable {
    case user, heart, home, star, sun, moon, cloud, flower, leaf, tree
    case cat, dog, bird, fish, bug, coffee, music, book, palette, camera
    case rocket, anchor, compass, crown, diamond

    var sfSymbol: String {
        switch self {
        // Map each to the closest SF Symbol equivalent
        }
    }
}
```

For all other UI icons, use SF Symbols directly.

---

## Supabase Client Configuration

### SupabaseClient.swift

```swift
import Supabase
import KeychainAccess

// CRITICAL: Use PKCE flow on iOS (not implicit — that's the Mac app's Electron workaround)
// Session storage goes to Keychain, NOT UserDefaults

let supabase = SupabaseClient(
    supabaseURL: URL(string: Config.supabaseURL)!,
    supabaseKey: Config.supabaseAnonKey,
    options: .init(
        auth: .init(
            storage: KeychainAuthStorage(),  // Custom storage adapter using KeychainAccess
            flowType: .pkce                  // PKCE — required for iOS OAuth redirects
        )
    )
)
```

Create a `KeychainAuthStorage` struct that conforms to Supabase's `AuthLocalStorage` protocol, storing/retrieving the session JSON from the Keychain.

### Config.swift

Reads from the build configuration (xcconfig):
```swift
enum Config {
    static let supabaseURL: String = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String ?? ""
    static let supabaseAnonKey: String = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String ?? ""
}
```

### Secrets.xcconfig (gitignored)

```
SUPABASE_URL = https://your-project.supabase.co
SUPABASE_ANON_KEY = your-anon-key-here
```

### Secrets.xcconfig.example (committed)

```
// Copy this file to Secrets.xcconfig and fill in your values.
// Secrets.xcconfig is gitignored — never commit real keys.
SUPABASE_URL = https://your-project.supabase.co
SUPABASE_ANON_KEY = your-anon-key-here
```

---

## Models — Codable Structs

Every model must match the Supabase schema exactly. Use `Codable` with `CodingKeys` mapping `snake_case` DB columns to `camelCase` Swift properties.

Key conventions:
- UUIDs are `String` (Supabase returns UUIDs as strings in JSON)
- Timestamps are `String` in ISO 8601 format (parse to `Date` only when displaying)
- Optional nullable DB columns are `String?` / `Double?` / `Bool?`
- Server-generated fields (`id`, `created_at`, `home_id`) are omitted from "Create" structs
- Each file has both the full model and the create/input variant

Example pattern:

```swift
struct ShoppingItem: Codable, Identifiable {
    let id: String
    let homeId: String
    let name: String
    let quantity: String?
    let category: String?
    let checked: Bool
    let addedBy: String?
    let checkedBy: String?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, quantity, category, checked
        case homeId = "home_id"
        case addedBy = "added_by"
        case checkedBy = "checked_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct CreateShoppingItem: Codable {
    let name: String
    let quantity: String?
    let category: String?
}
```

Follow this exact pattern for every model. Reference the Supabase schema in the attached ROOST_MOBILE_CONTEXT.md for the complete column definitions of every table.

---

## Service Layer Pattern

Every service is a class with `static` methods (or a singleton) that wraps Supabase calls. Services handle:
1. The Supabase query
2. Decoding the response into Codable models
3. Throwing typed errors on failure

Services do NOT handle UI state — that's the ViewModel's job.

Example pattern:

```swift
final class ShoppingService {

    static func fetchItems(homeId: String) async throws -> [ShoppingItem] {
        let response: [ShoppingItem] = try await supabase
            .from("shopping_items")
            .select()
            .eq("home_id", value: homeId)
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }

    static func addItem(homeId: String, item: CreateShoppingItem, userId: String) async throws -> ShoppingItem {
        // TODO: Insert into shopping_items, return the created item
        fatalError("Not implemented")
    }

    static func toggleItem(id: String, checked: Bool, userId: String?) async throws {
        // TODO: Update checked + checked_by
        fatalError("Not implemented")
    }

    static func deleteItem(id: String) async throws {
        // TODO: Delete from shopping_items
        fatalError("Not implemented")
    }
}
```

### RealtimeManager.swift

This is critical infrastructure. Port the Mac app's pattern:

1. **Stable channel key:** Each subscription is keyed by `"table:event:filter"`. Two subscribers with the same config share one channel.
2. **Ref-counting:** Track subscriber count per channel. Only tear down the channel when the last subscriber unsubscribes.
3. **Fan-out:** One Supabase Realtime channel fans events to all registered callbacks for that key.
4. **Error recovery:** When `NetworkMonitor` reports connectivity restored, resubscribe all broken channels.
5. **Clean API:**

```swift
final class RealtimeManager {
    static let shared = RealtimeManager()

    func subscribe(
        table: String,
        event: RealtimeEvent = .all,
        filter: String? = nil,
        onEvent: @escaping (Any) -> Void
    ) -> RealtimeSubscription  // RealtimeSubscription has an .unsubscribe() method

    func resubscribeAll()
    func channelStatus() -> [String: ChannelStatus]
}
```

ViewModels call `RealtimeManager.shared.subscribe(...)` in their init and `.unsubscribe()` in deinit.

---

## ViewModel Pattern

Every ViewModel is an `@Observable` class (iOS 17). Published properties drive the View. All async work happens in the ViewModel.

```swift
@Observable
final class ShoppingViewModel {
    // MARK: - Published State
    var items: [ShoppingItem] = []
    var isLoading = false
    var isAdding = false
    var error: String?

    // MARK: - Dependencies
    private let homeId: String
    private var realtimeSubscription: RealtimeSubscription?

    // MARK: - Init
    init(homeId: String) {
        self.homeId = homeId
        subscribeToRealtime()
    }

    deinit {
        realtimeSubscription?.unsubscribe()
    }

    // MARK: - Data Loading
    func loadItems() async {
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await ShoppingService.fetchItems(homeId: homeId)
        } catch {
            self.error = ErrorHandler.message(for: error)
        }
    }

    // MARK: - Mutations (with optimistic updates)
    func toggleItem(_ item: ShoppingItem) async {
        // 1. Optimistic update — flip checked in local array immediately
        // 2. Call ShoppingService.toggleItem()
        // 3. On error — rollback the local change
        // 4. On success — call ActivityService.logActivity()
    }

    // MARK: - Realtime
    private func subscribeToRealtime() {
        realtimeSubscription = RealtimeManager.shared.subscribe(
            table: "shopping_items",
            event: .all
        ) { [weak self] _ in
            Task { await self?.loadItems() }
        }
    }
}
```

**Critical pattern from the Mac app:** Realtime callbacks do NOT use the payload directly. They simply trigger a full re-fetch. This is intentional — it keeps the data pipeline simple and ensures Codable validation always runs on fresh data from the server.

---

## Auth Flow

### AuthService.swift

Must support three sign-in methods:

1. **Email + Password:**
   - `signUp(email:password:displayName:)` → `supabase.auth.signUp()`
   - `signIn(email:password:)` → `supabase.auth.signIn()`

2. **Google OAuth:**
   - `signInWithGoogle()` → `supabase.auth.signInWithOAuth(provider: .google, redirectTo: "com.roostapp.ios://auth/callback")`
   - Handle the redirect URL via a URL scheme or universal link

3. **Sign in with Apple:**
   - Use `ASAuthorizationAppleIDProvider` from `AuthenticationServices`
   - Pass the identity token to `supabase.auth.signInWithIdToken(provider: .apple, idToken:)`

### Auth State Management

Create an `AuthManager` that is injected into the SwiftUI environment:

```swift
@Observable
final class AuthManager {
    var currentUser: User?       // Supabase auth user
    var currentSession: Session?
    var isAuthenticated: Bool { currentSession != nil }
    var hasHome: Bool?           // nil = still checking, false = needs setup, true = ready

    func startSessionListener() {
        // Listen to supabase.auth.onAuthStateChange
        // On SIGNED_IN: set session, check for home via get_user_home_id RPC
        // On SIGNED_OUT: clear everything, navigate to welcome
    }
}
```

### Post-Auth Flow

After any successful sign-in (email, Google, or Apple):
1. Check if user has a home: `supabase.rpc("get_user_home_id")` → returns UUID or null
2. If null → navigate to `SetupView` (create home or join via invite code)
3. If UUID → navigate to `MainTabView`

---

## Navigation

### MainTabView.swift

```swift
TabView {
    DashboardView()
        .tabItem { Label("Home", systemImage: "house.fill") }

    ShoppingListView()
        .tabItem { Label("Shopping", systemImage: "cart.fill") }

    ExpensesView()
        .tabItem { Label("Expenses", systemImage: "sterlingsign.circle.fill") }

    ChoresView()
        .tabItem { Label("Chores", systemImage: "checkmark.circle.fill") }

    MoreMenuView()
        .tabItem { Label("More", systemImage: "ellipsis.circle.fill") }
}
```

The "More" tab provides access to: Calendar, Activity Feed, Budget, Notifications, and Settings.

### Deep Links

Handle the `roost-ios://` URL scheme for:
- `roost-ios://join?code=abc123ef` → open join flow with invite code pre-filled
- `roost-ios://auth/callback` → OAuth redirect handling
- Notification taps → route to the relevant feature screen

---

## SwiftData (Local Cache)

Set up SwiftData with `@Model` versions of the most-used types for offline caching. The sync pattern is:

1. On launch / on view appear: load from SwiftData immediately (instant UI)
2. Fetch from Supabase in the background
3. Merge Supabase response into SwiftData (upsert by ID)
4. UI updates automatically via SwiftData observation

Start with local cache models for: `ShoppingItem`, `Expense`, `Chore`, `ActivityFeedItem`. Other types can be added later.

The `SyncEngine` stub should document this pattern clearly even if the implementation comes later.

---

## Network Monitor

```swift
@Observable
final class NetworkMonitor {
    var isConnected = true

    init() {
        // Use NWPathMonitor to track connectivity
        // When connection restores: call RealtimeManager.shared.resubscribeAll()
    }
}
```

Inject into environment. `OfflineBanner` reads from it.

---

## Activity Feed Pattern

Every mutation that changes household data must call `ActivityService.logActivity()` after success. This is fire-and-forget — never block the UI waiting for it. The `activity_feed` INSERT triggers the DB `on_activity_inserted` function which automatically creates notification rows for the partner.

```swift
static func logActivity(
    homeId: String,
    userId: String,
    action: String,        // e.g. "added milk to the shopping list"
    entityType: String,    // e.g. "shopping_item"
    entityId: String? = nil
) async {
    // Fire and forget — don't throw, just log errors
    do {
        try await supabase.from("activity_feed").insert(...)
    } catch {
        Logger.log("Activity log failed: \(error)", category: .activity)
    }
}
```

---

## Info.plist Configuration

Ensure Info.plist includes:
- `UIAppFonts` → `["DMSans-Regular.ttf", "DMSans-Medium.ttf"]`
- `CFBundleURLTypes` → URL scheme `roost-ios` for deep links and OAuth callbacks
- `UIBackgroundModes` → `["remote-notification"]`
- `SUPABASE_URL` → `$(SUPABASE_URL)` (from xcconfig)
- `SUPABASE_ANON_KEY` → `$(SUPABASE_ANON_KEY)` (from xcconfig)

---

## .gitignore

```
# Xcode
xcuserdata/
*.xcworkspace
DerivedData/
build/

# Secrets
Secrets.xcconfig

# macOS
.DS_Store

# Swift Package Manager
.build/
.swiftpm/

# CocoaPods (not used, but just in case)
Pods/
```

---

## README.md

Include setup instructions:
1. Clone the repo
2. Copy `Secrets.xcconfig.example` to `Secrets.xcconfig` and fill in Supabase credentials
3. Open `Roost.xcodeproj` in Xcode
4. Select your development team for signing
5. Build and run on a simulator or device (iOS 17+)

---

## What "Done" Looks Like

When this scaffold task is complete:

1. ✅ The Xcode project opens without errors
2. ✅ All SPM dependencies resolve and build
3. ✅ The app compiles and launches on an iOS 17 simulator
4. ✅ The app shows the warm cream background with the tab bar navigation
5. ✅ Every tab shows a placeholder view with the correct title
6. ✅ The design system is implemented — colors, typography, spacing, animations all defined
7. ✅ DM Sans font is bundled and rendering
8. ✅ Light and dark mode both work with the correct Roost palette
9. ✅ Every model file exists with complete Codable structs matching the Supabase schema
10. ✅ Every service file exists with method signatures (can use `fatalError("Not implemented")` for bodies)
11. ✅ Every ViewModel exists as an `@Observable` class with the correct published properties
12. ✅ Every View exists as a stub showing at minimum the screen title
13. ✅ The RealtimeManager skeleton is in place with the ref-counting pattern documented
14. ✅ SwiftData models exist for the core types
15. ✅ The Supabase client is configured with Keychain storage and PKCE flow
16. ✅ Auth flow structure is in place (WelcomeView → Login/Signup/Join → Setup → MainTabView)
17. ✅ Deep link URL scheme is registered
18. ✅ Network monitor is set up
19. ✅ Test targets exist (empty but compilable)
20. ✅ `.gitignore` and `Secrets.xcconfig.example` are in place

**Do not implement any feature logic.** The goal is a project where every architectural decision is made, every file exists in the right place, and a developer can pick up any feature and start building immediately because the patterns are clear and the infrastructure is solid.
