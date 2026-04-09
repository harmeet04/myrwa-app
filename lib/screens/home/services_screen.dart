import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/prefs_service.dart';
import '../../widgets/warm_card.dart';
import '../visitors/visitors_screen.dart';
import '../bills/bills_screen.dart';
import '../packages/packages_screen.dart';
import '../facility/facility_screen.dart';
import '../marketplace/marketplace_screen.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isGated = PrefsService.isGatedCommunity;
    final items = [
      if (isGated)
        _ServiceItem('🚶', 'Visitors', 'Manage guest approvals', AppColors.amberBg, AppColors.amberBorder, const VisitorsScreen()),
      _ServiceItem('🧾', 'Reminders', 'Maintenance & bill reminders', AppColors.blueBg, AppColors.blueBorder, const BillsScreen()),
      if (isGated)
        _ServiceItem('📦', 'Packages', 'Deliveries & parcels', AppColors.greenBg, AppColors.greenBorder, const PackagesScreen()),
      _ServiceItem('🏋️', 'Facility Booking', 'Clubhouse, gym, pool & more', AppColors.pinkBg, AppColors.pinkBorder, const FacilityScreen()),
      _ServiceItem('🛍️', 'Marketplace', 'Buy & sell within society', AppColors.purpleBg, AppColors.purpleBorder, const MarketplaceScreen()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          return WarmCard(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => item.screen)),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.bgColor,
                    border: Border.all(color: item.borderColor, width: 1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusIcon),
                  ),
                  child: Center(
                    child: Text(item.emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textTertiary),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ServiceItem {
  final String emoji;
  final String title;
  final String subtitle;
  final Color bgColor;
  final Color borderColor;
  final Widget screen;

  const _ServiceItem(this.emoji, this.title, this.subtitle, this.bgColor, this.borderColor, this.screen);
}
