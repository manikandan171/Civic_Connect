import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';
import 'user_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserService _userService = UserService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Phone Authentication
  Future<String?> sendOTP(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          throw Exception('Verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          // Store verification ID for later use
          _storeVerificationId(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _storeVerificationId(verificationId);
        },
        timeout: const Duration(seconds: 60),
      );
      return 'OTP sent successfully';
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  Future<UserModel?> verifyOTP(String otp) async {
    try {
      final verificationId = await _getStoredVerificationId();
      if (verificationId == null) {
        throw Exception('No verification ID found');
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
        final userModel = await _createUserModel(user, isNewUser: isNewUser);
        
        // Store user data in Firestore
        await _userService.createOrUpdateUser(userModel);
        
        return userModel;
      }
      return null;
    } catch (e) {
      throw Exception('OTP verification failed: $e');
    }
  }

  // Email Authentication
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final userModel = await _createUserModel(userCredential.user!);
      
      // Store/update user data in Firestore
      await _userService.createOrUpdateUser(userModel);
      
      return userModel;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  Future<UserModel?> signUpWithEmail(String email, String password, String name) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user!.updateDisplayName(name);

      final userModel = await _createUserModel(userCredential.user!, isNewUser: true);
      
      // Store user data in Firestore
      await _userService.createOrUpdateUser(userModel);
      
      return userModel;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Google Sign In
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;
      
      // Update display name from Google account if not set
      if (user.displayName == null || user.displayName!.isEmpty) {
        await user.updateDisplayName(googleUser.displayName ?? googleUser.email.split('@')[0]);
      }
      
      // Create user model with Google account info
      final userModel = UserModel(
        id: user.uid,
        name: googleUser.displayName ?? user.displayName ?? googleUser.email.split('@')[0],
        email: user.email ?? googleUser.email,
        phone: user.phoneNumber ?? '',
        profileImage: user.photoURL ?? googleUser.photoUrl,
        createdAt: user.metadata.creationTime ?? DateTime.now(),
        isGuest: false,
      );
      
      // Store user data locally and in Firestore
      await _storeUserData(userModel);
      await _userService.createOrUpdateUser(userModel);
      
      return userModel;
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  // Guest Mode
  Future<UserModel> signInAsGuest() async {
    try {
      final user = UserModel(
        id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Guest User',
        email: 'guest@example.com',
        phone: '',
        createdAt: DateTime.now(),
        isGuest: true,
      );

      await _storeUserData(user);
      return user;
    } catch (e) {
      throw Exception('Guest sign in failed: $e');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      await _clearStoredData();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Get Current User
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // User is authenticated with Firebase
        // Try to get user data from Firestore first
        final firestoreUser = await _userService.getUserById(user.uid);
        if (firestoreUser != null) {
          // Store the latest data locally
          await _storeUserData(firestoreUser);
          return firestoreUser;
        }
        // Fallback to creating from Firebase Auth user
        final userModel = await _createUserModel(user);
        return userModel;
      } else {
        // No Firebase user, check for guest user in local storage
        final storedUser = await _getStoredUserData();
        if (storedUser != null && storedUser.isGuest) {
          return storedUser;
        }
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Update User Profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _storeUserData(user);
      if (!user.isGuest && _auth.currentUser != null) {
        await _auth.currentUser!.updateDisplayName(user.name);
        await _auth.currentUser!.verifyBeforeUpdateEmail(user.email);
      }
    } catch (e) {
      throw Exception('Profile update failed: $e');
    }
  }

  // Private Helper Methods
  Future<UserModel> _createUserModel(User user, {bool isNewUser = false}) async {
    // If user exists in Firestore and it's not a new user, get existing data
    if (!isNewUser) {
      final existingUser = await _userService.getUserById(user.uid);
      if (existingUser != null) {
        return existingUser;
      }
    }
    
    final userModel = UserModel(
      id: user.uid,
      name: user.displayName ?? user.email?.split('@')[0] ?? 'User',
      email: user.email ?? '',
      phone: user.phoneNumber ?? '',
      profileImage: user.photoURL,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      isGuest: false,
    );

    await _storeUserData(userModel);
    return userModel;
  }

  Future<void> _storeUserData(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = user.toJson();
    final jsonString = jsonEncode(userJson);
    await prefs.setString(AppConstants.userDataKey, jsonString);
  }

  Future<UserModel?> _getStoredUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(AppConstants.userDataKey);
      if (userData != null && userData.isNotEmpty) {
        final Map<String, dynamic> userMap = jsonDecode(userData);
        return UserModel.fromJson(userMap);
      }
      return null;
    } catch (e) {
      print('Error parsing stored user data: $e');
      return null;
    }
  }

  Future<void> _storeVerificationId(String verificationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('verification_id', verificationId);
  }

  Future<String?> _getStoredVerificationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('verification_id');
  }

  Future<void> _clearStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userDataKey);
    await prefs.remove('verification_id');
  }
}
