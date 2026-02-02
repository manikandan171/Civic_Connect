import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../constants/app_constants.dart';

class CategoryFilterWidget extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategoryChanged;

  const CategoryFilterWidget({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: AppConstants.issueCategories.length + 1, // +1 for "All"
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All" category
            return _buildCategoryChip(
              category: 'all',
              displayName: 'All',
              icon: '🏛️',
              isSelected: selectedCategory == 'all',
            );
          }
          
          final category = AppConstants.issueCategories[index - 1];
          return _buildCategoryChip(
            category: category['id']!,
            displayName: category['name']!,
            icon: category['icon']!,
            isSelected: selectedCategory == category['id'],
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip({
    required String category,
    required String displayName,
    required String icon,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: FilterChip(
        selected: isSelected,
        onSelected: (selected) {
          onCategoryChanged(category);
        },
        avatar: Text(
          icon,
          style: const TextStyle(fontSize: 16),
        ),
        label: Text(
          displayName,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey[300]!,
          width: 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}

// Category-specific map widget
class CategoryMapWidget extends StatefulWidget {
  final String selectedCategory;
  final Function(String) onCategoryChanged;

  const CategoryMapWidget({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  State<CategoryMapWidget> createState() => _CategoryMapWidgetState();
}

class _CategoryMapWidgetState extends State<CategoryMapWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Category Filter
        CategoryFilterWidget(
          selectedCategory: widget.selectedCategory,
          onCategoryChanged: widget.onCategoryChanged,
        ),
        
        // Map will be added here
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Map for ${widget.selectedCategory == 'all' ? 'All Categories' : widget.selectedCategory}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Issues will be filtered by category',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
