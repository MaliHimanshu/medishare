import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/ms_logo.dart';
import '../onboarding/onboarding_screen.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double>    _scaleAnim;
  late Animation<double>    _fadeAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Navigate after 2.8s
    Timer(const Duration(milliseconds: 2800), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.checkAuthStatus();

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            seenOnboarding ? const LoginScreen() : const OnboardingScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.splashGradient,
        ),
        child: Stack(
          children: [
            // Background orb 1
            Positioned(
              top: -80,
              left: -80,
              child: _Orb(
                size: 300,
                color: AppColors.primary.withAlpha(60),
              ),
            ),
            // Background orb 2
            Positioned(
              bottom: -60,
              right: -60,
              child: _Orb(
                size: 250,
                color: AppColors.accent.withAlpha(50),
              ),
            ),

            // Center content
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo Icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(15),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withAlpha(40),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: MsLogo.icon(height: 72),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // App Name
                      const Text(
                        'MediShare',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Smart Medical Equipment Network',
                        style: TextStyle(
                          color: Colors.white.withAlpha(150),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.3,
                        ),
                      ),

                      const SizedBox(height: 60),

                      // Loading indicator
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.accent.withAlpha(200),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Version tag bottom
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'v1.0.0',
                  style: TextStyle(
                    color: Colors.white.withAlpha(80),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;

  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}