import 'dart:io';
import 'package:flutter/material.dart';
import '../services/image_service.dart';

class ImageUploadWidget extends StatefulWidget {
  final Function(List<ImageData>)? onImagesSelected;
  final bool allowMultiple;
  final int maxImages;
  final List<ImageData>? initialImages;

  const ImageUploadWidget({
    super.key,
    this.onImagesSelected,
    this.allowMultiple = false,
    this.maxImages = 5,
    this.initialImages,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final ImageService _imageService = ImageService();
  List<ImageData> _selectedImages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialImages != null) {
      _selectedImages = List.from(widget.initialImages!);
    }
  }

  Future<void> _pickSingleImage() async {
    setState(() {
      _isLoading = true;
    });

    final imageData = await _imageService.showImagePickerDialog(context);
    
    if (imageData != null) {
      setState(() {
        _selectedImages = [imageData];
      });
      widget.onImagesSelected?.call(_selectedImages);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickMultipleImages() async {
    setState(() {
      _isLoading = true;
    });

    final images = await _imageService.pickMultipleImages();
    
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
        // Limit to max images
        if (_selectedImages.length > widget.maxImages) {
          _selectedImages = _selectedImages.take(widget.maxImages).toList();
        }
      });
      widget.onImagesSelected?.call(_selectedImages);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _addImage() async {
    if (widget.allowMultiple && _selectedImages.length < widget.maxImages) {
      await _pickMultipleImages();
    } else if (!widget.allowMultiple) {
      await _pickSingleImage();
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    widget.onImagesSelected?.call(_selectedImages);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload button
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey[300]!,
              style: BorderStyle.solid,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : InkWell(
                  onTap: _addImage,
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload,
                        size: 40,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.allowMultiple
                            ? 'Tap to upload images'
                            : 'Tap to upload image',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      if (widget.allowMultiple) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Max ${widget.maxImages} images',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),

        // Selected images grid
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Selected Images (${_selectedImages.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              final imageData = _selectedImages[index];
              return _buildImageTile(imageData, index);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildImageTile(ImageData imageData, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(imageData.filepath),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
          
          // Remove button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
          
          // Image info overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(
                imageData.formattedSize,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Simple image display widget
class ImageDisplayWidget extends StatelessWidget {
  final ImageData imageData;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ImageDisplayWidget({
    super.key,
    required this.imageData,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(imageData.filepath),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Icon(
            Icons.broken_image,
            color: Colors.grey,
          ),
        );
      },
    );
  }
}

// Image gallery widget
class ImageGalleryWidget extends StatefulWidget {
  final List<ImageData> images;
  final Function(ImageData)? onImageTap;
  final Function(ImageData)? onImageDelete;

  const ImageGalleryWidget({
    super.key,
    required this.images,
    this.onImageTap,
    this.onImageDelete,
  });

  @override
  State<ImageGalleryWidget> createState() => _ImageGalleryWidgetState();
}

class _ImageGalleryWidgetState extends State<ImageGalleryWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No images found',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: widget.images.length,
      itemBuilder: (context, index) {
        final imageData = widget.images[index];
        return _buildGalleryItem(imageData);
      },
    );
  }

  Widget _buildGalleryItem(ImageData imageData) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => widget.onImageTap?.call(imageData),
            child: ImageDisplayWidget(
              imageData: imageData,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          
          // Image info
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    imageData.filename,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${imageData.formattedSize} • ${_formatDate(imageData.createdAt)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Delete button
          if (widget.onImageDelete != null)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => widget.onImageDelete?.call(imageData),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
