import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;
  bool get isGuest => _currentUser?.isGuest ?? false;

  AuthProvider() {
    _initializeAuth();
  }

  /// Initialize authentication state
  void _initializeAuth() {
    // First, try to load stored user data immediately
    _loadStoredUserData();

    // Listen to Firebase Auth state changes
    _authService.authStateChanges.listen((User? user) async {
      debugPrint('🔄 Auth state changed: ${user?.email ?? 'null'}');
      if (user != null) {
        await _loadCurrentUser();
      } else {
        // Check for stored user data before setting unauthenticated
        final storedUser = await _authService.getCurrentUser();
        if (storedUser != null && !storedUser.isGuest) {
          debugPrint(
            '🔄 Found stored user, keeping authenticated: ${storedUser.email}',
          );
          _setUser(storedUser);
        } else {
          // Only set unauthenticated if we don't have a current user
          if (_currentUser == null) {
            _setUnauthenticated();
          }
        }
      }
    });
  }

  /// Load stored user data immediately on app start
  Future<void> _loadStoredUserData() async {
    try {
      _setLoading(true);
      final storedUser = await _authService.getCurrentUser();
      if (storedUser != null && !storedUser.isGuest) {
        debugPrint('🔄 App startup: Found stored user: ${storedUser.email}');
        _setUser(storedUser);
        return;
      }
      debugPrint('🔄 App startup: No stored user found');
    } catch (e) {
      debugPrint('❌ Error loading stored user: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load current user data
  Future<void> _loadCurrentUser() async {
    try {
      _setLoading(true);
      final user = await _authService.getCurrentUser();
      debugPrint('🔍 Loading current user: ${user?.toString()}');
      if (user != null) {
        debugPrint(
          '✅ User loaded: ${user.name} (${user.email}) - Guest: ${user.isGuest}',
        );
        _setUser(user);
      } else {
        debugPrint('❌ No user found, setting unauthenticated');
        _setUnauthenticated();
      }
    } catch (e) {
      debugPrint('❌ Error loading user: $e');
      _setError('Failed to load user: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();

      final user = await _authService.signInWithGoogle();
      if (user != null) {
        _setUser(user);
        debugPrint(
          '✅ Google Sign-In Successful: ${user.name} (${user.email}) - Guest: ${user.isGuest}',
        );

        // Force refresh to ensure UI updates
        await Future.delayed(const Duration(milliseconds: 500));
        await forceRefreshUser();

        return true;
      }
      debugPrint('❌ Google Sign-In returned null user');
      return false;
    } catch (e) {
      debugPrint('❌ Google Sign-In Error: $e');
      _setError('Google sign in failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      final user = await _authService.signInWithEmail(email, password);
      if (user != null) {
        _setUser(user);
        return true;
      }
      return false;
    } catch (e) {
      _setError('Email sign in failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign up with email and password
  Future<bool> signUpWithEmail(
    String email,
    String password,
    String name,
    String phone,
  ) async {
    try {
      _setLoading(true);
      _clearError();

      final user = await _authService.signUpWithEmail(email, password, name);
      if (user != null) {
        _setUser(user);
        return true;
      }
      return false;
    } catch (e) {
      _setError('Email sign up failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with phone number
  Future<bool> signInWithPhone(
    String phoneNumber,
    String verificationCode,
  ) async {
    try {
      _setLoading(true);
      _clearError();

      // This would need to be implemented in AuthService
      // For now, return false
      _setError('Phone authentication not implemented yet');
      return false;
    } catch (e) {
      _setError('Phone sign in failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in as guest
  Future<bool> signInAsGuest() async {
    try {
      _setLoading(true);
      _clearError();

      final user = await _authService.signInAsGuest();
      _setUser(user);
      return true;
    } catch (e) {
      _setError('Guest sign in failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Secure sign out with data clearing
  Future<void> signOut() async {
    try {
      _setLoading(true);

      // Clear user data first
      _setUser(null);
      _clearError();

      // Sign out from Firebase
      await _authService.signOut();

      // Clear all local data and cache
      await _clearAllLocalData();

      debugPrint('✅ User signed out and all data cleared');
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      _setError('Sign out failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Clear all local data and cache
  Future<void> _clearAllLocalData() async {
    try {
      // Preserve onboarding status when signing out
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

      // Clear all data
      await prefs.clear();

      // Restore onboarding status
      await prefs.setBool('has_seen_onboarding', hasSeenOnboarding);

      debugPrint('✅ All local data cleared (onboarding status preserved)');
    } catch (e) {
      debugPrint('❌ Error clearing local data: $e');
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile(UserModel updatedUser) async {
    try {
      _setLoading(true);
      _clearError();
      await _authService.updateUserProfile(updatedUser);
      _setUser(updatedUser);
      return true;
    } catch (e) {
      _setError('Profile update failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh current user data
  Future<void> refreshUser() async {
    await _loadCurrentUser();
  }

  /// Force refresh user data (clears cache)
  Future<void> forceRefreshUser() async {
    try {
      _setLoading(true);

      // Clear any cached guest data
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      if (userData != null) {
        // Check if it's guest data and clear it
        try {
          final Map<String, dynamic> userMap = jsonDecode(userData);
          if (userMap['isGuest'] == true) {
            await prefs.remove('user_data');
            debugPrint('🧹 Cleared guest user data');
          }
        } catch (e) {
          // If parsing fails, clear anyway
          await prefs.remove('user_data');
        }
      }

      // Force reload from Firebase
      await _loadCurrentUser();
    } finally {
      _setLoading(false);
    }
  }

  // Private helper methods
  void _setUser(UserModel? user) {
    _currentUser = user;
    _isAuthenticated = user != null;
    _errorMessage = null;
    notifyListeners();
  }

  void _setUnauthenticated() {
    _currentUser = null;
    _isAuthenticated = false;
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _clearError();
  }
}
