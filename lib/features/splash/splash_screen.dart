import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../core/constants/app_colors.dart';
import '../../firebase_options.dart';
import '../../core/services/fcm_service.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'splash_animation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Static flag: splash plays ONCE per process lifecycle only.
  static bool _splashShown = false;

  late final AnimationController _mainController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000), // 9 seconds
    );

    if (!_splashShown) {
      _splashShown = true;
      _preloadAudioAndStart();
    } else {
      _mainController.value = 1.0;
      Future.microtask(_doNavigate);
    }
  }

  Future<void> _preloadAudioAndStart() async {
    // Start animation IMMEDIATELY without waiting for anything else.
    _mainController.forward();

    // Play audio
    _audioPlayer.play(AssetSource('audio/splash_audio.wav')).catchError((e) {
      debugPrint('Audio playback error: $e');
    });

    // Run initialization in parallel
    _initializeServices();

    // Wait for the animation to finish fully
    await Future.delayed(const Duration(milliseconds: 9000));

    if (!mounted) return;
    _doNavigate();
  }

  Future<void> _initializeServices() async {
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

  Future<void> _doNavigate() async {
    if (!mounted) return;

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
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) {
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
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: MediShareSplashAnimation(
                controller: _mainController,
                isDark: context.isDarkMode,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF06152F), Color(0xFF0A2550), Color(0xFF06152F)],
        ),
      ),
      child: CustomPaint(painter: _SplashGlowPainter()),
    );
  }
}

class _SplashGlowPainter extends CustomPainter {
  const _SplashGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF2878FF).withValues(alpha: 0.16),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height / 2),
              radius: size.width * 0.65,
            ),
          );

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
