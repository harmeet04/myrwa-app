# MyRWA UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign MyRWA with a warm & friendly visual style, action-first home screen, illustrated auth onboarding, and rich card feed feature screens.

**Architecture:** Extract a centralized design system (colors, spacing, typography, shared widgets), then redesign key screens top-down: theme → shared widgets → splash → auth → main navigation → home → feature screens → remaining screens.

**Tech Stack:** Flutter/Dart, Material 3, Firebase, Provider

---

### Task 1: Design System — AppColors & AppSpacing

**Files:**
- Create: `lib/utils/app_colors.dart`
- Create: `lib/utils/app_spacing.dart`

- [ ] **Step 1: Create `lib/utils/app_colors.dart`**

```dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary gradient
  static const Color primaryAmber = Color(0xFFF59E0B);
  static const Color primaryOrange = Color(0xFFEA580C);
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryAmber, primaryOrange],
  );

  // Backgrounds
  static const Color scaffoldLight = Color(0xFFFFFDF7);
  static const Color surfaceLight = Color(0xFFFFFBEB);
  static const Color cardLight = Colors.white;
  static const Color cardBorder = Color(0xFFE7E5E4);

  // Dark theme backgrounds
  static const Color scaffoldDark = Color(0xFF1C1917);
  static const Color surfaceDark = Color(0xFF292524);
  static const Color cardDark = Color(0xFF292524);

  // Category pastels (background / border)
  static const Color amberBg = Color(0xFFFEF3C7);
  static const Color amberBorder = Color(0xFFFDE68A);
  static const Color greenBg = Color(0xFFECFDF5);
  static const Color greenBorder = Color(0xFFA7F3D0);
  static const Color blueBg = Color(0xFFEFF6FF);
  static const Color blueBorder = Color(0xFFBFDBFE);
  static const Color pinkBg = Color(0xFFFDF2F8);
  static const Color pinkBorder = Color(0xFFFBCFE8);
  static const Color purpleBg = Color(0xFFF5F3FF);
  static const Color purpleBorder = Color(0xFFDDD6FE);
  static const Color redBg = Color(0xFFFEF2F2);
  static const Color redBorder = Color(0xFFFECACA);

  // Text (Stone scale)
  static const Color textPrimary = Color(0xFF292524);
  static const Color textSecondary = Color(0xFF78716C);
  static const Color textTertiary = Color(0xFFA8A29E);
  static const Color textOnPrimary = Color(0xFF451A03);

  // Dark text
  static const Color textPrimaryDark = Color(0xFFF5F5F4);
  static const Color textSecondaryDark = Color(0xFFA8A29E);

  // Status
  static const Color statusError = Color(0xFFDC2626);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusSuccess = Color(0xFF22C55E);

  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1)),
  ];
  static List<BoxShadow> elevatedShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2)),
  ];
  static List<BoxShadow> fabShadow = [
    BoxShadow(color: primaryAmber.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
  ];

  // Helper: status color from enum/string
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open' || 'pending' || 'overdue':
        return statusError;
      case 'inprogress' || 'in progress' || 'in_progress' || 'approved':
        return statusWarning;
      case 'resolved' || 'completed' || 'paid':
        return statusSuccess;
      default:
        return textTertiary;
    }
  }

  // Helper: priority color
  static Color priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return statusError;
      case 'medium':
        return statusWarning;
      case 'low':
        return statusSuccess;
      default:
        return textTertiary;
    }
  }
}
```

- [ ] **Step 2: Create `lib/utils/app_spacing.dart`**

```dart
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  // Border radii
  static const double radiusCard = 14;
  static const double radiusModal = 20;
  static const double radiusChip = 10;
  static const double radiusIcon = 12;
  static const double radiusButton = 14;
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/utils/app_colors.dart lib/utils/app_spacing.dart
git commit -m "feat: add design system — AppColors and AppSpacing constants"
```

---

### Task 2: Theme Overhaul

**Files:**
- Modify: `lib/utils/theme.dart` (full rewrite, 89 lines)

