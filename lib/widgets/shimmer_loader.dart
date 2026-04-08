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
  void dispose() { _ctrl.dispose(); super.dispose(); }

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
                  Row(children: [
                    _shimmerBox(32, 32, AppSpacing.sm),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [_shimmerBox(double.infinity, 14, 4), const SizedBox(height: 6), _shimmerBox(120, 10, 4)],
                    )),
                    _shimmerBox(40, 16, 6),
                  ]),
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
      width: width, height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: [Colors.grey.shade200, Colors.grey.shade100, Colors.grey.shade200],
          stops: [(_ctrl.value - 0.3).clamp(0.0, 1.0), _ctrl.value, (_ctrl.value + 0.3).clamp(0.0, 1.0)],
        ),
      ),
    );
  }
}
