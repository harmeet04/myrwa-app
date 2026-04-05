import 'package:flutter/material.dart';
import '../../utils/prefs_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
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
  late Animation<double> _fadeIn;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5, curve: Curves.easeIn)));
    _scale = Tween<double>(begin: 0.5, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5, curve: Curves.elasticOut)));
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    Widget dest;
    if (AuthService.isLoggedIn && PrefsService.isLoggedIn) {
      // Refresh profile from Firestore & init notifications
      await AuthService.loadUserProfile();
      await NotificationService.init();
      dest = MainShell(onThemeToggle: widget.onThemeToggle);
    } else {
      dest = AuthScreen(onThemeToggle: widget.onThemeToggle);
    }
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
      backgroundColor: const Color(0xFF1565C0),
      body: Center(
        child: AnimatedBuilder(
          listenable: _ctrl,
          builder: (context, child) => Opacity(
            opacity: _fadeIn.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.apartment, size: 64, color: Color(0xFF1565C0)),
                  ),
                  const SizedBox(height: 24),
                  const Text('myRWA', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('Your Society, Connected', style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.8))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  const AnimatedBuilder({super.key, required super.listenable, required this.builder});

  @override
  Widget build(BuildContext context) => builder(context, null);

  Animation<double> get animation => listenable as Animation<double>;
}
