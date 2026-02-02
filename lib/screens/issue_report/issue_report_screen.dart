import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/map_location.dart';
import 'dart:io';
import '../../constants/app_constants.dart';
import '../../constants/app_theme.dart';
import '../../models/issue_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../services/image_encryption_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/category_selector.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/location_picker_widget.dart';
import '../auth/login_screen.dart';

class IssueReportScreen extends StatefulWidget {
  const IssueReportScreen({super.key});

  @override
  State<IssueReportScreen> createState() => _IssueReportScreenState();
}

class _IssueReportScreenState extends State<IssueReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _currentStep = 0;
  bool _isLoading = false;

  // Form data
  String _selectedCategory = '';
  String _selectedCategoryName = '';
  String _selectedCategoryIcon = '';
  List<File> _selectedImages = [];
  File? _selectedVideo;
  String _currentAddress = '';
  MapLocation? _selectedLocation;

  final List<String> _steps = ['Capture', 'Details', 'Location', 'Submit'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    setState(() {
      _currentStep--;
    });
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Capture
        return _selectedImages.isNotEmpty;
      case 1: // Details
        return _formKey.currentState!.validate() &&
            _selectedCategory.isNotEmpty;
      case 2: // Location
        return _selectedLocation != null;
      case 3: // Submit
        return true;
      default:
        return false;
    }
  }

  Future<void> _submitIssue() async {
    if (!_validateCurrentStep()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Check if user is authenticated
    if (!authProvider.isAuthenticated) {
      _showLoginRequiredDialog();
      return;
    }

    final currentUser = authProvider.currentUser!;

    setState(() {
      _isLoading = true;
    });

    // Process images for Firestore storage (Base64 encrypted)
    List<Map<String, dynamic>> processedImages = [];
    
    try {
      debugPrint('🔄 Starting issue submission with encryption...');
      debugPrint('👤 Current user: ${currentUser.email} (ID: ${currentUser.id})');
      debugPrint('📋 Form validation - Title: "${_titleController.text}", Category: "$_selectedCategory"');
      debugPrint('📷 Selected images: ${_selectedImages.length}');
      
      final encryptionService = ImageEncryptionService();
      encryptionService.initialize();
      
      // Skip Firebase Storage test since we're storing images in Firestore
      debugPrint('📄 Using Firestore for image storage (Base64 encrypted)');
      
      // Process images for Firestore storage
      
      if (_selectedImages.isNotEmpty) {
        debugPrint('🔐 Processing ${_selectedImages.length} images for Firestore storage...');
        
        try {
          processedImages = await encryptionService.processImagesForFirestore(
            _selectedImages,
            currentUser.id,
          );
          
          debugPrint('✅ Successfully processed ${processedImages.length}/${_selectedImages.length} images for Firestore');
          
          // Log image data sizes for monitoring
          for (int i = 0; i < processedImages.length; i++) {
            final imageData = processedImages[i];
            debugPrint('📄 Image ${i + 1}: ${imageData['originalSize']} bytes → ${imageData['encryptedSize']} bytes encrypted');
          }
          
        } catch (e) {
          debugPrint('❌ Failed to process images for Firestore: $e');
          debugPrint('📄 Error details: ${e.toString()}');
          // Continue without images rather than failing the entire submission
        }
      }

      // Create issue model with encrypted image paths
      final issue = IssueModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        categoryName: _selectedCategoryName,
        categoryIcon: _selectedCategoryIcon,
        status: IssueStatus.submitted,
        priority: _getPriorityFromCategory(_selectedCategory),
        userId: currentUser.id,
        userName: currentUser.name,
        userEmail: currentUser.email,
        userPhone: currentUser.phone,
        location: _selectedLocation!,
        address: _currentAddress,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        imageUrls: [], // Images will be stored directly in Firestore
        videoUrl: _selectedVideo?.path,
        department: _getDepartmentFromCategory(_selectedCategory),
        upvotes: 0,
        downvotes: 0,
        isPublic: true,
        complaintId: _generateComplaintId(),
      );

      // Test Firestore connectivity before storing
      debugPrint('🔥 Testing Firestore connectivity...');
      final firestoreService = FirestoreService();
      final hasFirestoreAccess = await firestoreService.testFirestoreConnection();
      if (!hasFirestoreAccess) {
        throw Exception('Firestore access denied. Check Firestore Security Rules.');
      }
      debugPrint('✅ Firestore connectivity verified');

      // Store the issue in Firestore with encrypted images
      debugPrint('💾 Storing issue in Firestore database...');
      await firestoreService.storeIssue(issue, encryptedImages: processedImages);
      
      // Update user statistics
      await UserService().updateUserStats(
        currentUser.id,
        issuesReported: 1,
        points: 10, // Award points for reporting an issue
      );
      
      debugPrint('✅ Issue created and stored: ${issue.title} (ID: ${issue.id}) with ${processedImages.length} encrypted images');

      if (mounted) {
        _showSuccessDialog(issue.complaintId ?? _generateComplaintId());
      }
    } catch (e, stackTrace) {
      debugPrint('❌ CRITICAL ERROR in issue submission: $e');
      debugPrint('📄 Stack trace: $stackTrace');
      debugPrint('📊 Current user: ${currentUser.id} (${currentUser.email})');
      debugPrint('📊 Selected images: ${_selectedImages.length}');
      debugPrint('📊 Processed images: ${processedImages.length}');
      debugPrint('📊 Issue title: ${_titleController.text}');
      debugPrint('📊 Issue category: $_selectedCategory');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit issue: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Get department based on category
  String _getDepartmentFromCategory(String category) {
    switch (category.toLowerCase()) {
      case 'road':
        return 'Public Works Department';
      case 'water':
        return 'Water Department';
      case 'electricity':
        return 'Electricity Board';
      case 'waste':
        return 'Sanitation Department';
      case 'security':
        return 'Police Department';
      default:
        return 'Municipal Corporation';
    }
  }

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

  String _generateComplaintId() {
    final now = DateTime.now();
    return 'SIH${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.millisecondsSinceEpoch.toString().substring(8)}';
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.login,
              size: 60,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Sign In Required',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Please sign in to report issues and track their progress.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String complaintId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Issue Reported Successfully!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Your complaint ID: $complaintId',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You will receive updates on the status of your complaint.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(true); // Go back to home with success status
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Done',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report Issue - Step ${_currentStep + 1}/${_steps.length}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary.withValues(alpha: 0.1),
            child: Row(
              children: _steps.asMap().entries.map((entry) {
                int index = entry.key;
                String step = entry.value;
                bool isActive = index == _currentStep;
                bool isCompleted = index < _currentStep;

                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted
                                    ? AppColors.success
                                    : isActive
                                    ? AppColors.primary
                                    : Colors.grey[300],
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: isActive
                                              ? Colors.white
                                              : Colors.grey[600],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              step,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: isActive
                                        ? AppColors.primary
                                        : Colors.grey[600],
                                    fontWeight: isActive
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (index < _steps.length - 1)
                        Container(
                          width: 20,
                          height: 2,
                          color: isCompleted
                              ? AppColors.success
                              : Colors.grey[300],
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Step Content
          Expanded(child: _buildStepContent()),

          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Previous',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  flex: _currentStep == 0 ? 1 : 1,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _getNextButtonAction(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            _getNextButtonText(),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
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

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildCaptureStep();
      case 1:
        return _buildDetailsStep();
      case 2:
        return _buildLocationStep();
      case 3:
        return _buildSubmitStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildCaptureStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Capture the Issue',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take photos or videos of the issue to help authorities understand the problem better.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ImagePickerWidget(
              selectedImages: _selectedImages,
              selectedVideo: _selectedVideo,
              onImagesSelected: (images) {
                setState(() {
                  _selectedImages = images;
                });
              },
              onVideoSelected: (video) {
                setState(() {
                  _selectedVideo = video;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Issue Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Provide more information about the issue to help authorities prioritize and resolve it.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Category Selection
              Text(
                'Category',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              CategorySelector(
                selectedCategory: _selectedCategory,
                onCategorySelected: (category, name, icon) {
                  setState(() {
                    _selectedCategory = category;
                    _selectedCategoryName = name;
                    _selectedCategoryIcon = icon;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Issue Title',
                  hintText: 'Brief description of the issue',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title for the issue';
                  }
                  if (value.length < 5) {
                    return 'Title must be at least 5 characters long';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Provide more details about the issue...',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please provide a description';
                  }
                  if (value.length < 10) {
                    return 'Description must be at least 10 characters long';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pin the exact location of the issue on the map.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LocationPickerWidget(
              selectedLocation: _selectedLocation,
              currentAddress: _currentAddress,
              onLocationSelected: (location, address) {
                setState(() {
                  _selectedLocation = location;
                  _currentAddress = address;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitStep() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & Submit',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please review your issue details before submitting.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Review Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _selectedCategoryIcon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedCategoryName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _titleController.text,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Description:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _descriptionController.text,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentAddress,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.photo_camera,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedImages.length} photo(s)',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (_selectedVideo != null) ...[
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.videocam,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '1 video',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  VoidCallback? _getNextButtonAction() {
    switch (_currentStep) {
      case 0:
      case 1:
      case 2:
        return _nextStep;
      case 3:
        return _submitIssue;
      default:
        return null;
    }
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case 0:
      case 1:
      case 2:
        return 'Next';
      case 3:
        return 'Submit Issue';
      default:
        return 'Next';
    }
  }
}
