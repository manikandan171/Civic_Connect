import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/media_encryption_service.dart';

/// Widget to display encrypted media (images/videos) from Firestore Base64
class EncryptedMediaWidget extends StatefulWidget {
  final String encryptedBase64;
  final String mediaType; // 'image' or 'video' or 'video_thumbnail'
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const EncryptedMediaWidget({
    super.key,
    required this.encryptedBase64,
    this.mediaType = 'image',
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<EncryptedMediaWidget> createState() => _EncryptedMediaWidgetState();
}

class _EncryptedMediaWidgetState extends State<EncryptedMediaWidget> {
  final MediaEncryptionService _mediaService = MediaEncryptionService();
  Uint8List? _decryptedBytes;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _decryptMedia();
  }

  @override
  void didUpdateWidget(EncryptedMediaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.encryptedBase64 != widget.encryptedBase64) {
      _decryptMedia();
    }
  }

  Future<void> _decryptMedia() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _mediaService.initialize();
      final bytes = _mediaService.decryptFromBase64(widget.encryptedBase64);

      if (mounted) {
        setState(() {
          _decryptedBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error decrypting media: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ??
          SizedBox(
            width: widget.width ?? 100,
            height: widget.height ?? 100,
            child: const Center(child: CircularProgressIndicator()),
          );
    }

    if (_error != null || _decryptedBytes == null) {
      return widget.errorWidget ??
          SizedBox(
            width: widget.width ?? 100,
            height: widget.height ?? 100,
            child: const Icon(Icons.error_outline, color: Colors.red),
          );
    }

    return Image.memory(
      _decryptedBytes!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }
}

/// Gallery widget to display multiple encrypted images
class EncryptedMediaGallery extends StatelessWidget {
  final List<Map<String, dynamic>> mediaList;
  final double itemWidth;
  final double itemHeight;
  final int crossAxisCount;
  final double spacing;

  const EncryptedMediaGallery({
    super.key,
    required this.mediaList,
    this.itemWidth = 100,
    this.itemHeight = 100,
    this.crossAxisCount = 3,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaList.isEmpty) {
      return const Center(child: Text('No media available'));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: itemWidth / itemHeight,
      ),
      itemCount: mediaList.length,
      itemBuilder: (context, index) {
        final mediaData = mediaList[index];
        final encryptedData = mediaData['encryptedData'] as String?;
        final mediaType = mediaData['type'] as String? ?? 'image';

        if (encryptedData == null) {
          return const Icon(Icons.broken_image);
        }

        return GestureDetector(
          onTap: () {
            _showFullScreen(context, encryptedData, mediaType);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: EncryptedMediaWidget(
              encryptedBase64: encryptedData,
              mediaType: mediaType,
              width: itemWidth,
              height: itemHeight,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  void _showFullScreen(
    BuildContext context,
    String encryptedData,
    String mediaType,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(
              child: EncryptedMediaWidget(
                encryptedBase64: encryptedData,
                mediaType: mediaType,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Media picker and upload widget
class MediaPickerWidget extends StatefulWidget {
  final String userId;
  final Function(List<Map<String, dynamic>> images, Map<String, dynamic>? video)
  onMediaProcessed;
  final bool allowVideo;
  final int maxImages;

  const MediaPickerWidget({
    super.key,
    required this.userId,
    required this.onMediaProcessed,
    this.allowVideo = true,
    this.maxImages = 5,
  });

  @override
  State<MediaPickerWidget> createState() => _MediaPickerWidgetState();
}

class _MediaPickerWidgetState extends State<MediaPickerWidget> {
  final MediaEncryptionService _mediaService = MediaEncryptionService();
  final List<File> _selectedImages = [];
  File? _selectedVideo;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _mediaService.initialize();
  }

  Future<void> _pickImages() async {
    try {
      final images = await _mediaService.pickMultipleImages();

      setState(() {
        _selectedImages.addAll(images);
        if (_selectedImages.length > widget.maxImages) {
          _selectedImages.removeRange(widget.maxImages, _selectedImages.length);
        }
      });
    } catch (e) {
      _showError('Failed to pick images: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final video = await _mediaService.pickVideoFromGallery();

      if (video != null) {
        setState(() {
          _selectedVideo = video;
        });
      }
    } catch (e) {
      _showError('Failed to pick video: $e');
    }
  }

  Future<void> _processMedia() async {
    if (_selectedImages.isEmpty && _selectedVideo == null) {
      _showError('Please select at least one image or video');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Process images
      List<Map<String, dynamic>> processedImages = [];
      if (_selectedImages.isNotEmpty) {
        processedImages = await _mediaService.processImagesForFirestore(
          _selectedImages,
          widget.userId,
        );
      }

      // Process video
      Map<String, dynamic>? processedVideo;
      if (_selectedVideo != null) {
        processedVideo = await _mediaService.processVideoForFirestore(
          _selectedVideo!,
          widget.userId,
        );
      }

      widget.onMediaProcessed(processedImages, processedVideo);

      setState(() {
        _selectedImages.clear();
        _selectedVideo = null;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showError('Failed to process media: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeVideo() {
    setState(() {
      _selectedVideo = null;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _pickImages,
                icon: const Icon(Icons.image),
                label: Text(
                  'Pick Images (${_selectedImages.length}/${widget.maxImages})',
                ),
              ),
            ),
            if (widget.allowVideo) ...[
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _pickVideo,
                  icon: const Icon(Icons.videocam),
                  label: Text(
                    _selectedVideo != null ? 'Video ✓' : 'Pick Video',
                  ),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 16),

        // Selected images preview
        if (_selectedImages.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(_selectedImages[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
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
                  ],
                );
              },
            ),
          ),

        // Selected video preview
        if (_selectedVideo != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.video_file, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _selectedVideo!.path.split('/').last,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: _removeVideo,
                  icon: const Icon(Icons.close, color: Colors.red),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Process button
        ElevatedButton(
          onPressed: _isProcessing ? null : _processMedia,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            backgroundColor: Colors.blue,
          ),
          child: _isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Process & Upload Media',
                  style: TextStyle(fontSize: 16),
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mediaService.dispose();
    super.dispose();
  }
}
