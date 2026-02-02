import 'dart:io';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../models/map_location.dart';
import '../models/issue_model.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';
import 'firestore_service.dart';

class IssueService {
  static final IssueService _instance = IssueService._internal();
  factory IssueService() => _instance;
  IssueService._internal();

  final Dio _dio = Dio();
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();
  final Uuid _uuid = const Uuid();

  // Report a new issue
  Future<IssueModel> reportIssue({
    required String title,
    required String description,
    required String category,
    required String categoryName,
    required String categoryIcon,
    required double latitude,
    required double longitude,
    required String address,
    required List<File> images,
    File? video,
    required String userId,
    required String userName,
  }) async {
    try {
      // Generate unique ID
      final issueId = _uuid.v4();
      final complaintId = _generateComplaintId();

      // Upload media files
      final imageUrls = await _uploadImages(images);
      final videoUrl = video != null ? await _uploadVideo(video) : null;

      // Create issue model
      final issue = IssueModel(
        id: issueId,
        title: title,
        description: description,
        category: category,
        categoryName: categoryName,
        categoryIcon: categoryIcon,
        status: IssueStatus.submitted,
        priority: _getPriorityFromCategory(category),
        userId: userId,
        userName: userName,
        location: MapLocation(latitude, longitude),
        address: address,
        createdAt: DateTime.now(),
        imageUrls: imageUrls,
        videoUrl: videoUrl,
        complaintId: complaintId,
      );

      // Save to local storage first (offline support)
      await _storageService.saveIssue(issue);

      // Store in Firestore
      try {
        await _firestoreService.storeIssue(issue);
        print('Issue stored in Firestore successfully: ${issue.id}');
      } catch (e) {
        print('Failed to store in Firestore, will retry later: $e');
        // If Firestore fails, mark for later sync
        await _storageService.markIssueForSync(issueId);
      }

      return issue;
    } catch (e) {
      throw Exception('Failed to report issue: $e');
    }
  }

  // Get user's issues
  Future<List<IssueModel>> getUserIssues(String userId) async {
    try {
      // First try to get from server
      try {
        final response = await _dio.get(
          '${AppConstants.baseUrl}${AppConstants.getIssuesEndpoint}',
          queryParameters: {'userId': userId},
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = response.data['issues'];
          return data.map((json) => IssueModel.fromJson(json)).toList();
        }
      } catch (e) {
        // If server fails, get from local storage
        return await _storageService.getUserIssues(userId);
      }

      return await _storageService.getUserIssues(userId);
    } catch (e) {
      throw Exception('Failed to get user issues: $e');
    }
  }

