import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/image_encryption_service.dart';

class EncryptedImageWidget extends StatefulWidget {
  final String encryptedImagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const EncryptedImageWidget({
    super.key,
    required this.encryptedImagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<EncryptedImageWidget> createState() => _EncryptedImageWidgetState();
}

class _EncryptedImageWidgetState extends State<EncryptedImageWidget> {
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

      debugPrint('🔓 Loading encrypted image: ${widget.encryptedImagePath}');
      
      // Check if file exists
      if (!await File(widget.encryptedImagePath).exists()) {
        throw Exception('Encrypted image file not found');
      }

      // Decrypt the image
      final decryptedData = await _encryptionService.decryptImage(widget.encryptedImagePath);
      
      if (mounted) {
        setState(() {
          _decryptedImageData = decryptedData;
          _isLoading = false;
        });
        debugPrint('✅ Image decrypted and loaded successfully');
      }
    } catch (e) {
      debugPrint('❌ Error loading encrypted image: $e');
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
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
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
          debugPrint('❌ Error displaying decrypted image: $error');
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

/// Encrypted image thumbnail widget for lists
class EncryptedImageThumbnail extends StatelessWidget {
  final String encryptedImagePath;
  final double size;
  final VoidCallback? onTap;

  const EncryptedImageThumbnail({
    super.key,
    required this.encryptedImagePath,
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
        child: EncryptedImageWidget(
          encryptedImagePath: encryptedImagePath,
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
                  Icons.lock,
                  color: Colors.grey[400],
                  size: 16,
                ),
                const SizedBox(height: 2),
                Text(
                  'Decrypting...',
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
