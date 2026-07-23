import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/widgets/ms_button.dart';
import '../../shared/widgets/ms_logo.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  late AnimationController _animController;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      emoji: '🏥',
      gradient: [Color(0xFF3B6CF8), Color(0xFF2855D8)],
      title: 'Donate Medical\nEquipment',
      subtitle:
          'Help hospitals and NGOs by donating unused medical equipment that could save lives.',
    ),
    _OnboardingData(
      emoji: '🤝',
      gradient: [Color(0xFF2ECFB3), Color(0xFF22A892)],
      title: 'Connect with\nHealthcare',
      subtitle:
          'Find donors and recipients quickly across your city. Build a stronger healthcare network.',
    ),
    _OnboardingData(
      emoji: '❤️',
      gradient: [Color(0xFF141929), Color(0xFF1E2640)],
      title: 'Save Lives\nTogether',
      subtitle:
          'Join thousands on MediShare and be part of the movement to make healthcare more accessible.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animController.forward();
  }

  void _nextPage() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _getStarted();
    }
  }

  Future<void> _getStarted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _onPageChanged(int index) {
    _animController.reset();
    setState(() => _currentIndex = index);
    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentIndex];
    final isLast = _currentIndex == _pages.length - 1;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: page.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top Bar ───────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MsLogo(height: 28, color: Colors.white),
                    TextButton(
                      onPressed: _getStarted,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Page Content ──────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    return _OnboardingPage(data: _pages[index]);
                  },
                ),
              ),

              // ── Dots ──────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == i ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == i
                          ? Colors.white
                          : Colors.white.withAlpha(80),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── CTA Button ────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: MsButton(
                  label: isLast ? 'Get Started' : 'Next',
                  onPressed: _nextPage,
                  backgroundColor: Colors.white,
                  foregroundColor: page.gradient.first,
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji in circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withAlpha(50),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                data.emoji,
                style: const TextStyle(fontSize: 60),
              ),
            ),
          ),

          const SizedBox(height: 48),

          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 16,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final String emoji;
  final List<Color> gradient;
  final String title;
  final String subtitle;

  const _OnboardingData({
    required this.emoji,
    required this.gradient,
    required this.title,
    required this.subtitle,
  });
}