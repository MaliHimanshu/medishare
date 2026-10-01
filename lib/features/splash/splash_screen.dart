import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../core/constants/app_colors.dart';
import '../../firebase_options.dart';
import '../../core/services/fcm_service.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';
import 'splash_animation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static bool _splashShown = false;
  bool _hasNavigated = false;

  late final AnimationController _mainController;
  late final AudioPlayer _splashAudioPlayer;

  @override
  void initState() {
    super.initState();
    debugPrint('SPLASH START');

    _splashAudioPlayer = AudioPlayer();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000), // strictly 10.0s timeline
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_splashShown) {
        _splashShown = true;
        _startSplash();
      } else {
        _mainController.value = 1.0;
        _navigateToAppImmediately();
      }
    });
  }

  void _startSplash() {
    // Start audio immediately
    _playSplashAudio();

    // Start animation immediately
    _mainController.forward();
    
    // Listen for completion
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        debugPrint('SPLASH LOGO COMPLETE');
        debugPrint('SPLASH NAVIGATION START');
        _navigateToAppImmediately();
      }
    });

    // Run initialization in background
    _initializeServicesInBackground();
  }

  Future<void> _playSplashAudio() async {
    debugPrint('SPLASH AUDIO START');
    try {
      await _splashAudioPlayer.stop();
      await _splashAudioPlayer.setVolume(1.0);
      await _splashAudioPlayer.setReleaseMode(ReleaseMode.stop);

      await _splashAudioPlayer.play(
        AssetSource('audio/medishare_clear_sound.mp3'),
        volume: 1.0,
      );

      debugPrint('SPLASH AUDIO SUCCESS');
    } catch (e, st) {
      debugPrint('SPLASH AUDIO ERROR: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> _initializeServicesInBackground() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FcmService().init();
    } catch (e, stack) {
      debugPrint('Startup initialization error: $e\n$stack');
    }

    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    await authProvider.checkAuthStatus();
  }

  Future<void> _navigateToAppImmediately() async {
    if (_hasNavigated) return;
    if (!mounted) return;
    _hasNavigated = true;

    final authProvider = context.read<AuthProvider>();
    final Widget destination;

    if (authProvider.isAuthenticated) {
      destination = const HomeScreen();
    } else {
      final prefs = await SharedPreferences.getInstance();
      final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
      destination = seenOnboarding
          ? const LoginScreen()
          : const OnboardingScreen();
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, anim, secondary) => destination,
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _splashAudioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: RepaintBoundary(
        child: SizedBox.expand(
          child: MediShareSplashAnimation(
            controller: _mainController,
            isDark: context.isDarkMode,
          ),
        ),
      ),
    );
  }
}
