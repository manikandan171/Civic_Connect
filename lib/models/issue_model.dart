import 'map_location.dart';

enum IssueStatus { submitted, acknowledged, inProgress, resolved, rejected }

enum IssuePriority { low, medium, high, urgent }

// Helper extensions for enum to string conversion
extension IssueStatusExtension on IssueStatus {
  String get displayName {
    switch (this) {
      case IssueStatus.submitted:
        return 'submitted';
      case IssueStatus.acknowledged:
        return 'acknowledged';
      case IssueStatus.inProgress:
        return 'inProgress';
      case IssueStatus.resolved:
        return 'resolved';
      case IssueStatus.rejected:
        return 'rejected';
    }
  }
}

extension IssuePriorityExtension on IssuePriority {
  String get displayName {
    switch (this) {
      case IssuePriority.low:
        return 'low';
      case IssuePriority.medium:
        return 'medium';
      case IssuePriority.high:
        return 'high';
      case IssuePriority.urgent:
        return 'urgent';
    }
  }
}

class IssueModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String categoryName;
  final String categoryIcon;
  final IssueStatus status;
  final IssuePriority priority;
  final String userId;
  final String userName;
  final String? userPhone;
  final String? userEmail;
  final List<String> imageUrls;
  final List<Map<String, dynamic>>? encryptedImages; // New field for Firestore encrypted images
  final String? videoUrl;
  final MapLocation location;
  final String address;
  final String? department;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final String? assignedTo;
  final String? assignedToName;
  final List<IssueUpdate> updates;
  final int upvotes;
  final int downvotes;
  final bool isPublic;
  final String? complaintId; // For tracking

  IssueModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.categoryName,
    required this.categoryIcon,
    required this.status,
    required this.priority,
    required this.userId,
    required this.userName,
    this.userPhone,
    this.userEmail,
    this.imageUrls = const [],
    this.encryptedImages,
    this.videoUrl,
    required this.location,
    required this.address,
    this.department,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.resolutionNotes,
    this.assignedTo,
    this.assignedToName,
    this.updates = const [],
    this.upvotes = 0,
    this.downvotes = 0,
    this.isPublic = true,
    this.complaintId,
  });

  factory IssueModel.fromJson(Map<String, dynamic> json) {
    return IssueModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      categoryName: json['categoryName'] ?? '',
      categoryIcon: json['categoryIcon'] ?? '📋',
      status: IssueStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => IssueStatus.submitted,
      ),
      priority: IssuePriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => IssuePriority.medium,
      ),
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userPhone: json['userPhone'],
      userEmail: json['userEmail'],
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      encryptedImages: json['encryptedImages'] != null 
          ? List<Map<String, dynamic>>.from(json['encryptedImages'])
          : null,
      videoUrl: json['videoUrl'],
      location: MapLocation(
        json['location']['latitude'] ?? 0.0,
        json['location']['longitude'] ?? 0.0,
      ),
      address: json['address'] ?? '',
      department: json['department'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'])
          : null,
      resolutionNotes: json['resolutionNotes'],
      assignedTo: json['assignedTo'],
      assignedToName: json['assignedToName'],
      updates:
          (json['updates'] as List<dynamic>?)
              ?.map((update) => IssueUpdate.fromJson(update))
              .toList() ??
          [],
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      isPublic: json['isPublic'] ?? true,
      complaintId: json['complaintId'],
    );
  }

  // Create IssueModel from Firestore document data
  factory IssueModel.fromMap(Map<String, dynamic> map) {
    return IssueModel.fromJson(map);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'categoryName': categoryName,
      'categoryIcon': categoryIcon,
      'status': status.name,
      'priority': priority.name,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'userEmail': userEmail,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'address': address,
      'department': department,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolutionNotes': resolutionNotes,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'updates': updates.map((update) => update.toJson()).toList(),
      'upvotes': upvotes,
      'downvotes': downvotes,
      'isPublic': isPublic,
      'complaintId': complaintId,
    };
  }

  IssueModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? categoryName,
    String? categoryIcon,
    IssueStatus? status,
    IssuePriority? priority,
    String? userId,
    String? userName,
    String? userPhone,
    String? userEmail,
    List<String>? imageUrls,
    String? videoUrl,
    MapLocation? location,
    String? address,
    String? department,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    String? resolutionNotes,
    String? assignedTo,
    String? assignedToName,
    List<IssueUpdate>? updates,
    int? upvotes,
    int? downvotes,
    bool? isPublic,
    String? complaintId,
  }) {
    return IssueModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userEmail: userEmail ?? this.userEmail,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      location: location ?? this.location,
      address: address ?? this.address,
      department: department ?? this.department,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      updates: updates ?? this.updates,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      isPublic: isPublic ?? this.isPublic,
      complaintId: complaintId ?? this.complaintId,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case IssueStatus.submitted:
        return 'Submitted';
      case IssueStatus.acknowledged:
        return 'Acknowledged';
      case IssueStatus.inProgress:
        return 'In Progress';
      case IssueStatus.resolved:
        return 'Resolved';
      case IssueStatus.rejected:
        return 'Rejected';
    }
  }

  String get statusIcon {
    switch (status) {
      case IssueStatus.submitted:
        return '⏳';
      case IssueStatus.acknowledged:
        return '✅';
      case IssueStatus.inProgress:
        return '🚧';
      case IssueStatus.resolved:
        return '🟢';
      case IssueStatus.rejected:
        return '❌';
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case IssuePriority.low:
        return 'Low';
      case IssuePriority.medium:
        return 'Medium';
      case IssuePriority.high:
        return 'High';
      case IssuePriority.urgent:
        return 'Urgent';
    }
  }

  @override
  String toString() {
    return 'IssueModel(id: $id, title: $title, status: $status, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IssueModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class IssueUpdate {
  final String id;
  final String issueId;
  final String message;
  final String? imageUrl;
  final String updatedBy;
  final String updatedByName;
  final DateTime updatedAt;
  final IssueStatus? newStatus;

  IssueUpdate({
    required this.id,
    required this.issueId,
    required this.message,
    this.imageUrl,
    required this.updatedBy,
    required this.updatedByName,
    required this.updatedAt,
    this.newStatus,
  });

  factory IssueUpdate.fromJson(Map<String, dynamic> json) {
    return IssueUpdate(
      id: json['id'] ?? '',
      issueId: json['issueId'] ?? '',
      message: json['message'] ?? '',
      imageUrl: json['imageUrl'],
      updatedBy: json['updatedBy'] ?? '',
      updatedByName: json['updatedByName'] ?? '',
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      newStatus: json['newStatus'] != null
          ? IssueStatus.values.firstWhere(
              (e) => e.name == json['newStatus'],
              orElse: () => IssueStatus.submitted,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'issueId': issueId,
      'message': message,
      'imageUrl': imageUrl,
      'updatedBy': updatedBy,
      'updatedByName': updatedByName,
      'updatedAt': updatedAt.toIso8601String(),
      'newStatus': newStatus?.name,
    };
  }
}
