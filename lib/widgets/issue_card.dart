import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../models/issue_model.dart';
import 'firebase_encrypted_image_widget.dart';
import 'firestore_encrypted_image_widget.dart';

class IssueCard extends StatelessWidget {
  final IssueModel issue;
  final VoidCallback? onTap;

  const IssueCard({super.key, required this.issue, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    // Category Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          issue.status,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          issue.categoryIcon,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title and Category
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            issue.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            issue.categoryName,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          issue.status,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(
                            issue.status,
                          ).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            issue.statusIcon,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            issue.statusDisplayName,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: _getStatusColor(issue.status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  issue.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Images (prioritize Firestore encrypted images, fallback to legacy URLs)
                _buildImageSection(),

                // Footer
                Row(
                  children: [
                    // Location
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              issue.address,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[500]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Priority
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(
                          issue.priority,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        issue.priorityDisplayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getPriorityColor(issue.priority),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Bottom Row
                Row(
                  children: [
                    // Complaint ID
                    if (issue.complaintId != null) ...[
                      Icon(Icons.receipt, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        issue.complaintId!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Date
                    Text(
                      _formatDate(issue.createdAt),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                    ),

                    const SizedBox(width: 8),

                    // Arrow
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    // Check if we have encrypted images from Firestore (new format)
    final hasEncryptedImages =
        issue.encryptedImages != null && issue.encryptedImages!.isNotEmpty;
    // Check if we have legacy image URLs
    final hasLegacyImages = issue.imageUrls.isNotEmpty;

    // Debug logging
    debugPrint('🖼️ IssueCard - Issue: ${issue.title}');
    debugPrint('🖼️ Encrypted images: ${issue.encryptedImages?.length ?? 0}');
    debugPrint('🖼️ Legacy URLs: ${issue.imageUrls.length}');
    if (hasEncryptedImages) {
      debugPrint(
        '🖼️ First encrypted image keys: ${issue.encryptedImages![0].keys.toList()}',
      );
    }

    if (hasEncryptedImages) {
      // Use new Firestore encrypted images
      return Column(
        children: [
          FirestoreEncryptedImageGallery(
            encryptedImages: issue.encryptedImages!,
            imageHeight: 80,
            maxImages: 3,
            onTap: onTap,
          ),
          const SizedBox(height: 12),
        ],
      );
    } else if (hasLegacyImages) {
      // Fallback to legacy image URLs
      return Column(
        children: [
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: issue.imageUrls.length > 3
                  ? 3
                  : issue.imageUrls.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  child: Stack(
                    children: [
                      // Use smart image widget that handles both Firebase and regular URLs
                      SmartEncryptedImageWidget(
                        imageUrl: issue.imageUrls[index],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                      // Show count indicator if more than 3 images
                      if (index == 2 && issue.imageUrls.length > 3)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '+${issue.imageUrls.length - 3}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      );
    } else {
      // No images
      return const SizedBox.shrink();
    }
  }

  Color _getStatusColor(IssueStatus status) {
    switch (status) {
      case IssueStatus.submitted:
        return AppColors.submitted;
      case IssueStatus.acknowledged:
        return AppColors.acknowledged;
      case IssueStatus.inProgress:
        return AppColors.inProgress;
      case IssueStatus.resolved:
        return AppColors.resolved;
      case IssueStatus.rejected:
        return AppColors.rejected;
    }
  }

  Color _getPriorityColor(IssuePriority priority) {
    switch (priority) {
      case IssuePriority.low:
        return AppColors.lowPriority;
      case IssuePriority.medium:
        return AppColors.mediumPriority;
      case IssuePriority.high:
        return AppColors.highPriority;
      case IssuePriority.urgent:
        return AppColors.urgentPriority;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
