import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/image_encryption_service.dart';

class FirestoreEncryptedImageWidget extends StatefulWidget {
  final Map<String, dynamic> encryptedImageData;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const FirestoreEncryptedImageWidget({
    super.key,
    required this.encryptedImageData,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  State<FirestoreEncryptedImageWidget> createState() =>
      _FirestoreEncryptedImageWidgetState();
}

class _FirestoreEncryptedImageWidgetState
    extends State<FirestoreEncryptedImageWidget> {
  Uint8List? _decryptedImageBytes;
  bool _isLoading = true;
  String? _error;
  final ImageEncryptionService _encryptionService = ImageEncryptionService();

  @override
  void initState() {
    super.initState();
    _encryptionService.initialize();
    _decryptImage();
  }

  Future<void> _decryptImage() async {
    try {
      if (!mounted) return;

      setState(() {
        _isLoading = true;
        _error = null;
      });

      debugPrint(
        '🔓 Decrypting Firestore image: ${widget.encryptedImageData['id']}',
      );
      debugPrint(
        '📄 Image data keys: ${widget.encryptedImageData.keys.toList()}',
      );

      final encryptedBase64 =
          widget.encryptedImageData['encryptedData'] as String?;
      if (encryptedBase64 == null || encryptedBase64.isEmpty) {
        throw Exception('No encrypted data found in image data');
      }

      debugPrint('📄 Encrypted Base64 length: ${encryptedBase64.length} chars');

      final decryptedBytes = _encryptionService.decryptImageFromBase64(
        encryptedBase64,
      );

      if (!mounted) return;

      setState(() {
        _decryptedImageBytes = decryptedBytes;
        _isLoading = false;
      });

      debugPrint(
        '✅ Image decrypted successfully: ${decryptedBytes.length} bytes',
      );
    } catch (e) {
      debugPrint('❌ Error decrypting Firestore image: $e');
      debugPrint('📄 Stack trace: ${StackTrace.current}');

      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_decryptedImageBytes != null) {
      return Image.memory(
        _decryptedImageBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Error displaying decrypted image: $error');
          return _buildErrorWidget();
        },
      );
    }

    return _buildErrorWidget();
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.grey[100],
      child: const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey, size: 24),
      ),
    );
  }
}

/// Widget to display multiple encrypted images from Firestore
class FirestoreEncryptedImageGallery extends StatelessWidget {
  final List<Map<String, dynamic>> encryptedImages;
  final double imageHeight;
  final int maxImages;
  final VoidCallback? onTap;

  const FirestoreEncryptedImageGallery({
    super.key,
    required this.encryptedImages,
    this.imageHeight = 80,
    this.maxImages = 3,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (encryptedImages.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayImages = encryptedImages.take(maxImages).toList();
    final hasMoreImages = encryptedImages.length > maxImages;

    return SizedBox(
      height: imageHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: displayImages.length,
        itemBuilder: (context, index) {
          final isLast = index == displayImages.length - 1;

          return GestureDetector(
            onTap: onTap,
            child: Container(
              margin: EdgeInsets.only(right: isLast ? 0 : 8),
              child: Stack(
                children: [
                  FirestoreEncryptedImageWidget(
                    encryptedImageData: displayImages[index],
                    width: imageHeight,
                    height: imageHeight,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  // Show count indicator if more images exist
                  if (isLast && hasMoreImages)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '+${encryptedImages.length - maxImages}',
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
            ),
          );
        },
      ),
    );
  }
}
