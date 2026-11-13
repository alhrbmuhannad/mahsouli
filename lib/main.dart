import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'screens/auth/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark),
  );
  runApp(ChangeNotifierProvider(create: (_) => AppState()..load(), child: const MahsouliApp()));
}

class MahsouliApp extends StatelessWidget {
  const MahsouliApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.select<AppState, Locale>((s) => s.locale);
    return MaterialApp(
      title: 'Mahsouli | محصولي',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const RootGate(),
    );
  }
}

/// Decides which top-level screen to show: splash → onboarding → login → app.
class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final Widget child;
    if (!state.loaded || !_splashDone) {
      child = const SplashScreen();
    } else if (!state.onboarded) {
      child = const OnboardingScreen();
    } else if (!state.hasSession) {
      child = const LoginScreen();
    } else {
      child = const MainShell();
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: KeyedSubtree(key: ValueKey(child.runtimeType), child: child),
    );
  }
}
