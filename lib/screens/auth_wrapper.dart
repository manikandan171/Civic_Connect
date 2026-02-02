import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'onboarding_screen.dart';
import 'home/home_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasSeenOnboarding = false;
  bool _isCheckingOnboarding = true;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

      if (mounted) {
        setState(() {
          _hasSeenOnboarding = hasSeenOnboarding;
          _isCheckingOnboarding = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
      if (mounted) {
        setState(() {
          _isCheckingOnboarding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading while checking authentication or onboarding state
        if (authProvider.isLoading || _isCheckingOnboarding) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is authenticated
        if (authProvider.isAuthenticated) {
          // If they haven't seen onboarding, show it
          if (!_hasSeenOnboarding) {
            return const OnboardingScreen();
          }
          // If they have seen onboarding, go directly to home
          return const HomeScreen();
        }

        // If not authenticated, show login screen
        return const LoginScreen();
      },
    );
  }
}
