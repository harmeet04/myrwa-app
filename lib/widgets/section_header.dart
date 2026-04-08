import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';

class SectionHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final VoidCallback? onSeeAll;

  const SectionHeader({super.key, required this.emoji, required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: AppSpacing.sm),
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: const Text('See all', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryAmber)),
            ),
        ],
      ),
    );
  }
}
