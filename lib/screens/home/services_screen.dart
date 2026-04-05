import 'package:flutter/material.dart';
import '../marketplace/marketplace_screen.dart';
import '../facility/facility_screen.dart';
import '../staff/staff_screen.dart';
import '../packages/packages_screen.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _ServiceItem(Icons.store_rounded, 'Marketplace', 'Buy & sell within society', const Color(0xFFFF7043), const MarketplaceScreen()),
      _ServiceItem(Icons.meeting_room_rounded, 'Amenity Booking', 'Clubhouse, gym, pool & more', const Color(0xFF7E57C2), const FacilityScreen()),
      _ServiceItem(Icons.badge_rounded, 'Daily Help', 'Maid, cook, driver tracking', const Color(0xFF26A69A), const StaffScreen()),
      _ServiceItem(Icons.inventory_2_rounded, 'Package Tracking', 'Deliveries & parcels', const Color(0xFF42A5F5), const PackagesScreen()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => item.screen)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [item.color, item.color.withValues(alpha: 0.7)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item.icon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(item.subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      ],
                    )),
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ServiceItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget screen;
  const _ServiceItem(this.icon, this.title, this.subtitle, this.color, this.screen);
}
