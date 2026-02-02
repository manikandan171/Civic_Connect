import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class StatusFilterWidget extends StatelessWidget {
  final String selectedStatus;
  final Function(String) onStatusChanged;

  const StatusFilterWidget({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  static const List<Map<String, String>> statusOptions = [
    {'value': 'all', 'label': 'All Status', 'icon': '📋'},
    {'value': 'submitted', 'label': 'Submitted', 'icon': '📝'},
    {'value': 'acknowledged', 'label': 'Acknowledged', 'icon': '👀'},
    {'value': 'inProgress', 'label': 'In Progress', 'icon': '🔄'},
    {'value': 'resolved', 'label': 'Resolved', 'icon': '✅'},
    {'value': 'rejected', 'label': 'Rejected', 'icon': '❌'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: statusOptions.length,
        itemBuilder: (context, index) {
          final status = statusOptions[index];
          final isSelected = selectedStatus == status['value'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    status['icon']!,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    status['label']!,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              onSelected: (bool selected) {
                if (selected) {
                  onStatusChanged(status['value']!);
                }
              },
              selectedColor: AppColors.primary,
              backgroundColor: Colors.grey[100],
              checkmarkColor: Colors.white,
              elevation: isSelected ? 4 : 1,
              pressElevation: 6,
            ),
          );
        },
      ),
    );
  }
}