  // Get all issues (for map view)
  Future<List<IssueModel>> getAllIssues({
    String? category,
    String? status,
    double? latitude,
    double? longitude,
    double? radius,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (status != null) queryParams['status'] = status;
      if (latitude != null) queryParams['latitude'] = latitude;
      if (longitude != null) queryParams['longitude'] = longitude;
      if (radius != null) queryParams['radius'] = radius;

      final response = await _dio.get(
        '${AppConstants.baseUrl}${AppConstants.getIssuesEndpoint}',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['issues'];
        return data.map((json) => IssueModel.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      // Return cached issues if server fails
      return await _storageService.getAllIssues();
    }
  }

  // Get issue by ID
  Future<IssueModel?> getIssueById(String issueId) async {
    try {
      final response = await _dio.get(
        '${AppConstants.baseUrl}${AppConstants.getIssuesEndpoint}/$issueId',
      );

      if (response.statusCode == 200) {
        return IssueModel.fromJson(response.data);
      }

      return null;
    } catch (e) {
      // Try local storage
      return await _storageService.getIssueById(issueId);
    }
  }

  // Update issue status
  Future<void> updateIssueStatus(
    String issueId,
    IssueStatus status,
    String notes,
  ) async {
    try {
      await _dio.put(
        '${AppConstants.baseUrl}${AppConstants.updateIssueEndpoint}/$issueId',
        data: {
          'status': status.toString().split('.').last,
          'notes': notes,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      // Update local storage
      await _storageService.updateIssueStatus(issueId, status, notes);
    } catch (e) {
      throw Exception('Failed to update issue status: $e');
    }
  }

  // Add issue update
  Future<void> addIssueUpdate(
    String issueId,
    String message,
    String updatedBy,
    String updatedByName,
  ) async {
    try {
      final update = IssueUpdate(
        id: _uuid.v4(),
        issueId: issueId,
        message: message,
        updatedBy: updatedBy,
        updatedByName: updatedByName,
        updatedAt: DateTime.now(),
      );

      await _dio.post(
        '${AppConstants.baseUrl}${AppConstants.updateIssueEndpoint}/$issueId/updates',
        data: update.toJson(),
      );

      // Update local storage
      await _storageService.addIssueUpdate(issueId, update);
    } catch (e) {
      throw Exception('Failed to add issue update: $e');
    }
  }

  // Sync pending issues
  Future<void> syncPendingIssues() async {
    try {
      final pendingIssues = await _storageService.getPendingSyncIssues();

      for (final issue in pendingIssues) {
        try {
          await _syncIssueToServer(issue);
          await _storageService.removePendingSyncIssue(issue.id);
        } catch (e) {
          // Keep issue in pending list for next sync attempt
        }
      }
    } catch (e) {
      throw Exception('Failed to sync pending issues: $e');
    }
  }

  // Upload images
  Future<List<String>> _uploadImages(List<File> images) async {
    final List<String> imageUrls = [];

    for (final image in images) {
      try {
        final formData = FormData.fromMap({
          'image': await MultipartFile.fromFile(image.path),
        });

        final response = await _dio.post(
          '${AppConstants.baseUrl}/api/upload/image',
          data: formData,
        );

        if (response.statusCode == 200) {
          imageUrls.add(response.data['url']);
        }
      } catch (e) {
        // If upload fails, store locally and mark for later upload
        final localUrl = await _storageService.storeImageLocally(image);
        imageUrls.add(localUrl);
      }
    }

    return imageUrls;
  }

  // Upload video
  Future<String> _uploadVideo(File video) async {
    try {
      final formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(video.path),
      });

      final response = await _dio.post(
        '${AppConstants.baseUrl}/api/upload/video',
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['url'];
      }

      throw Exception('Video upload failed');
    } catch (e) {
      // Store locally if upload fails
      return await _storageService.storeVideoLocally(video);
    }
  }

  // Sync issue to server
  Future<void> _syncIssueToServer(IssueModel issue) async {
    await _dio.post(
      '${AppConstants.baseUrl}${AppConstants.reportIssueEndpoint}',
      data: issue.toJson(),
    );
  }

  // Generate complaint ID
  String _generateComplaintId() {
    final now = DateTime.now();
    return 'CC${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.millisecondsSinceEpoch.toString().substring(8)}';
  }

  // Get priority from category
  IssuePriority _getPriorityFromCategory(String category) {
    final categoryData = AppConstants.issueCategories.firstWhere(
      (cat) => cat['id'] == category,
      orElse: () => {'priority': 'medium'},
    );

    switch (categoryData['priority']) {
      case 'high':
        return IssuePriority.high;
      case 'urgent':
        return IssuePriority.urgent;
      case 'low':
        return IssuePriority.low;
      default:
        return IssuePriority.medium;
    }
  }

  // Get issue statistics
  Future<Map<String, int>> getIssueStatistics(String userId) async {
    try {
      final response = await _dio.get(
        '${AppConstants.baseUrl}/api/statistics/issues',
        queryParameters: {'userId': userId},
      );

      if (response.statusCode == 200) {
        return Map<String, int>.from(response.data);
      }

      return {
        'total': 0,
        'submitted': 0,
        'acknowledged': 0,
        'inProgress': 0,
        'resolved': 0,
      };
    } catch (e) {
      // Return local statistics
      final issues = await _storageService.getUserIssues(userId);
      return {
        'total': issues.length,
        'submitted': issues
            .where((i) => i.status == IssueStatus.submitted)
            .length,
        'acknowledged': issues
            .where((i) => i.status == IssueStatus.acknowledged)
            .length,
        'inProgress': issues
            .where((i) => i.status == IssueStatus.inProgress)
            .length,
        'resolved': issues
            .where((i) => i.status == IssueStatus.resolved)
            .length,
      };
    }
  }
}
