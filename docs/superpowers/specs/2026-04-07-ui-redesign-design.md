# MyRWA UI Redesign — Design Spec

**Date:** 2026-04-07
**Style:** Warm & Friendly
**Scope:** Redesign key screens (Home, Auth, Complaints, Notices, Visitors) + design system extraction + navigation restructure

---

## 1. Design System

### 1.1 Color Palette

All colors centralized in `lib/utils/app_colors.dart`. No hardcoded colors anywhere in screens.

**Primary gradient:** Amber `#F59E0B` → Orange `#EA580C`

**Backgrounds:**
- Scaffold: `#FFFDF7` (warm white)
- Surface: `#FFFBEB` (cream)
- Card: `#FFFFFF` with border `#E7E5E4`

**Category pastels (background / border pairs):**
- Amber: `#FEF3C7` / `#FDE68A`
- Green: `#ECFDF5` / `#A7F3D0`
- Blue: `#EFF6FF` / `#BFDBFE`
- Pink: `#FDF2F8` / `#FBCFE8`
- Purple: `#F5F3FF` / `#DDD6FE`

**Text (Stone scale):**
- Primary: `#292524` (stone-900)
- Secondary: `#78716C` (stone-500)
- Tertiary: `#A8A29E` (stone-400)
- On-primary (on amber/orange): `#451A03` (amber-950)

**Status colors:**
- Error/High/Open: `#DC2626` (red-600)
- Warning/Medium/InProgress: `#F59E0B` (amber-500)
- Success/Low/Resolved: `#22C55E` (green-500)

**Dark theme:** Invert backgrounds to stone-900/950, keep pastels at reduced opacity, text becomes stone-100/300/400. Primary amber stays.

### 1.2 Typography

Use `theme.textTheme` exclusively. No hardcoded font sizes.

| Usage | Theme token | Weight | Size (default) |
|-------|------------|--------|----------------|
| Page title | `titleLarge` | 700 | 22 |
| Section heading | `titleMedium` | 700 | 16 |
| Card title | `titleSmall` | 600 | 14 |
| Body text | `bodyMedium` | 400 | 14 |
| Caption/subtitle | `bodySmall` | 400 | 12 |
| Label/chip | `labelSmall` | 600 | 11 |
| Badge | `labelSmall` | 700 | 9 |

### 1.3 Spacing

8px grid: 4, 8, 12, 16, 20, 24, 32. Define as constants in `AppSpacing`.

### 1.4 Border Radius

- Cards: 14px
- Modals/Bottom sheets: 20px (top only)
- Chips/badges: 10px
- Icon containers: 8-12px
- Avatars: 50% (circular)
- Buttons: 14px

### 1.5 Shadows

- Card: `BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: Offset(0, 1))`
- Elevated card: `BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: Offset(0, 2))`
- FAB: `BoxShadow(color: primaryAmber.withOpacity(0.4), blurRadius: 12, offset: Offset(0, 4))`

---

## 2. Shared Components

Create `lib/widgets/` with these reusable widgets:

### 2.1 `warm_card.dart`
Standard card with white background, stone border, subtle shadow. Props: child, onTap, pastelColor (optional — tints the left border or background).

### 2.2 `status_chip.dart`
Colored dot (6px) + label text. Props: status enum, size.

### 2.3 `priority_badge.dart`
Rounded badge with pastel background + bold text. Props: priority enum. Renders "HIGH", "MED", "LOW" with matching colors.

### 2.4 `filter_chip_bar.dart`
Horizontal scrollable row of filter chips. Active chip = amber filled, inactive = pastel outlined. Props: options list, selected index, onChanged.

### 2.5 `empty_state.dart`
Centered column: emoji/illustration (large) + title + subtitle. Props: emoji, title, subtitle.

### 2.6 `shimmer_loader.dart`
Animated shimmer placeholder matching card layout. Props: itemCount, cardHeight.

### 2.7 `action_tile.dart`
"Needs attention" card: icon in pastel box + title + subtitle + action buttons (approve/reject or pay). Props: icon, iconColor, title, subtitle, actions list.

### 2.8 `section_header.dart`
Row with emoji + title + optional "See all" link. Props: emoji, title, onSeeAll.

---

## 3. Navigation Restructure

### 3.1 Bottom Navigation — 4 Tabs

