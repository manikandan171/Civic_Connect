import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_theme.dart';
import '../../models/issue_model.dart';
import '../../models/map_location.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/category_filter_widget.dart';

class CategoryMapDemo extends StatefulWidget {
  const CategoryMapDemo({super.key});

  @override
  State<CategoryMapDemo> createState() => _CategoryMapDemoState();
}

class _CategoryMapDemoState extends State<CategoryMapDemo> {
  String _selectedCategory = 'all';
  List<IssueModel> _issues = [];
  bool _isLoading = false;
  MapController _mapController = MapController();
  List<Marker> _markers = [];
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  Future<void> _loadIssues() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final firestoreService = FirestoreService();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      List<IssueModel> issues;
      if (currentUser != null && !currentUser.isGuest) {
        // Load user-specific filtered issues
        issues = await firestoreService.getUserFilteredIssues(
          currentUser.id,
          category: _selectedCategory,
        );
      } else {
        // Load public issues for guests
        issues = await firestoreService.getPublicIssues();
        // Filter by category client-side for public issues
        if (_selectedCategory != 'all') {
          issues = issues
              .where((issue) => issue.category == _selectedCategory)
              .toList();
        }
      }

      setState(() {
        _issues = issues;
        _updateMarkers();
      });
    } catch (e) {
      print('Error loading issues: $e');
      // Show demo data if database fails
      _createDemoIssues();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _createDemoIssues() {
    // Create some demo issues for different categories
    _issues = [
      IssueModel(
        id: '1',
        title: 'Pothole on Main Street',
        description: 'Large pothole causing traffic issues',
        category: 'pothole',
        categoryName: 'Pothole',
        categoryIcon: '🕳️',
        status: IssueStatus.submitted,
        priority: IssuePriority.high,
        userId: 'user1',
        userName: 'John Doe',
        location: const MapLocation(23.6102, 85.2799),
        address: 'Main Street, City Center',
        createdAt: DateTime.now(),
        complaintId: 'CC001',
        imageUrls: [],
      ),
      IssueModel(
        id: '2',
        title: 'Broken Street Light',
        description: 'Street light not working since last week',
        category: 'streetlight',
        categoryName: 'Street Light',
        categoryIcon: '💡',
        status: IssueStatus.inProgress,
        priority: IssuePriority.medium,
        userId: 'user2',
        userName: 'Jane Smith',
        location: const MapLocation(23.6150, 85.2850),
        address: 'Park Avenue, Downtown',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        complaintId: 'CC002',
        imageUrls: [],
      ),
      IssueModel(
        id: '3',
        title: 'Garbage Not Collected',
        description: 'Garbage bins overflowing for 3 days',
        category: 'garbage',
        categoryName: 'Garbage',
        categoryIcon: '🗑️',
        status: IssueStatus.acknowledged,
        priority: IssuePriority.high,
        userId: 'user3',
        userName: 'Mike Johnson',
        location: const MapLocation(23.6050, 85.2750),
        address: 'Residential Area, Block A',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        complaintId: 'CC003',
        imageUrls: [],
      ),
    ];
    _updateMarkers();
  }

  void _updateMarkers() {
    List<IssueModel> filteredIssues = _selectedCategory == 'all'
        ? _issues
        : _issues
              .where((issue) => issue.category == _selectedCategory)
              .toList();

    setState(() {
      _markers = filteredIssues.map((issue) {
        return Marker(
          point: LatLng(issue.location.latitude, issue.location.longitude),
          child: GestureDetector(
            onTap: () => _showIssueDetails(issue),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getStatusColor(issue.status),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  issue.categoryIcon,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        );
      }).toList();
    });
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

  void _showIssueDetails(IssueModel issue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(issue.categoryIcon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    issue.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Category: ${issue.categoryName}',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${issue.statusDisplayName}',
              style: TextStyle(
                color: _getStatusColor(issue.status),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(issue.description),
            const SizedBox(height: 12),
            Text(
              'Location: ${issue.address}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadIssues(); // Reload issues for the new category
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Map Demo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Category Filter
          CategoryFilterWidget(
            selectedCategory: _selectedCategory,
            onCategoryChanged: _onCategoryChanged,
          ),

          // Map
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(23.6102, 85.2799),
                    initialZoom: 13.0,
                    minZoom: 5.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.untitled',
                    ),
                    MarkerLayer(markers: _markers),
                  ],
                ),

                // Loading overlay
                if (_isLoading)
                  Container(
                    color: Colors.white.withValues(alpha: 0.8),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                // Info panel
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Text(
                      _selectedCategory == 'all'
                          ? 'Showing all ${_issues.length} issues'
                          : 'Showing ${_markers.length} ${_selectedCategory} issues',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
