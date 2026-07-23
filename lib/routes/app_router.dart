import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/home/home_screen.dart';

/// Named route constants
class AppRoutes {
  AppRoutes._();
  static const String splash     = '/';
  static const String onboarding = '/onboarding';
  static const String login      = '/login';
  static const String register   = '/register';
  static const String home       = '/home';
}

/// App-wide GoRouter configuration
class AppRouter {
  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: authProvider,
      redirect: (BuildContext context, GoRouterState state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoading       = authProvider.isLoading;
        final loc             = state.uri.path;

        // Don't redirect while loading
        if (isLoading) return null;

        // Auth pages
        final isAuthPage = loc == AppRoutes.login || loc == AppRoutes.register;

        if (isAuthenticated && isAuthPage) {
          return AppRoutes.home;
        }
        if (!isAuthenticated && loc == AppRoutes.home) {
          return AppRoutes.login;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          name: 'onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.register,
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: AppRoutes.home,
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
      ],
    );
  }
}
