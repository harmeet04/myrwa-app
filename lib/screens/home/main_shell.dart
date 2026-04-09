import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/locale_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/connectivity_banner.dart';
import '../../services/notification_provider.dart';
import '../../services/notification_service.dart';
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
  void initState() {
    super.initState();
    final notifProvider = context.read<NotificationProvider>();
    notifProvider.init();
    NotificationService.onForegroundMessage = (message) {
      final body = message.notification?.body ?? 'New notification';
      notifProvider.onNewMessage(body);
    };
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final screens = [
      const HomeScreen(),
      const CommunityScreen(),
      const ServicesScreen(),
      MoreScreen(onThemeToggle: widget.onThemeToggle),
    ];

    return Scaffold(
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(child: IndexedStack(index: _index, children: screens)),
        ],
      ),
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
