# Changelog - MyNeighborhood App

## v2.0.0 — March 24, 2026 — Major Feature & UX Overhaul

### 🆕 New Features

#### Package/Delivery Tracking Screen
- Full package tracking with Pending Pickup and Collected tabs
- Each package shows: courier name (Amazon, Flipkart, Swiggy, etc.), AWB number, received date/time, collected date/time
- Courier-specific colors and icons (brand colors for Amazon orange, Flipkart blue, etc.)
- "Mark as Collected" button on pending packages
- Notification badge showing pending package count
- Detail view with all package info
- Pull-to-refresh support
- Empty state illustrations

#### Community Hub Screen (New Tab)
- New bottom nav tab consolidating community features
- Quick access cards to: Notices, Chat, Events, Polls, Directory
- Each with gradient icons and descriptive subtitles

#### Services Hub Screen (New Tab)
- New bottom nav tab for all services
- Access to: Marketplace, Amenity Booking, Daily Help, Package Tracking
- Clean card-based layout with gradient icons

#### Alerts Screen (New Tab)
- Unified alerts/notifications center
- Shows: visitor approvals, complaint updates, package arrivals, bill reminders
- Color-coded by type (orange for visitors, blue for packages, red for bills)
- "Mark all read" action
- Tappable alerts navigate to relevant screens

### 🔄 Navigation Restructured
- **New 5-tab bottom navigation**: Home, Community, Services, Alerts, More
- Alerts tab shows badge with pending notification count
- More screen reorganized with section headers (Finances, Gate & Security, Vehicle, Governance, Settings)
- Cleaner grouping of all features

### 🏠 Home Screen Enhancements
- **Today's Summary Card**: Shows visitor count, pending packages, complaints, events at a glance
- **Weather Widget**: Mini weather display in the summary card (32°C ☀️)
- **Gradient Quick Action Icons**: All quick actions now have gradient backgrounds with subtle shadows
- **Badge Counts**: Quick action icons show pending count badges (4 packages, 2 bills, etc.)
- **SOS Floating Action Button**: Pulsing red FAB always visible on home screen for quick emergency access
- **Package & Amenity Quick Actions**: Added to the quick actions grid
- **"NEW" badge** on recent announcements (< 3 days old)
- **Notification badge** on the bell icon
- **Deeper blue gradient** in header (0D47A1 → 1565C0 → 1E88E5)

### 🎨 UI/UX Improvements — All Screens

#### Complaints Screen
- Pulsing red dot animation for HIGH priority complaints
- Better priority display with colored circle indicators in dropdown
- More visible description preview (2-line excerpt on cards)
- Improved empty states with illustrations
- Pull-to-refresh support
- Better admin response container with icon

#### Notice Board
- **"NEW" badge** on notices less than 3 days old
- **Share button** on each notice card
- Pinned notices always at top with pin icon
- Pull-to-refresh support
- Better empty state

#### Marketplace
- **Condition tags**: Like New / Used / Good / Fair — color-coded badges on each item
- **"Negotiate" button** alongside "Chat with Seller" in item detail
- **Sort by**: Date, Price ↑, Price ↓ via popup menu
- **Better image placeholders**: Category-specific colored backgrounds with matching icons instead of broken images
- **Green price styling**: ₹ amounts in bold green (#2E7D32)
- Pull-to-refresh on both Items and Services tabs
- Empty state illustrations

#### Directory
- **Alphabetical section headers** (A, B, C...) dividing resident list
- **Always-visible search bar** with clear button
- **Quick call & WhatsApp buttons** on each resident card
- **Prominent flat numbers** in styled badge chips
- Better card layout with avatars
- Pull-to-refresh

#### Chat
- **Modern chat bubbles** with shadow and improved border radius
- **Timestamp grouping**: "Today", "Yesterday", or date headers between messages
- **Online status indicator** (green dot on avatar)
- **Typing indicator**: Animated bouncing dots when simulated response pending
- **Read receipts**: Double-check marks on sent messages
- **Attachment button** in message input area
- Improved message input design

#### Polls & Voting
- **Animated progress bars** — vote bars animate on cast with smooth transitions
- **Vote count AND percentage** shown side-by-side
- **Time remaining badge** on each poll (e.g., "5d left", "3h left")
- **"You voted" indicator** after casting vote
- **Animated vote confirmation** snackbar with checkmark
- **Winner highlighting** for highest-voted option
- Pull-to-refresh
- Improved empty state

### 🎯 Theme & Colors
- **Updated card theme**: 16px border radius, elevation 2, subtle shadows
- **Smooth page transitions**: CupertinoPageTransitionsBuilder for iOS-like slide transitions on all platforms
- **Consistent snackbar styling**: Floating behavior with rounded corners
- **Background**: #F5F5F5 light grey
- **Dark mode**: Improved with #121212 scaffold background
- **Accent color**: Updated to #FF8F00 (amber/orange) for CTAs
- **Error color**: #C62828 (deep red)
- **Success color**: #2E7D32 (deep green)

### 🔧 Technical Changes
- Added `screens/packages/packages_screen.dart` — new Package Tracking feature
- Added `screens/home/community_screen.dart` — Community hub tab
- Added `screens/home/services_screen.dart` — Services hub tab
- Added `screens/home/alerts_screen.dart` — Alerts/notifications tab
- Updated `screens/home/main_shell.dart` — 5-tab navigation
- Updated `screens/home/more_screen.dart` — section headers, reorganized
- Updated `utils/theme.dart` — improved card theme, transitions, snackbar
- Updated `utils/locale_provider.dart` — added nav_community, nav_services, nav_alerts translations
- Improved all existing screen files with consistent patterns

### 📋 Competitive Gap Closure
Based on competitive analysis vs MyGate, NoBrokerHood, ADDA:
- ✅ Package/Delivery Tracking — **CLOSED** (was missing, all top 5 competitors have it)
- ✅ Emergency SOS — was already built, now **ENHANCED** with home screen FAB
- ✅ Daily Help Management — was already built via Staff screen
- ✅ Amenity Booking — was already built via Facility screen
- ✅ Dark Mode — only MyGate had it, we now have improved dark theme
- ✅ Modern UI — leapfrogging dated competitors (ADDA, ApnaComplex)

### 🌐 Deployment
- Live at: https://society-app-live.web.app
