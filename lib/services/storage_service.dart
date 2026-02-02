import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/map_location.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/issue_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Database? _database;

  // Initialize database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'sih_civic.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Issues table
    await db.execute('''
      CREATE TABLE issues (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        categoryName TEXT NOT NULL,
        categoryIcon TEXT NOT NULL,
        status TEXT NOT NULL,
        priority TEXT NOT NULL,
        userId TEXT NOT NULL,
        userName TEXT NOT NULL,
        userPhone TEXT,
        userEmail TEXT,
        imageUrls TEXT,
        videoUrl TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        address TEXT NOT NULL,
        department TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        resolvedAt TEXT,
        resolutionNotes TEXT,
        assignedTo TEXT,
        assignedToName TEXT,
        updates TEXT,
        upvotes INTEGER DEFAULT 0,
        downvotes INTEGER DEFAULT 0,
        isPublic INTEGER DEFAULT 1,
        complaintId TEXT,
        needsSync INTEGER DEFAULT 0
      )
    ''');

    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL,
        profileImage TEXT,
        createdAt TEXT NOT NULL,
        isGuest INTEGER DEFAULT 0,
        points INTEGER DEFAULT 0,
        issuesReported INTEGER DEFAULT 0,
        issuesResolved INTEGER DEFAULT 0,
        preferredLanguage TEXT DEFAULT 'en',
        notificationsEnabled INTEGER DEFAULT 1
      )
    ''');

    // Notifications table
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        isRead INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        issueId TEXT,
        actionUrl TEXT,
        metadata TEXT
      )
    ''');

    // Pending sync table
    await db.execute('''
      CREATE TABLE pending_sync (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        data TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // Issue operations
  Future<void> saveIssue(IssueModel issue) async {
    final db = await database;
    await db.insert(
      'issues',
      _issueToMap(issue),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<IssueModel>> getUserIssues(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'issues',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => _issueFromMap(map)).toList();
  }

  Future<List<IssueModel>> getAllIssues() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'issues',
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => _issueFromMap(map)).toList();
  }

  Future<IssueModel?> getIssueById(String issueId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'issues',
      where: 'id = ?',
      whereArgs: [issueId],
    );

    if (maps.isNotEmpty) {
      return _issueFromMap(maps.first);
    }
    return null;
  }

  Future<void> updateIssueStatus(
    String issueId,
    IssueStatus status,
    String notes,
  ) async {
    final db = await database;
    await db.update(
      'issues',
      {
        'status': status.toString().split('.').last,
        'resolutionNotes': notes,
        'updatedAt': DateTime.now().toIso8601String(),
        'needsSync': 1,
      },
      where: 'id = ?',
      whereArgs: [issueId],
    );
  }

  Future<void> addIssueUpdate(String issueId, IssueUpdate update) async {
    final db = await database;
    final issue = await getIssueById(issueId);
    if (issue != null) {
      final updatedUpdates = [...issue.updates, update];
      await db.update(
        'issues',
        {
          'updates': jsonEncode(updatedUpdates.map((u) => u.toJson()).toList()),
          'needsSync': 1,
        },
        where: 'id = ?',
        whereArgs: [issueId],
      );
    }
  }

  Future<List<IssueModel>> getPendingSyncIssues() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'issues',
      where: 'needsSync = ?',
      whereArgs: [1],
    );

    return maps.map((map) => _issueFromMap(map)).toList();
  }

  Future<void> markIssueForSync(String issueId) async {
    final db = await database;
    await db.update(
      'issues',
      {'needsSync': 1},
      where: 'id = ?',
      whereArgs: [issueId],
    );
  }

  Future<void> removePendingSyncIssue(String issueId) async {
    final db = await database;
    await db.update(
      'issues',
      {'needsSync': 0},
      where: 'id = ?',
      whereArgs: [issueId],
    );
  }

  // User operations
  Future<void> saveUser(UserModel user) async {
    final db = await database;
    await db.insert(
      'users',
      _userToMap(user),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> getUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return _userFromMap(maps.first);
    }
    return null;
  }

  // Notification operations
  Future<void> saveNotification(NotificationModel notification) async {
    final db = await database;
    await db.insert(
      'notifications',
      _notificationToMap(notification),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<NotificationModel>> getNotifications() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => _notificationFromMap(map)).toList();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final db = await database;
    await db.update(
      'notifications',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  Future<void> deleteNotification(String notificationId) async {
    final db = await database;
    await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  // File storage operations
  Future<String> storeImageLocally(File image) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final imagesDirectory = Directory('${documentsDirectory.path}/images');

    if (!await imagesDirectory.exists()) {
      await imagesDirectory.create(recursive: true);
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final newPath = '${imagesDirectory.path}/$fileName';

    await image.copy(newPath);
    return newPath;
  }

  Future<String> storeVideoLocally(File video) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final videosDirectory = Directory('${documentsDirectory.path}/videos');

    if (!await videosDirectory.exists()) {
      await videosDirectory.create(recursive: true);
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
    final newPath = '${videosDirectory.path}/$fileName';

    await video.copy(newPath);
    return newPath;
  }

  // Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('issues');
    await db.delete('users');
    await db.delete('notifications');
    await db.delete('pending_sync');
  }

  // Helper methods
  Map<String, dynamic> _issueToMap(IssueModel issue) {
    return {
      'id': issue.id,
      'title': issue.title,
      'description': issue.description,
      'category': issue.category,
      'categoryName': issue.categoryName,
      'categoryIcon': issue.categoryIcon,
      'status': issue.status.toString().split('.').last,
      'priority': issue.priority.toString().split('.').last,
      'userId': issue.userId,
      'userName': issue.userName,
      'userPhone': issue.userPhone,
      'userEmail': issue.userEmail,
      'imageUrls': jsonEncode(issue.imageUrls),
      'videoUrl': issue.videoUrl,
      'latitude': issue.location.latitude,
      'longitude': issue.location.longitude,
      'address': issue.address,
      'department': issue.department,
      'createdAt': issue.createdAt.toIso8601String(),
      'updatedAt': issue.updatedAt?.toIso8601String(),
      'resolvedAt': issue.resolvedAt?.toIso8601String(),
      'resolutionNotes': issue.resolutionNotes,
      'assignedTo': issue.assignedTo,
      'assignedToName': issue.assignedToName,
      'updates': jsonEncode(issue.updates.map((u) => u.toJson()).toList()),
      'upvotes': issue.upvotes,
      'downvotes': issue.downvotes,
      'isPublic': issue.isPublic ? 1 : 0,
      'complaintId': issue.complaintId,
    };
  }

  IssueModel _issueFromMap(Map<String, dynamic> map) {
    return IssueModel(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      category: map['category'],
      categoryName: map['categoryName'],
      categoryIcon: map['categoryIcon'],
      status: IssueStatus.values.firstWhere((e) => e.toString().split('.').last == map['status']),
      priority: IssuePriority.values.firstWhere(
        (e) => e.toString().split('.').last == map['priority'],
      ),
      userId: map['userId'],
      userName: map['userName'],
      userPhone: map['userPhone'],
      userEmail: map['userEmail'],
      imageUrls: List<String>.from(jsonDecode(map['imageUrls'] ?? '[]')),
      videoUrl: map['videoUrl'],
      location: MapLocation(map['latitude'], map['longitude']),
      address: map['address'],
      department: map['department'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
      resolvedAt: map['resolvedAt'] != null
          ? DateTime.parse(map['resolvedAt'])
          : null,
      resolutionNotes: map['resolutionNotes'],
      assignedTo: map['assignedTo'],
      assignedToName: map['assignedToName'],
      updates: (jsonDecode(map['updates'] ?? '[]') as List)
          .map((u) => IssueUpdate.fromJson(u))
          .toList(),
      upvotes: map['upvotes'],
      downvotes: map['downvotes'],
      isPublic: map['isPublic'] == 1,
      complaintId: map['complaintId'],
    );
  }

  Map<String, dynamic> _userToMap(UserModel user) {
    return {
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'phone': user.phone,
      'profileImage': user.profileImage,
      'createdAt': user.createdAt.toIso8601String(),
      'isGuest': user.isGuest ? 1 : 0,
      'points': user.points,
      'issuesReported': user.issuesReported,
      'issuesResolved': user.issuesResolved,
      'preferredLanguage': user.preferredLanguage,
      'notificationsEnabled': user.notificationsEnabled ? 1 : 0,
    };
  }

  UserModel _userFromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      profileImage: map['profileImage'],
      createdAt: DateTime.parse(map['createdAt']),
      isGuest: map['isGuest'] == 1,
      points: map['points'],
      issuesReported: map['issuesReported'],
      issuesResolved: map['issuesResolved'],
      preferredLanguage: map['preferredLanguage'],
      notificationsEnabled: map['notificationsEnabled'] == 1,
    );
  }

  Map<String, dynamic> _notificationToMap(NotificationModel notification) {
    return {
      'id': notification.id,
      'title': notification.title,
      'message': notification.message,
      'type': notification.type.toString().split('.').last,
      'isRead': notification.isRead ? 1 : 0,
      'createdAt': notification.createdAt.toIso8601String(),
      'issueId': notification.issueId,
      'actionUrl': notification.actionUrl,
      'metadata': notification.metadata != null
          ? jsonEncode(notification.metadata)
          : null,
    };
  }

  NotificationModel _notificationFromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'],
      title: map['title'],
      message: map['message'],
      type: NotificationType.values.firstWhere((e) => e.toString().split('.').last == map['type']),
      isRead: map['isRead'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      issueId: map['issueId'],
      actionUrl: map['actionUrl'],
      metadata: map['metadata'] != null ? jsonDecode(map['metadata']) : null,
    );
  }
}