| Tab | Icon | Label | Screen |
|-----|------|-------|--------|
| 0 | 🏠 | Home | Action-first dashboard |
| 1 | 👥 | Community | Notices, Chat, Events, Polls, Directory |
| 2 | 🛎️ | Services | Visitors, Bills, Packages, Facilities, Marketplace |
| 3 | ⚙️ | More | Profile, Settings, Admin, Documents, SOS |

Remove the separate Alerts tab — alerts are merged into Home as the "Needs Your Attention" section.

### 3.2 Navigation Bar Styling
- Warm white background with amber active indicator
- Emoji icons (or Material icons with warm tint)
- Dynamic badge counts from real data (not hardcoded)

---

## 4. Home Screen — Action-First Redesign

### 4.1 Layout (top to bottom)

1. **Greeting Bar** — Avatar (gradient amber/orange circle with initial) + "Good morning, {name}!" + society name + flat number. Notification bell icon (top right) with red unread dot.

2. **Needs Your Attention** — Section header with ⚡ emoji. Vertical list of `ActionTile` widgets:
   - Pending visitors: "Rahul wants to visit" + purpose + time ago + [✓ Approve] [✗ Reject] buttons
   - Due bills: "Maintenance due" + amount + due date + [Pay] button
   - Unread important notices: title + snippet + [Read] button
   - Sorted by urgency (newest first, highest priority first)
   - If empty: show friendly "All caught up! 🎉" message

3. **Quick Access** — Horizontal scrollable row of pastel tiles. Each tile: emoji icon + label. Tiles: Visitors, Packages, Notices, Bills, Booking, Polls, Gate Log, QR Pass. Scrollable so it works on all screen sizes.

4. **Community Feed** — Section header "🏘️ Community". Recent notices and active polls as compact cards. Each shows title + age + category chip. Tap navigates to full screen.

5. **SOS FAB** — Bottom right, red gradient, only pulses when there's an active emergency. Otherwise static with subtle shadow.

### 4.2 Responsive Behavior
- Quick access tiles: fixed width per tile, horizontal scroll handles all screen sizes
- Action tiles: full width, stack vertically
- No fixed pixel widths for cards — use EdgeInsets and Expanded

---

## 5. Auth — Illustrated Story Onboarding

### 5.1 Flow

```
Welcome → Phone Input → OTP Verify → Profile (Name/Flat) → Society Selection
```

### 5.2 Per-Step Design

Each step is a full-screen page with:
- Top 40%: Warm gradient background (`#FFFBEB` → `#FEF3C7`) with large centered emoji/icon illustration
- Progress indicator: Dotted path with filled/unfilled circles (like a journey map)
- Bottom 60%: White card sliding up with form fields

**Step 1 — Welcome:**
- Illustration: 🏠 large house emoji (72px) on amber gradient circle
- Title: "Welcome to your community"
- Subtitle: "Let's get you set up in under a minute"
- Input: Phone number with +91 prefix
- Button: "Continue" (amber gradient filled)
- Below: "Or sign in with Google" (outlined button with Google icon)

**Step 2 — Verify:**
- Illustration: 📱 phone emoji
- Title: "We sent you a code"
- Subtitle: "Enter the 6-digit OTP sent to +91 {phone}"
- Input: 6-digit OTP with auto-focus and auto-advance
- Button: "Verify" (amber gradient)
- Below: "Resend code" timer + "Change number" text button

**Step 3 — About You:**
- Illustration: 👋 waving hand
- Title: "Tell us about yourself"
- Inputs: Name field, Flat/House number field
- Admin toggle: "I'm a society admin" switch
- Button: "Next" (amber gradient)

**Step 4 — Your Society:**
- Illustration: 🏘️ houses
- Title: "Find your community"
- Community type: Two selectable cards ("🏢 Society" / "🏘️ Sector/Colony")
- Society picker: Dropdown with search
- Button: "Join Community" (amber gradient)

### 5.3 Transitions
- Pages slide left-to-right (CupertinoPageTransition)
- Dotted progress path animates between steps
- Fields appear with subtle fade-in

---

## 6. Feature Screens — Rich Card Feed

### 6.1 Complaints Screen

