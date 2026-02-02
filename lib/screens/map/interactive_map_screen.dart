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
import '../../widgets/map_filter_bottom_sheet.dart';
import '../../widgets/issue_marker_info_window.dart';

class InteractiveMapScreen extends StatefulWidget {
  const InteractiveMapScreen({super.key});

  @override
  State<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends State<InteractiveMapScreen> {
  List<IssueModel> _allIssues = [];
  List<IssueModel> _filteredIssues = [];
  String _selectedCategory = 'all';
  String _selectedStatus = 'all';
  bool _showHeatmap = false;
  bool _isLoading = true;
  MapController _mapController = MapController();
  List<Marker> _markers = [];
  LatLng? _currentLocation;
  bool _locationLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadIssues();
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      _locationLoading = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        if (mounted) {
          setState(() {
            _locationLoading = false;
          });
        }
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          if (mounted) {
            setState(() {
              _locationLoading = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        if (mounted) {
          setState(() {
            _locationLoading = false;
          });
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _locationLoading = false;
      });

      // Move map to current location
      if (_currentLocation != null && mounted) {
        _mapController.move(_currentLocation!, 15.0);
      }

      debugPrint(
        'Current location: ${_currentLocation?.latitude}, ${_currentLocation?.longitude}',
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      if (mounted) {
        setState(() {
          _locationLoading = false;
        });
      }
    }
  }

  Future<void> _loadIssues() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      // Load issues from Firestore
      final firestoreService = FirestoreService();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      if (currentUser != null && !currentUser.isGuest) {
        // Load user-specific filtered issues
        debugPrint(
          '🗺️ Loading filtered issues for user: ${currentUser.name} (${currentUser.id})',
        );
        _allIssues = await firestoreService.getUserFilteredIssues(
          currentUser.id,
          category: _selectedCategory,
          status: _selectedStatus,
        );
        debugPrint('🗺️ Loaded ${_allIssues.length} filtered issues');
      } else {
        // Load public issues for guests
        _allIssues = await firestoreService.getPublicIssues();
        // Filter client-side for public issues
        if (_selectedCategory != 'all') {
          _allIssues = _allIssues
              .where((issue) => issue.category == _selectedCategory)
              .toList();
        }
        if (_selectedStatus != 'all') {
          _allIssues = _allIssues
              .where(
                (issue) =>
                    issue.status.toString().split('.').last == _selectedStatus,
              )
              .toList();
        }
      }

      _filteredIssues = List.from(_allIssues);
      _updateMarkers();
    } catch (e) {
      debugPrint('Error loading issues: $e');
      // Create demo data if database fails
      _createDemoIssues();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _createDemoIssues() {
    // Create some demo issues for testing
    _allIssues = [
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
    _filterIssues();
  }

  void _filterIssues() {
    if (mounted) {
      setState(() {
        _filteredIssues = _allIssues.where((issue) {
          bool categoryMatch =
              _selectedCategory == 'all' || issue.category == _selectedCategory;
          bool statusMatch =
              _selectedStatus == 'all' ||
              issue.status.toString().split('.').last == _selectedStatus;
          return categoryMatch && statusMatch;
        }).toList();
      });
      // Update markers when filters change
      _updateMarkers();
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MapFilterBottomSheet(
        selectedCategory: _selectedCategory,
        selectedStatus: _selectedStatus,
        showHeatmap: _showHeatmap,
        showStreetView: false,
        onCategoryChanged: (category) {
          if (mounted) {
            setState(() {
              _selectedCategory = category;
            });
          }
        },
        onStatusChanged: (status) {
          if (mounted) {
            setState(() {
              _selectedStatus = status;
            });
          }
        },
        onHeatmapChanged: (show) {
          if (mounted) {
            setState(() {
              _showHeatmap = show;
            });
          }
        },
        onStreetViewChanged: (show) {
          // Street view not used with Flutter Map
        },
        onApplyFilters: () {
          _filterIssues();
          Navigator.of(context).pop();
        },
        onClearFilters: () {
          if (mounted) {
            setState(() {
              _selectedCategory = 'all';
              _selectedStatus = 'all';
              _showHeatmap = false;
            });
          }
          _filterIssues();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showIssueDetails(IssueModel issue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IssueMarkerInfoWindow(issue: issue),
    );
  }

  void _updateMarkers() {
    if (mounted) {
      setState(() {
        _markers = _filteredIssues.map((issue) {
          return Marker(
            point: LatLng(issue.location.latitude, issue.location.longitude),
            child: GestureDetector(
              onTap: () => _showIssueDetails(issue),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getMarkerColor(issue.status),
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
  }

  Color _getMarkerColor(IssueStatus status) {
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

  void _centerMapOnIssues() {
    if (_filteredIssues.isEmpty) return;

    if (_filteredIssues.length == 1) {
      final issue = _filteredIssues.first;
      _mapController.move(
        LatLng(issue.location.latitude, issue.location.longitude),
        16.0,
      );
    } else {
      // Calculate bounds for multiple issues
      double minLat = _filteredIssues.first.location.latitude;
      double maxLat = _filteredIssues.first.location.latitude;
      double minLng = _filteredIssues.first.location.longitude;
      double maxLng = _filteredIssues.first.location.longitude;

      for (final issue in _filteredIssues) {
        minLat = minLat < issue.location.latitude
            ? minLat
            : issue.location.latitude;
        maxLat = maxLat > issue.location.latitude
            ? maxLat
            : issue.location.latitude;
        minLng = minLng < issue.location.longitude
            ? minLng
            : issue.location.longitude;
        maxLng = maxLng > issue.location.longitude
            ? maxLng
            : issue.location.longitude;
      }

      // Calculate center and appropriate zoom
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      final latDiff = maxLat - minLat;
      final lngDiff = maxLng - minLng;
      final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

      double zoom = 15.0;
      if (maxDiff > 0.1)
        zoom = 10.0;
      else if (maxDiff > 0.05)
        zoom = 12.0;
      else if (maxDiff > 0.01)
        zoom = 14.0;

      _mapController.move(LatLng(centerLat, centerLng), zoom);
    }
  }

  void _goToCurrentLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 16.0);
    } else {
      // Try to get current location again
      _getCurrentLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Flutter Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  _currentLocation ??
                  LatLng(
                    AppConstants.defaultLatitude,
                    AppConstants.defaultLongitude,
                  ),
              initialZoom: _currentLocation != null
                  ? 15.0
                  : AppConstants.defaultZoom,
              minZoom: 5.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.untitled',
              ),
              MarkerLayer(
                markers: [
                  ..._markers,
                  // Current location marker
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Loading Overlay
          if (_isLoading || _locationLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _locationLoading
                          ? 'Getting your location...'
                          : 'Loading issues...',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Filter Button
          Positioned(
            top: 50,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'fab_filter',
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _showFilterBottomSheet,
              child: const Icon(Icons.filter_list, color: AppColors.primary),
            ),
          ),

          // Map Controls
          Positioned(
            bottom: 100,
            right: 16,
            child: Column(
              children: [
                // My Location button
                FloatingActionButton(
                  heroTag: 'fab_my_location',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _goToCurrentLocation,
                  child: Icon(
                    Icons.my_location,
                    color: _currentLocation != null
                        ? AppColors.primary
                        : Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                // Center on issues
                if (_filteredIssues.isNotEmpty)
                  FloatingActionButton(
                    heroTag: 'fab_map_center',
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: _centerMapOnIssues,
                    child: const Icon(
                      Icons.center_focus_strong,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),

          // Map Legend
          if (_filteredIssues.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Issues: ${_filteredIssues.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedCategory == 'all'
                          ? 'All Categories'
                          : _selectedCategory.toUpperCase(),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
