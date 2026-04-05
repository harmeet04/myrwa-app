import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/locale_provider.dart';
import 'home_screen.dart';
import 'community_screen.dart';
import 'services_screen.dart';
import 'alerts_screen.dart';
import 'more_screen.dart';

class MainShell extends StatefulWidget {
  final VoidCallback onThemeToggle;
  const MainShell({super.key, required this.onThemeToggle});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const CommunityScreen(),
      const ServicesScreen(),
      const AlertsScreen(),
      MoreScreen(onThemeToggle: widget.onThemeToggle),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: locale.get('nav_home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups),
            label: locale.get('nav_community'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.miscellaneous_services_outlined),
            selectedIcon: const Icon(Icons.miscellaneous_services),
            label: locale.get('nav_services'),
          ),
          NavigationDestination(
            icon: Badge(
              label: const Text('3'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              label: const Text('3'),
              child: const Icon(Icons.notifications),
            ),
            label: locale.get('nav_alerts'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz_outlined),
            selectedIcon: const Icon(Icons.more_horiz),
            label: locale.get('nav_more'),
          ),
        ],
      ),
    );
  }
}