**AppBar:** "Complaints" title, warm styling
**Filter bar:** Horizontal `FilterChipBar` — All, 🔴 Open, 🔵 In Progress, ✅ Resolved
**List:** `ListView.builder` of complaint cards:
- Left: Category icon in pastel rounded square (8px radius)
- Title: bold, single line
- Subtitle: "Flat {flat} • {timeAgo}"
- Preview: 2-line description truncated with ellipsis
- Top-right: `PriorityBadge` (HIGH/MED/LOW)
- Bottom-left: `StatusChip` (colored dot + label)
- Bottom-right: 💬 reply count
**FAB:** Extended — "➕ New Complaint" (amber gradient with shadow)
**Empty state:** "No complaints — that's great! 🎉"
**Loading:** `ShimmerLoader` with 3 card placeholders

### 6.2 Notices Screen

Same card feed pattern as complaints but:
- Filter chips: All, Announcement, AGM Minutes, Rules, Financial
- Cards show: pinned icon if pinned, category chip, like count, NEW badge if < 3 days
- FAB: "➕ Add Notice" (admin only)

### 6.3 Visitors Screen

Same card feed pattern but:
- Cards show: visitor name, purpose, time, status chip
- Pending visitors get inline approve/reject buttons (like action tiles)
- FAB: "➕ Pre-approve Visitor"

### 6.4 Other Feature Screens

Apply the same warm card feed pattern consistently to: Packages, Events, Polls, Bills, Gate Log. Each gets appropriate filter chips and FAB.

---

## 7. Community & Services Hubs

Warm list tiles with:
- Left: Pastel icon container (48px, 12px border radius) with category emoji
- Title + subtitle in theme typography
- Right: Stone-400 chevron
- Subtle card shadow
- Consistent across both hub screens

---

## 8. Theme Updates

### 8.1 `lib/utils/theme.dart` Changes

- Light theme: scaffold background `#FFFDF7`, card theme with 14px radius and warm border
- Dark theme: scaffold background stone-950, cards stone-900, keep amber primary
- AppBar: warm white background, no elevation, stone-900 title
- Input decoration: filled with cream background, amber focus border
- FAB: amber gradient theme
- SnackBar: warm styling (success = green pastel, error = red pastel)
- Bottom sheet: 20px top radius, warm white background
- NavigationBar: warm white, amber indicator

### 8.2 Remove All Hardcoded Colors

Every screen that uses `Colors.xxx` or `Color(0xFFxxx)` directly must be refactored to use `AppColors` or `Theme.of(context).colorScheme`.

---

## 9. Files to Create

| File | Purpose |
|------|---------|
| `lib/utils/app_colors.dart` | Centralized color palette |
| `lib/utils/app_spacing.dart` | Spacing constants |
| `lib/widgets/warm_card.dart` | Standard warm card |
| `lib/widgets/status_chip.dart` | Status dot + label |
| `lib/widgets/priority_badge.dart` | Priority badge |
| `lib/widgets/filter_chip_bar.dart` | Horizontal filter chips |
| `lib/widgets/empty_state.dart` | Empty state widget |
| `lib/widgets/shimmer_loader.dart` | Loading placeholder |
| `lib/widgets/action_tile.dart` | Actionable notification card |
| `lib/widgets/section_header.dart` | Section title with emoji |

## 10. Files to Modify

| File | Changes |
|------|---------|
| `lib/utils/theme.dart` | Full warm theme overhaul |
| `lib/screens/home/main_shell.dart` | 4-tab nav, remove alerts tab, dynamic badges |
| `lib/screens/home/home_screen.dart` | Full redesign — action-first layout |
| `lib/screens/home/community_screen.dart` | Warm hub tiles |
| `lib/screens/home/services_screen.dart` | Warm hub tiles |
| `lib/screens/home/more_screen.dart` | Absorb old alerts features, warm styling |
| `lib/screens/auth/auth_screen.dart` | Illustrated story onboarding |
| `lib/screens/splash/splash_screen.dart` | Warm gradient + amber colors |
| `lib/screens/complaints/complaints_screen.dart` | Rich card feed redesign |
| `lib/screens/notices/notices_screen.dart` | Rich card feed redesign |
| `lib/screens/visitors/visitors_screen.dart` | Rich card feed with inline actions |
| `lib/screens/home/alerts_screen.dart` | Remove (merged into home) |
| `lib/utils/helpers.dart` | Use AppColors for status/priority colors |
| All other screens | Replace hardcoded colors with AppColors/theme |
