import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/image_encryption_service.dart';

/// Widget to display encrypted images from Firebase Storage
class FirebaseEncryptedImageWidget extends StatefulWidget {
  final String downloadUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const FirebaseEncryptedImageWidget({
    super.key,
    required this.downloadUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<FirebaseEncryptedImageWidget> createState() => _FirebaseEncryptedImageWidgetState();
}

class _FirebaseEncryptedImageWidgetState extends State<FirebaseEncryptedImageWidget> {
  final ImageEncryptionService _encryptionService = ImageEncryptionService();
  Uint8List? _decryptedImageData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _encryptionService.initialize();
    _loadDecryptedImage();
  }

  Future<void> _loadDecryptedImage() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      debugPrint('🔓 Loading encrypted image from Firebase: ${widget.downloadUrl}');
      
      // Download and decrypt the image
      final decryptedData = await _encryptionService.downloadAndDecryptImage(widget.downloadUrl);
      
      if (mounted) {
        if (decryptedData != null) {
          setState(() {
            _decryptedImageData = decryptedData;
            _isLoading = false;
          });
          debugPrint('✅ Firebase image decrypted and loaded successfully');
        } else {
          setState(() {
            _error = 'Failed to decrypt image';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading Firebase encrypted image: $e');
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
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(strokeWidth: 2),
                const SizedBox(height: 8),
                Text(
                  'Decrypting...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
    }

    if (_error != null || _decryptedImageData == null) {
      return widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported,
                  color: Colors.grey[500],
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  'Image Error',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(
        _decryptedImageData!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Error displaying decrypted Firebase image: $error');
          return widget.errorWidget ??
              Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.broken_image,
                  color: Colors.grey[500],
                  size: 24,
                ),
              );
        },
      ),
    );
  }
}

/// Firebase encrypted image thumbnail widget for lists
class FirebaseEncryptedImageThumbnail extends StatelessWidget {
  final String downloadUrl;
  final double size;
  final VoidCallback? onTap;

  const FirebaseEncryptedImageThumbnail({
    super.key,
    required this.downloadUrl,
    this.size = 80,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: FirebaseEncryptedImageWidget(
          downloadUrl: downloadUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_download,
                  color: Colors.grey[400],
                  size: 16,
                ),
                const SizedBox(height: 2),
                Text(
                  'Loading...',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget builder for encrypted images with automatic detection
class SmartEncryptedImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const SmartEncryptedImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final encryptionService = ImageEncryptionService();
    
    // Check if it's a Firebase Storage URL
    if (encryptionService.isFirebaseStorageUrl(imageUrl)) {
      return FirebaseEncryptedImageWidget(
        downloadUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
      );
    }
    
    // Fallback to regular network image
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.image_not_supported,
              color: Colors.grey[500],
              size: 24,
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      ),
    );
  }
}
