import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collections
  static const String _usersCollection = 'users';

  /// Create or update user in Firestore
  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      await _firestore.collection(_usersCollection).doc(user.id).set(
        user.toJson(),
        SetOptions(merge: true),
      );
      debugPrint('User data stored in Firestore: ${user.id}');
    } catch (e) {
      debugPrint('Error storing user in Firestore: $e');
      throw Exception('Failed to store user data: $e');
    }
  }

  /// Get user by ID from Firestore
  Future<UserModel?> getUserById(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user by ID: $e');
      return null;
    }
  }

  /// Get user by email from Firestore
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        return UserModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user by email: $e');
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore.collection(_usersCollection).doc(user.id).update({
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
        'profileImage': user.profileImage,
        'preferredLanguage': user.preferredLanguage,
        'notificationsEnabled': user.notificationsEnabled,
      });
      debugPrint('User profile updated: ${user.id}');
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Update user statistics (issues reported/resolved, points)
  Future<void> updateUserStats(String userId, {
    int? issuesReported,
    int? issuesResolved,
    int? points,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      
      if (issuesReported != null) {
        updates['issuesReported'] = FieldValue.increment(issuesReported);
      }
      if (issuesResolved != null) {
        updates['issuesResolved'] = FieldValue.increment(issuesResolved);
      }
      if (points != null) {
        updates['points'] = FieldValue.increment(points);
      }

      if (updates.isNotEmpty) {
        await _firestore.collection(_usersCollection).doc(userId).update(updates);
        debugPrint('User stats updated: $userId');
      }
    } catch (e) {
      debugPrint('Error updating user stats: $e');
      throw Exception('Failed to update user stats: $e');
    }
  }

  /// Delete user account
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).delete();
      debugPrint('User deleted: $userId');
    } catch (e) {
      debugPrint('Error deleting user: $e');
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Get top users for leaderboard
  Future<List<UserModel>> getTopUsers({int limit = 10}) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_usersCollection)
          .where('isGuest', isEqualTo: false)
          .orderBy('points', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting top users: $e');
      return [];
    }
  }

  /// Listen to user data changes
  Stream<UserModel?> listenToUser(String userId) {
    try {
      return _firestore
          .collection(_usersCollection)
          .doc(userId)
          .snapshots()
          .map((doc) {
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          return UserModel.fromJson(data);
        }
        return null;
      });
    } catch (e) {
      debugPrint('Error listening to user: $e');
      return Stream.value(null);
    }
  }

  /// Check if user exists
  Future<bool> userExists(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking if user exists: $e');
      return false;
    }
  }

  /// Get users count
  Future<int> getUsersCount() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_usersCollection)
          .where('isGuest', isEqualTo: false)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting users count: $e');
      return 0;
    }
  }
}
