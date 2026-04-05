import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'utils/theme.dart';
import 'utils/prefs_service.dart';
import 'utils/locale_provider.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await PrefsService.init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDark;
  late double _textScale;

  @override
  void initState() {
    super.initState();
    _isDark = PrefsService.isDarkMode;
    _textScale = PrefsService.textScaleFactor;
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
      home: SplashScreen(onThemeToggle: _onSettingsChanged),
    );
  }
}
