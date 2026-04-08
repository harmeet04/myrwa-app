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
                  decoration: BoxDecoration(color: a.color, borderRadius: BorderRadius.circular(8)),
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