- [ ] **Step 1: Rewrite `lib/utils/theme.dart`**

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: AppColors.primaryAmber,
    scaffoldBackgroundColor: AppColors.scaffoldLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.scaffoldLight,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        side: const BorderSide(color: AppColors.cardBorder, width: 0.5),
      ),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        borderSide: const BorderSide(color: AppColors.primaryAmber, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryAmber,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusButton)),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusCard))),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusModal)),
      ),
      backgroundColor: AppColors.scaffoldLight,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.scaffoldLight,
      indicatorColor: AppColors.amberBg,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStatePropertyAll(IconThemeData(color: AppColors.textSecondary)),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusChip)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: AppColors.primaryAmber,
    scaffoldBackgroundColor: AppColors.scaffoldDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.scaffoldDark,
      foregroundColor: AppColors.textPrimaryDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimaryDark,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
      ),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        borderSide: const BorderSide(color: AppColors.primaryAmber, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryAmber,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusButton)),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusCard))),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusModal)),
      ),
      backgroundColor: AppColors.scaffoldDark,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.scaffoldDark,
      indicatorColor: AppColors.primaryAmber.withValues(alpha: 0.2),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusChip)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
```

- [ ] **Step 2: Run `flutter analyze` to verify no errors**

Run: `flutter analyze`
Expected: No errors (warnings about other files expected until they're updated)

- [ ] **Step 3: Commit**

```bash
git add lib/utils/theme.dart
git commit -m "feat: overhaul theme with warm & friendly palette"
```

---

### Task 3: Shared Widgets

**Files:**
- Create: `lib/widgets/warm_card.dart`
- Create: `lib/widgets/status_chip.dart`
- Create: `lib/widgets/priority_badge.dart`
- Create: `lib/widgets/filter_chip_bar.dart`
- Create: `lib/widgets/empty_state.dart`
- Create: `lib/widgets/shimmer_loader.dart`
- Create: `lib/widgets/action_tile.dart`
- Create: `lib/widgets/section_header.dart`

- [ ] **Step 1: Create `lib/widgets/warm_card.dart`**

```dart
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';

class WarmCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? pastelColor;
  final Color? borderColor;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const WarmCard({
    super.key,
    required this.child,
    this.onTap,
    this.pastelColor,
    this.borderColor,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: borderColor ?? (isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.cardBorder),
          width: 0.5,
        ),
        boxShadow: isDark ? null : AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
            child: child,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create `lib/widgets/status_chip.dart`**

```dart
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color? color;

  const StatusChip({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.statusColor(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: c),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Create `lib/widgets/priority_badge.dart`**

```dart
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.priorityColor(priority);
    final bgColor = color.withValues(alpha: 0.1);
    final label = switch (priority.toLowerCase()) {
      'high' => 'HIGH',
      'medium' => 'MED',
      'low' => 'LOW',
      _ => priority.toUpperCase(),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
```

- [ ] **Step 4: Create `lib/widgets/filter_chip_bar.dart`**

```dart
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';

class FilterChipBar extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const FilterChipBar({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryAmber : AppColors.amberBg,
                borderRadius: BorderRadius.circular(20),
                border: selected ? null : Border.all(color: AppColors.amberBorder),
              ),
              child: Text(
                options[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textOnPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 5: Create `lib/widgets/empty_state.dart`**

```dart
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';

class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;

  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Create `lib/widgets/shimmer_loader.dart`**

```dart
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';

class ShimmerLoader extends StatefulWidget {
  final int itemCount;

  const ShimmerLoader({super.key, this.itemCount = 3});

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: widget.itemCount,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                border: Border.all(color: AppColors.cardBorder, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _shimmerBox(32, 32, AppSpacing.sm),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _shimmerBox(double.infinity, 14, 4),
                            const SizedBox(height: 6),
                            _shimmerBox(120, 10, 4),
                          ],
                        ),
                      ),
                      _shimmerBox(40, 16, 6),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _shimmerBox(double.infinity, 10, 4),
                  const SizedBox(height: 4),
                  _shimmerBox(200, 10, 4),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _shimmerBox(double width, double height, double radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
          stops: [
            (_ctrl.value - 0.3).clamp(0.0, 1.0),
            _ctrl.value,
            (_ctrl.value + 0.3).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;
  const AnimatedBuilder({super.key, required Animation<double> animation, required this.builder, this.child})
      : super(listenable: animation);
  @override
  Widget build(BuildContext context) => builder(context, child);
}
```

- [ ] **Step 7: Create `lib/widgets/action_tile.dart`**

```dart
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';

class ActionTile extends StatelessWidget {
  final String emoji;
  final Color bgColor;
  final Color borderColor;
  final String title;
  final String subtitle;
  final List<ActionTileButton> actions;
  final VoidCallback? onTap;

  const ActionTile({
    super.key,
    required this.emoji,
    required this.bgColor,
    required this.borderColor,
    required this.title,
    required this.subtitle,
    required this.actions,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            ...actions.map((a) => Padding(
              padding: const EdgeInsets.only(left: 4),
              child: GestureDetector(
                onTap: a.onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: a.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(a.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class ActionTileButton {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ActionTileButton({required this.label, required this.color, required this.onTap});
}
```

- [ ] **Step 8: Create `lib/widgets/section_header.dart`**

```dart
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';

class SectionHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final VoidCallback? onSeeAll;

  const SectionHeader({
    super.key,
    required this.emoji,
    required this.title,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'See all',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryAmber),
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 9: Run `flutter analyze` to verify all widgets compile**

Run: `flutter analyze`
Expected: No errors in new widget files

- [ ] **Step 10: Commit**

```bash
git add lib/widgets/
git commit -m "feat: add shared warm widgets — cards, chips, badges, loaders, tiles"
```

---

### Task 4: Update Helpers

**Files:**
- Modify: `lib/utils/helpers.dart` (72 lines)

- [ ] **Step 1: Rewrite `lib/utils/helpers.dart` to use AppColors**

```dart
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

String formatDate(DateTime d) => DateFormat('dd MMM yyyy').format(d);
String formatDateTime(DateTime d) => DateFormat('dd MMM yyyy, hh:mm a').format(d);
String formatCurrency(num n) => NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(n);
String formatTime(DateTime d) => DateFormat('hh:mm a').format(d);

String timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return formatDate(d);
}

Color statusColor(String s) => AppColors.statusColor(s);
Color priorityColor(String s) => AppColors.priorityColor(s);

IconData categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'plumbing' || 'water':
      return Icons.plumbing;
    case 'electrical' || 'electricity':
      return Icons.electrical_services;
    case 'security':
      return Icons.security;
    case 'cleaning' || 'housekeeping':
      return Icons.cleaning_services;
    case 'noise':
      return Icons.volume_up;
    case 'parking':
      return Icons.local_parking;
    case 'lift' || 'elevator':
      return Icons.elevator;
    case 'maintenance':
      return Icons.build;
    case 'garden' || 'landscaping':
      return Icons.park;
    case 'pest control':
      return Icons.bug_report;
    default:
      return Icons.report_problem;
  }
}

void showSnack(BuildContext context, String msg, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.statusError : AppColors.statusSuccess,
      duration: const Duration(seconds: 2),
    ),
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/utils/helpers.dart
git commit -m "refactor: update helpers to use AppColors"
```

---

### Task 5: Splash Screen Redesign

**Files:**
- Modify: `lib/screens/splash/splash_screen.dart` (105 lines)

- [ ] **Step 1: Rewrite splash screen with warm palette**

```dart
import 'package:flutter/material.dart';
import '../../utils/prefs_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_colors.dart';
import '../auth/auth_screen.dart';
import '../home/main_shell.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  const SplashScreen({super.key, required this.onThemeToggle});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    Widget dest;
    if (AuthService.isLoggedIn && PrefsService.isLoggedIn) {
      await AuthService.loadUserProfile();
      await NotificationService.init();
      dest = MainShell(onThemeToggle: widget.onThemeToggle);
    } else {
      dest = AuthScreen(onThemeToggle: widget.onThemeToggle);
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => dest,
        transitionsBuilder: (context, a, secondaryAnimation, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7), Color(0xFFFDE68A)],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: AppColors.fabShadow,
                    ),
                    child: const Center(
                      child: Text('🏠', style: TextStyle(fontSize: 48)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'myRWA',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your community, simplified',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run `flutter analyze` on splash**

Run: `flutter analyze lib/screens/splash/`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/screens/splash/splash_screen.dart
git commit -m "feat: redesign splash screen with warm gradient"
```

---

### Task 6: Auth Screen — Illustrated Story Onboarding

**Files:**
- Modify: `lib/screens/auth/auth_screen.dart` (413 lines — full rewrite)

- [ ] **Step 1: Rewrite auth screen**

The auth screen should be fully rewritten with the illustrated story flow. This is a large file. Key changes:
- Replace flat layout with illustrated step pages
- Each step: top gradient area with large emoji + dotted progress path + white form area below
- Warm color palette throughout
- Animated transitions between steps
- Progress dots showing journey (not a stepper)

Write the complete file to `lib/screens/auth/auth_screen.dart`. Preserve ALL existing auth logic (`_sendOtp`, `_verifyOtp`, `_signInWithGoogle`, `_completeProfile`, `_goHome`) but wrap in new warm UI. Key structure:

```
Scaffold
└── body: AnimatedSwitcher
    └── _buildStep(_currentStep)
        └── Column
            ├── Expanded(flex: 2): gradient area with emoji + progress dots
            └── Expanded(flex: 3): white card with form fields
```

The existing auth logic in `AuthService`, `PrefsService`, `NotificationService` stays unchanged. Only the UI layer changes.

Imports to add: `app_colors.dart`, `app_spacing.dart`. Remove unused `prefs_service.dart` import (already removed in debug phase).

Each step illustration:
- Step 0 (phone): 🏠 emoji, "Welcome to your community"
- Step 1 (OTP): 📱 emoji, "We sent you a code"
- Step 2 (profile): 👋 emoji, "Tell us about yourself"  
- Step 3 (society): 🏘️ emoji, "Find your community"

Progress dots: Row of 4 circles connected by dotted lines. Completed = amber filled, current = amber outlined with pulse, future = grey outlined.

Form styling: Use theme InputDecoration (already warm from Task 2). Buttons use `Container` with `AppColors.primaryGradient` decoration for the warm gradient look.

- [ ] **Step 2: Run `flutter analyze`**

Run: `flutter analyze lib/screens/auth/`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/screens/auth/auth_screen.dart
git commit -m "feat: redesign auth with illustrated story onboarding"
```

---

### Task 7: Main Shell — 4-Tab Navigation

**Files:**
- Modify: `lib/screens/home/main_shell.dart` (80 lines)

- [ ] **Step 1: Rewrite main_shell.dart with 4 tabs**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/locale_provider.dart';
import '../../utils/app_colors.dart';
import 'home_screen.dart';
import 'community_screen.dart';
import 'services_screen.dart';
import 'more_screen.dart';

class MainShell extends StatefulWidget {
  final VoidCallback onThemeToggle;
  const MainShell({super.key, required this.onThemeToggle});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final screens = [
      HomeScreen(onThemeToggle: widget.onThemeToggle),
      const CommunityScreen(),
      const ServicesScreen(),
      MoreScreen(onThemeToggle: widget.onThemeToggle),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primaryAmber),
            label: locale.get('nav_home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people_rounded, color: AppColors.primaryAmber),
            label: locale.get('nav_community'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.room_service_outlined),
            selectedIcon: Icon(Icons.room_service_rounded, color: AppColors.primaryAmber),
            label: locale.get('nav_services'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz_outlined),
            selectedIcon: Icon(Icons.more_horiz_rounded, color: AppColors.primaryAmber),
            label: locale.get('nav_more'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/screens/home/main_shell.dart
git commit -m "feat: simplify to 4-tab navigation, remove alerts tab"
```

---

### Task 8: Home Screen — Action-First Redesign

**Files:**
- Modify: `lib/screens/home/home_screen.dart` (690 lines — full rewrite)

- [ ] **Step 1: Rewrite home screen**

Full rewrite of `lib/screens/home/home_screen.dart`. Key structure:

```
Scaffold
├── floatingActionButton: SOS FAB (static, red, only pulses during emergency)
└── body: CustomScrollView
    ├── SliverToBoxAdapter: _GreetingBar (avatar + name + society + bell icon)
    ├── SliverToBoxAdapter: _NeedsAttention (list of ActionTiles)
    ├── SliverToBoxAdapter: _QuickAccess (horizontal scrollable pastel tiles)
    ├── SliverToBoxAdapter: _CommunityFeed (recent notices + polls)
    └── SliverToBoxAdapter: bottom spacing
```

Key changes from current:
- Remove gradient header, replace with simple greeting bar on warm white background
- Remove _TodaySummaryCard (info merged into _NeedsAttention)
- Replace 4x grid with horizontal scroll row (works on all screen sizes)
- Remove _EmergencyBar and _PendingBillsCard (merged into _NeedsAttention)
- Remove _AnnouncementCard (merged into _CommunityFeed)
- All colors from AppColors, all spacing from AppSpacing
- Use SectionHeader widget for section titles
- Use ActionTile widget for attention items
- Use WarmCard widget for community feed items

Import shared widgets: `action_tile.dart`, `section_header.dart`, `warm_card.dart`.
Import AppColors, AppSpacing.
Keep existing navigation imports for `_push()` helper.

Quick access tiles: Each tile is a `Container` with pastel background + border + emoji + label. Use a `ListView.builder` with `scrollDirection: Axis.horizontal` and fixed 76px width tiles.

The _NeedsAttention section should pull from MockData:
- `MockData.visitors.where((v) => v.status == VisitorStatus.pending)` → visitor action tiles
- `MockData.bills.where((b) => b.status == BillStatus.overdue || b.status == BillStatus.pending)` → bill action tiles
- Show "All caught up! 🎉" if no pending items

- [ ] **Step 2: Run `flutter analyze`**

Run: `flutter analyze lib/screens/home/home_screen.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/screens/home/home_screen.dart
git commit -m "feat: redesign home screen with action-first layout"
```

---

### Task 9: Community & Services Hub Screens

**Files:**
- Modify: `lib/screens/home/community_screen.dart` (85 lines)
- Modify: `lib/screens/home/services_screen.dart` (83 lines)

- [ ] **Step 1: Rewrite community_screen.dart with warm styling**

Replace hardcoded colors with pastel category colors from AppColors. Each hub item gets:
- Pastel icon container (48px, rounded 12px) with emoji
- Title + subtitle using theme.textTheme
- Chevron icon in AppColors.textTertiary
- WarmCard wrapping each item

Items: Notices (amber), Chat (pink), Events (purple), Polls (blue), Directory (green)

- [ ] **Step 2: Rewrite services_screen.dart with warm styling**

Same pattern as community. Items: Visitors (amber), Bills (blue), Packages (green), Facility Booking (pink), Marketplace (purple)

- [ ] **Step 3: Commit**

```bash
git add lib/screens/home/community_screen.dart lib/screens/home/services_screen.dart
git commit -m "feat: redesign community & services hubs with warm palette"
```

---

### Task 10: More Screen + Alerts Absorption

**Files:**
- Modify: `lib/screens/home/more_screen.dart` (169 lines)
- Delete: `lib/screens/home/alerts_screen.dart` (no longer referenced after Task 7)

- [ ] **Step 1: Update more_screen.dart with warm styling**

Replace all hardcoded `Colors.xxx` with AppColors equivalents. Each _MoreTile icon color should use a pastel from the palette. Group sections with SectionHeader-style headers. Keep existing navigation and language picker logic but style with warm palette.

- [ ] **Step 2: Delete alerts_screen.dart**

The alerts tab was removed in Task 7 (4-tab nav). Alerts functionality is now in the home screen's "Needs Your Attention" section. Delete `lib/screens/home/alerts_screen.dart`.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/home/more_screen.dart
git rm lib/screens/home/alerts_screen.dart
git commit -m "feat: warm more screen, remove alerts screen (merged into home)"
```

---

### Task 11: Complaints Screen — Rich Card Feed

**Files:**
- Modify: `lib/screens/complaints/complaints_screen.dart` (642 lines)

- [ ] **Step 1: Redesign complaints screen**

Key changes:
- Replace TabBar with FilterChipBar widget (All, 🔴 Open, 🔵 In Progress, ✅ Resolved)
- Replace existing complaint cards with rich card design using WarmCard
- Each card: category icon in pastel rounded box + title + "Flat {flat} • {timeAgo}" + 2-line preview + PriorityBadge (top-right) + StatusChip (bottom-left) + 💬 reply count (bottom-right)
- Replace FloatingActionButton with extended FAB: "➕ New Complaint" with amber gradient + fabShadow
- Add EmptyState per tab ("No open complaints — that's great! 🎉")
- Add ShimmerLoader while Firestore stream loads
- Keep ALL existing logic: Firestore stream, AI categorization, voice input, admin respond
- Replace hardcoded colors with AppColors throughout
- Bottom sheets use warm palette

Remove duplicated `AnimatedBuilder` class — import from `shimmer_loader.dart` instead.
Remove `_PulsingDot` — replace with simpler static red dot for high priority (less visual chaos).

- [ ] **Step 2: Run `flutter analyze`**

Run: `flutter analyze lib/screens/complaints/`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/screens/complaints/complaints_screen.dart
git commit -m "feat: redesign complaints with rich card feed and warm palette"
```

---

### Task 12: Notices Screen — Rich Card Feed

**Files:**
- Modify: `lib/screens/notices/notices_screen.dart` (406 lines)

- [ ] **Step 1: Redesign notices screen**

Same card feed pattern as complaints:
- FilterChipBar: All, Announcement, AGM Minutes, Rules, Financial
- WarmCard for each notice with: pinned icon if pinned, category chip, title, preview text, like count, NEW badge (amber bg instead of red)
- Extended FAB for admin: "➕ Add Notice" with amber gradient
- EmptyState: "No notices yet 📭"
- ShimmerLoader while loading
- Keep all existing logic: Firestore stream, AI polish, Hindi translation, pinning
- Replace all hardcoded colors with AppColors
- Detail bottom sheet uses warm palette

- [ ] **Step 2: Commit**

```bash
git add lib/screens/notices/notices_screen.dart
git commit -m "feat: redesign notices with rich card feed and warm palette"
```

---

### Task 13: Visitors Screen — Rich Card Feed with Inline Actions

**Files:**
- Modify: `lib/screens/visitors/visitors_screen.dart` (176 lines)

- [ ] **Step 1: Redesign visitors screen**

Key changes:
- Add FilterChipBar: All, Pending, Approved, Completed
- Use WarmCard for each visitor
- Pending visitors get inline approve/reject buttons (like ActionTile pattern)
- Status shown with StatusChip widget
- Purpose shown with emoji icon in pastel box
- Extended FAB: "➕ Pre-approve Visitor"
- EmptyState: "No visitors today 🏠"
- Replace `_statusColor()` and `_purposeIcon()` with AppColors-based equivalents
- Replace all hardcoded colors

- [ ] **Step 2: Commit**

```bash
git add lib/screens/visitors/visitors_screen.dart
git commit -m "feat: redesign visitors with card feed and inline actions"
```

---

### Task 14: Remaining Screens — Color Replacement

**Files:**
- Modify: All remaining screen files that use hardcoded colors

- [ ] **Step 1: Update remaining screens to use AppColors**

For each of these files, replace all `Colors.xxx` and `Color(0xFFxxx)` with AppColors equivalents:
- `lib/screens/bills/bills_screen.dart`
- `lib/screens/chat/chat_screen.dart`
- `lib/screens/chat/chat_list_screen.dart` (if exists)
- `lib/screens/events/events_screen.dart`
- `lib/screens/polls/polls_screen.dart`
- `lib/screens/facility/facility_screen.dart`
- `lib/screens/packages/packages_screen.dart`
- `lib/screens/marketplace/marketplace_screen.dart`
- `lib/screens/gate_log/gate_log_screen.dart`
- `lib/screens/qr_pass/qr_pass_screen.dart`
- `lib/screens/vehicle/vehicle_screen.dart`
- `lib/screens/staff/staff_screen.dart`
- `lib/screens/guard/guard_screen.dart`
- `lib/screens/documents/documents_screen.dart`
- `lib/screens/accounting/accounting_screen.dart`
- `lib/screens/voting/voting_screen.dart`
- `lib/screens/profile/profile_screen.dart`
- `lib/screens/sos/sos_screen.dart`
- `lib/screens/admin/admin_panel_screen.dart`
- `lib/screens/vendor/vendor_screen.dart` (if exists)
- `lib/widgets/stream_helpers.dart`
- `lib/utils/mock_data.dart` (avatar colors)

For each file: add `import '../../utils/app_colors.dart';` and replace color references.

This is a bulk find-and-replace task. Key mappings:
- `Colors.red` → `AppColors.statusError`
- `Colors.green` → `AppColors.statusSuccess`
- `Colors.orange` → `AppColors.statusWarning`
- `Colors.grey.shade600` → `AppColors.textSecondary`
- `Colors.grey.shade400` → `AppColors.textTertiary`
- `Color(0xFF1565C0)` → `AppColors.primaryAmber`
- `Color(0xFFFF8F00)` → `AppColors.primaryOrange`
- Bottom sheet `BorderRadius.vertical(top: Radius.circular(20))` → already handled by theme

- [ ] **Step 2: Run `flutter analyze`**

Run: `flutter analyze`
Expected: No errors, no warnings

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "refactor: replace all hardcoded colors with AppColors across remaining screens"
```

---

### Task 15: Final Verification & Cleanup

**Files:**
- All files

- [ ] **Step 1: Run full analysis**

Run: `flutter analyze`
Expected: No errors, no warnings. Only infos acceptable.

- [ ] **Step 2: Test build**

Run: `flutter build web --release` (or `flutter build apk --debug` if targeting Android)
Expected: Build succeeds

- [ ] **Step 3: Remove any remaining AnimatedBuilder duplicates**

Grep for `class AnimatedBuilder` across all files. Should only exist in `lib/widgets/shimmer_loader.dart`. Remove duplicates from `home_screen.dart` and `complaints_screen.dart`.

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "chore: final cleanup — remove duplicates, verify build"
```
