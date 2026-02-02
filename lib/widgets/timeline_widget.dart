import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../models/issue_model.dart';

class TimelineWidget extends StatelessWidget {
  final List<IssueUpdate> updates;
  final DateTime issueCreatedAt;
  final IssueStatus issueStatus;

  const TimelineWidget({
    super.key,
    required this.updates,
    required this.issueCreatedAt,
    required this.issueStatus,
  });

  @override
  Widget build(BuildContext context) {
    // Create timeline items
    List<TimelineItem> timelineItems = [];
    
    // Add initial submission
    timelineItems.add(
      TimelineItem(
        title: 'Issue Submitted',
        description: 'Your issue has been submitted and is under review',
        timestamp: issueCreatedAt,
        status: IssueStatus.submitted,
        isCompleted: true,
      ),
    );

    // Add updates
    for (var update in updates) {
      timelineItems.add(
        TimelineItem(
          title: _getUpdateTitle(update.newStatus),
          description: update.message,
          timestamp: update.updatedAt,
          status: update.newStatus ?? issueStatus,
          isCompleted: _isStatusCompleted(update.newStatus ?? issueStatus),
          updatedBy: update.updatedByName,
        ),
      );
    }

    // Sort by timestamp
    timelineItems.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Column(
      children: timelineItems.asMap().entries.map((entry) {
        int index = entry.key;
        TimelineItem item = entry.value;
        bool isLast = index == timelineItems.length - 1;

        return _buildTimelineItem(context, item, isLast);
      }).toList(),
    );
  }

  Widget _buildTimelineItem(BuildContext context, TimelineItem item, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.isCompleted 
                    ? _getStatusColor(item.status)
                    : Colors.grey[300],
                border: Border.all(
                  color: item.isCompleted 
                      ? _getStatusColor(item.status)
                      : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: item.isCompleted
                  ? Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : Icon(
                      Icons.radio_button_unchecked,
                      size: 14,
                      color: Colors.grey[400],
                    ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: Colors.grey[300],
                margin: const EdgeInsets.only(top: 4),
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: item.isCompleted ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTimestamp(item.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: item.isCompleted ? Colors.grey[700] : Colors.grey[500],
                    height: 1.4,
                  ),
                ),
                if (item.updatedBy != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Updated by: ${item.updatedBy}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getUpdateTitle(IssueStatus? status) {
    if (status == null) return 'Update';
    
    switch (status) {
      case IssueStatus.acknowledged:
        return 'Issue Acknowledged';
      case IssueStatus.inProgress:
        return 'Work In Progress';
      case IssueStatus.resolved:
        return 'Issue Resolved';
      case IssueStatus.rejected:
        return 'Issue Rejected';
      default:
        return 'Status Update';
    }
  }

  bool _isStatusCompleted(IssueStatus status) {
    return status != IssueStatus.submitted;
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

class TimelineItem {
  final String title;
  final String description;
  final DateTime timestamp;
  final IssueStatus status;
  final bool isCompleted;
  final String? updatedBy;

  TimelineItem({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.status,
    required this.isCompleted,
    this.updatedBy,
  });
}
