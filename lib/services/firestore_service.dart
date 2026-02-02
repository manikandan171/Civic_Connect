import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:math' as math;
import '../models/issue_model.dart';
import '../models/map_location.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Initialize Firestore with better settings
  void initializeFirestore() {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Collections
  static const String _issuesCollection = 'issues';
  static const String _updatesCollection = 'updates';

  // Get all PUBLIC issues from Firestore (for public viewing only)
  Future<List<IssueModel>> getPublicIssues() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_issuesCollection)
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _issueFromFirestore(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting public issues: $e');
      return [];
    }
  }

  // Get user's issues by category
  Future<List<IssueModel>> getUserIssuesByCategory(String userId, String category) async {
    try {
      Query query = _firestore
          .collection(_issuesCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      if (category != 'all') {
        query = query.where('category', isEqualTo: category);
      }

      final QuerySnapshot snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _issueFromFirestore(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting user issues by category: $e');
      return [];
    }
  }

  // Get user's filtered issues
  Future<List<IssueModel>> getUserFilteredIssues(String userId, {
    String category = 'all',
    String status = 'all',
  }) async {
    try {
      Query query = _firestore
          .collection(_issuesCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      if (category != 'all') {
        query = query.where('category', isEqualTo: category);
      }

      if (status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      final QuerySnapshot snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _issueFromFirestore(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting user filtered issues: $e');
      return [];
    }
  }

  // Store issue in Firestore with encrypted images
  Future<void> storeIssue(IssueModel issue, {List<Map<String, dynamic>>? encryptedImages}) async {
    try {
      debugPrint('🔄 Storing issue in Firestore...');
      debugPrint('📄 Issue ID: ${issue.id}');
      debugPrint('📄 Issue Title: ${issue.title}');
      debugPrint('📄 Issue UserID: ${issue.userId}');
      debugPrint('📄 Issue UserName: ${issue.userName}');
      debugPrint('📄 Issue Status: ${issue.status.toString().split('.').last}');
      debugPrint('📄 Encrypted Images: ${encryptedImages?.length ?? 0}');
      
      // Log encrypted images info
      if (encryptedImages != null && encryptedImages.isNotEmpty) {
        for (int i = 0; i < encryptedImages.length; i++) {
          final imageData = encryptedImages[i];
          debugPrint('📄 Encrypted Image ${i + 1}: ID=${imageData['id']}, Size=${imageData['originalSize']} bytes');
        }
      }
      
      // Prepare the data for Firestore
      final issueData = {
        'id': issue.id,
        'title': issue.title.trim(),
        'description': issue.description.trim(),
        'category': issue.category,
        'categoryName': issue.categoryName,
        'categoryIcon': issue.categoryIcon,
        'status': issue.status.toString().split('.').last,
        'priority': issue.priority.toString().split('.').last,
        'userId': issue.userId,
        'userName': issue.userName,
        'userPhone': issue.userPhone,
        'userEmail': issue.userEmail,
        'imageUrls': issue.imageUrls, // Legacy field for compatibility
        'encryptedImages': encryptedImages ?? [], // Encrypted Base64 images stored directly
        'videoUrl': issue.videoUrl,
        'location': {
          'latitude': issue.location.latitude,
          'longitude': issue.location.longitude,
        },
        'address': issue.address,
        'department': issue.department,
        'createdAt': Timestamp.fromDate(issue.createdAt),
        'updatedAt': Timestamp.fromDate(issue.updatedAt ?? DateTime.now()),
        'resolvedAt': issue.resolvedAt != null ? Timestamp.fromDate(issue.resolvedAt!) : null,
        'resolutionNotes': issue.resolutionNotes,
        'assignedTo': issue.assignedTo,
        'assignedToName': issue.assignedToName,
        'upvotes': issue.upvotes,
        'downvotes': issue.downvotes,
        'isPublic': issue.isPublic,
        'complaintId': issue.complaintId,
        // Additional metadata for encrypted images
        'hasEncryptedImages': (encryptedImages?.isNotEmpty ?? false) || issue.imageUrls.isNotEmpty,
        'imageCount': (encryptedImages?.length ?? 0) + issue.imageUrls.length,
        'encryptionVersion': 'AES-256-Firebase-v1',
        'submissionTimestamp': FieldValue.serverTimestamp(),
      };
      
      debugPrint('💾 Writing to Firestore collection: $_issuesCollection');
      debugPrint('💾 Document ID: ${issue.id}');
      
      await _firestore.collection(_issuesCollection).doc(issue.id).set(issueData);
      
      debugPrint('✅ Issue stored in Firestore successfully: ${issue.id}');
      debugPrint('✅ Stored with UserID: ${issue.userId}');
      debugPrint('✅ Stored ${encryptedImages?.length ?? 0} encrypted images and ${issue.imageUrls.length} legacy URLs');
      
      // Verify the issue was stored by trying to read it back
      final doc = await _firestore.collection(_issuesCollection).doc(issue.id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('✅ Verification: Issue exists in DB with UserID: ${data['userId']}');
      } else {
        debugPrint('❌ Verification failed: Issue not found in DB');
      }
    } catch (e) {
      debugPrint('❌ Error storing issue in Firestore: $e');
      debugPrint('📄 Failed issue ID: ${issue.id}');
      debugPrint('📄 Failed user ID: ${issue.userId}');
      throw Exception('Failed to store issue: $e');
    }
  }

  /// Verify Firestore connectivity and permissions
  Future<bool> testFirestoreConnection() async {
    try {
      debugPrint('🔥 Testing Firestore connectivity...');
      
      // Try to read from the issues collection
      final testQuery = await _firestore.collection(_issuesCollection).limit(1).get();
      
      debugPrint('✅ Firestore connectivity verified');
      debugPrint('📄 Collection accessible, found ${testQuery.docs.length} sample documents');
      
      return true;
    } catch (e) {
      debugPrint('❌ Firestore connectivity test failed: $e');
      debugPrint('📄 This might be a Firestore Security Rules issue');
      return false;
    }
  }


  // Get user's issues
  Future<List<IssueModel>> getUserIssues(String userId) async {
    try {
      debugPrint('🔍 FirestoreService: Getting issues for userId: $userId');
      
      // Temporary fix: Remove orderBy to avoid index requirement
      final QuerySnapshot snapshot = await _firestore
          .collection(_issuesCollection)
          .where('userId', isEqualTo: userId)
          .get();

      debugPrint('📋 FirestoreService: Found ${snapshot.docs.length} documents');
      
      final issues = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('📄 Document data: ${data.keys.toList()}');
        return _issueFromFirestore(data);
      }).toList();
      
      // Sort by createdAt descending (client-side sorting)
      issues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      debugPrint('✅ FirestoreService: Converted to ${issues.length} IssueModel objects');
      
      // If no issues found, let's debug further
      if (issues.isEmpty) {
        debugPrint('🔍 No issues found for user $userId, checking all issues...');
        await _debugAllIssues();
      }
      
      return issues;
    } catch (e) {
      debugPrint('❌ Error getting user issues: $e');
      return [];
    }
  }

  /// Debug method to check all issues in database
  Future<void> _debugAllIssues() async {
    try {
      final QuerySnapshot allSnapshot = await _firestore
          .collection(_issuesCollection)
          .limit(10)
          .get();
      
      debugPrint('🔍 DEBUG: Total issues in database: ${allSnapshot.docs.length}');
      
      for (int i = 0; i < allSnapshot.docs.length; i++) {
        final data = allSnapshot.docs[i].data() as Map<String, dynamic>;
        debugPrint('🔍 Issue $i: UserID=${data['userId']}, Title=${data['title']}, Status=${data['status']}');
      }
    } catch (e) {
      debugPrint('❌ Error in debug all issues: $e');
    }
  }

  // Get user's issues by status
  Future<List<IssueModel>> getUserIssuesByStatus(String userId, String status) async {
    try {
      Query query = _firestore
          .collection(_issuesCollection)
          .where('userId', isEqualTo: userId);

      if (status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      final QuerySnapshot snapshot = await query.get();

      final issues = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _issueFromFirestore(data);
      }).toList();
      
      // Sort by createdAt descending (client-side sorting)
      issues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return issues;
    } catch (e) {
      debugPrint('Error getting user issues by status: $e');
      return [];
    }
  }

  // Listen to user's issues in real-time
  Stream<List<IssueModel>> listenToUserIssues(String userId, {String status = 'all'}) {
    try {
      Query query = _firestore
          .collection(_issuesCollection)
          .where('userId', isEqualTo: userId);

      if (status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      return query.snapshots().map((snapshot) {
        final issues = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _issueFromFirestore(data);
        }).toList();
        
        // Sort by createdAt descending (client-side sorting)
        issues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        return issues;
      });
    } catch (e) {
      debugPrint('Error listening to user issues: $e');
      return Stream.value([]);
    }
  }

  // Get user statistics
  Future<Map<String, int>> getUserIssueStats(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_issuesCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final Map<String, int> stats = {
        'total': 0,
        'submitted': 0,
        'acknowledged': 0,
        'inProgress': 0,
        'resolved': 0,
        'rejected': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String? ?? 'submitted';
        
        stats['total'] = (stats['total'] ?? 0) + 1;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      debugPrint('Error getting user issue stats: $e');
      return {
        'total': 0,
        'submitted': 0,
        'acknowledged': 0,
        'inProgress': 0,
        'resolved': 0,
        'rejected': 0,
      };
    }
  }

  // Get issue by ID
  Future<IssueModel?> getIssueById(String issueId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_issuesCollection)
          .doc(issueId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return _issueFromFirestore(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting issue by ID: $e');
      return null;
    }
  }

  // Update issue status
  Future<void> updateIssueStatus(String issueId, IssueStatus status, String notes) async {
    try {
      await _firestore.collection(_issuesCollection).doc(issueId).update({
        'status': status.toString().split('.').last,
        'updatedAt': DateTime.now(),
        'resolutionNotes': notes,
        if (status == IssueStatus.resolved) 'resolvedAt': DateTime.now(),
      });
      
      debugPrint('Issue status updated: $issueId -> ${status.toString().split('.').last}');
    } catch (e) {
      debugPrint('Error updating issue status: $e');
      throw Exception('Failed to update issue status: $e');
    }
  }

  // Upload image to Firebase Storage
  Future<String> uploadImage(File imageFile, String issueId) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final Reference ref = _storage.ref().child('issues/$issueId/images/$fileName');
      
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('Image uploaded: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // Upload multiple images
  Future<List<String>> uploadImages(List<File> imageFiles, String issueId) async {
    final List<String> imageUrls = [];
    
    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final String url = await uploadImage(imageFiles[i], issueId);
        imageUrls.add(url);
      } catch (e) {
        debugPrint('Failed to upload image ${i + 1}: $e');
        // Continue with other images even if one fails
      }
    }
    
    return imageUrls;
  }


  // Get issues near location
  Future<List<IssueModel>> getIssuesNearLocation(double latitude, double longitude, double radiusKm) async {
    try {
      // Note: For production, you'd want to use geohash or GeoFlutterFire for efficient geo queries
      // For now, we'll get all issues and filter client-side (not efficient for large datasets)
      final QuerySnapshot snapshot = await _firestore
          .collection(_issuesCollection)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _issueFromFirestore(data);
      }).where((issue) {
        final double distance = _calculateDistance(
          latitude,
          longitude,
          issue.location.latitude,
          issue.location.longitude,
        );
        return distance <= radiusKm;
      }).toList();
    } catch (e) {
      debugPrint('Error getting issues near location: $e');
      return [];
    }
  }

  // Delete issue
  Future<void> deleteIssue(String issueId) async {
    try {
      await _firestore.collection(_issuesCollection).doc(issueId).delete();
      debugPrint('Issue deleted: $issueId');
    } catch (e) {
      debugPrint('Error deleting issue: $e');
      throw Exception('Failed to delete issue: $e');
    }
  }

  // Add issue update
  Future<void> addIssueUpdate(String issueId, IssueUpdate update) async {
    try {
      await _firestore
          .collection(_issuesCollection)
          .doc(issueId)
          .collection(_updatesCollection)
          .doc(update.id)
          .set({
        'id': update.id,
        'issueId': update.issueId,
        'message': update.message,
        'updatedBy': update.updatedBy,
        'updatedByName': update.updatedByName,
        'updatedAt': update.updatedAt,
      });
      
      debugPrint('Issue update added: ${update.id}');
    } catch (e) {
      debugPrint('Error adding issue update: $e');
      throw Exception('Failed to add issue update: $e');
    }
  }

  // Get issue updates
  Future<List<IssueUpdate>> getIssueUpdates(String issueId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_issuesCollection)
          .doc(issueId)
          .collection(_updatesCollection)
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return IssueUpdate(
          id: data['id'],
          issueId: data['issueId'],
          message: data['message'],
          updatedBy: data['updatedBy'],
          updatedByName: data['updatedByName'],
          updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting issue updates: $e');
      return [];
    }
  }

  // Helper method to convert Firestore data to IssueModel
  IssueModel _issueFromFirestore(Map<String, dynamic> data) {
    return IssueModel(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      categoryName: data['categoryName'] ?? '',
      categoryIcon: data['categoryIcon'] ?? '📍',
      status: IssueStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => IssueStatus.submitted,
      ),
      priority: IssuePriority.values.firstWhere(
        (e) => e.toString().split('.').last == data['priority'],
        orElse: () => IssuePriority.medium,
      ),
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhone: data['userPhone'],
      userEmail: data['userEmail'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      encryptedImages: data['encryptedImages'] != null 
          ? List<Map<String, dynamic>>.from(data['encryptedImages'])
          : null,
      videoUrl: data['videoUrl'],
      location: MapLocation(
        (data['location']?['latitude'] ?? 0.0).toDouble(),
        (data['location']?['longitude'] ?? 0.0).toDouble(),
      ),
      address: data['address'] ?? '',
      department: data['department'],
      createdAt: _parseTimestamp(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(data['updatedAt']),
      resolvedAt: _parseTimestamp(data['resolvedAt']),
      resolutionNotes: data['resolutionNotes'],
      assignedTo: data['assignedTo'],
      assignedToName: data['assignedToName'],
      upvotes: data['upvotes'] ?? 0,
      downvotes: data['downvotes'] ?? 0,
      isPublic: data['isPublic'] ?? true,
      complaintId: data['complaintId'] ?? '',
      updates: [], // Updates would be loaded separately
    );
  }

  // Helper method to safely parse timestamps
  DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        debugPrint('Error parsing timestamp string: $e');
        return null;
      }
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    
    return null;
  }

  // Helper method to calculate distance between two points
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Haversine formula for calculating distance between two points on Earth
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.asin(math.sqrt(a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}
