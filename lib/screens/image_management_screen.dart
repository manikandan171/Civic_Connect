import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/image_service.dart';
import '../widgets/image_upload_widget.dart';

class ImageManagementScreen extends StatefulWidget {
  const ImageManagementScreen({super.key});

  @override
  State<ImageManagementScreen> createState() => _ImageManagementScreenState();
}

class _ImageManagementScreenState extends State<ImageManagementScreen>
    with SingleTickerProviderStateMixin {
  final ImageService _imageService = ImageService();
  late TabController _tabController;
  
  List<ImageData> _allImages = [];
  List<ImageData> _selectedImages = [];
  bool _isLoading = false;
  int _totalStorageUsed = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadImages();
    _loadStorageInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadImages() async {
    setState(() {
      _isLoading = true;
    });

    final images = await _imageService.getAllImages();
    
    setState(() {
      _allImages = images;
      _isLoading = false;
    });
  }

  Future<void> _loadStorageInfo() async {
    final storage = await _imageService.getTotalStorageUsed();
    setState(() {
      _totalStorageUsed = storage;
    });
  }

  void _onImagesSelected(List<ImageData> images) {
    setState(() {
      _selectedImages = images;
    });
    _loadImages(); // Refresh the gallery
    _loadStorageInfo(); // Update storage info
  }

  Future<void> _deleteImage(ImageData imageData) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: Text('Are you sure you want to delete ${imageData.filename}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _imageService.deleteImage(imageData.id);
      if (success) {
        _loadImages();
        _loadStorageInfo();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image deleted successfully')),
          );
        }
      }
    }
  }

  Future<void> _viewImageDetails(ImageData imageData) async {
    showDialog(
      context: context,
      builder: (context) => _ImageDetailsDialog(imageData: imageData),
    );
  }

  String _formatStorageSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Management'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.upload), text: 'Upload'),
            Tab(icon: Icon(Icons.photo_library), text: 'Gallery'),
            Tab(icon: Icon(Icons.info), text: 'Storage'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUploadTab(),
          _buildGalleryTab(),
          _buildStorageTab(),
        ],
      ),
    );
  }

  Widget _buildUploadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Single Image Upload',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ImageUploadWidget(
            onImagesSelected: _onImagesSelected,
            allowMultiple: false,
          ),
          
          const SizedBox(height: 32),
          
          Text(
            'Multiple Images Upload',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ImageUploadWidget(
            onImagesSelected: _onImagesSelected,
            allowMultiple: true,
            maxImages: 5,
          ),
          
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Images: ${_selectedImages.length}'),
                    Text('Total Size: ${_formatStorageSize(_selectedImages.fold(0, (sum, img) => sum + img.size))}'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGalleryTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Images (${_allImages.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _loadImages,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ImageGalleryWidget(
              images: _allImages,
              onImageTap: _viewImageDetails,
              onImageDelete: _deleteImage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Storage Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStorageRow('Total Images', '${_allImages.length}'),
                  _buildStorageRow('Total Storage Used', _formatStorageSize(_totalStorageUsed)),
                  _buildStorageRow('Average Image Size', 
                    _allImages.isNotEmpty 
                      ? _formatStorageSize(_totalStorageUsed ~/ _allImages.length)
                      : '0 B'
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Images',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_allImages.isEmpty)
                    const Text('No images found')
                  else
                    ...(_allImages.take(5).map((image) => ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: ImageDisplayWidget(
                          imageData: image,
                          width: 50,
                          height: 50,
                        ),
                      ),
                      title: Text(
                        image.filename,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${image.formattedSize} • ${_formatDate(image.createdAt)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () => _viewImageDetails(image),
                      ),
                    ))),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loadStorageInfo,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Storage Info'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _ImageDetailsDialog extends StatelessWidget {
  final ImageData imageData;

  const _ImageDetailsDialog({required this.imageData});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image preview
            Container(
              height: 200,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: ImageDisplayWidget(
                imageData: imageData,
                width: double.infinity,
                height: 200,
              ),
            ),
            
            // Image details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Image Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Filename', imageData.filename),
                  _buildDetailRow('Size', imageData.formattedSize),
                  _buildDetailRow('MIME Type', imageData.mimeType),
                  _buildDetailRow('Created', _formatDateTime(imageData.createdAt)),
                  _buildDetailRow('ID', imageData.id),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: imageData.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ID copied to clipboard')),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy ID'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
