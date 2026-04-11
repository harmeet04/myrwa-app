import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'utils/app_colors.dart';
import 'utils/theme.dart';
import 'utils/prefs_service.dart';
import 'utils/locale_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'services/analytics_service.dart';
import 'services/notification_provider.dart';
import 'services/notification_service.dart';
import 'utils/seed_data.dart';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await PrefsService.init();

    // Seed demo users (run once, then remove this line)
    await SeedData.seedDemoUsers();

    // Global error handler
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      try { FirebaseCrashlytics.instance.recordFlutterFatalError(details); } catch (_) {}
    };

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('Uncaught error: $error');
    try { FirebaseCrashlytics.instance.recordError(error, stack, fatal: true); } catch (_) {}
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDark;
  late double _textScale;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _isDark = PrefsService.isDarkMode;
    _textScale = PrefsService.textScaleFactor;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.setupInteractiveMessage(navigatorKey);
    });
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.statusError),
                const SizedBox(height: 16),
                const Text('Something went wrong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(details.exceptionAsString(), style: TextStyle(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    };
  }

  void _onSettingsChanged() {
    setState(() {
      _isDark = PrefsService.isDarkMode;
      _textScale = PrefsService.textScaleFactor;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to locale changes to rebuild
    context.watch<LocaleProvider>();
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'myRWA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(_textScale),
          ),
          child: child!,
        );
      },
      navigatorObservers: [AnalyticsService.observer],
      home: SplashScreen(onThemeToggle: _onSettingsChanged),
    );
  }
}
