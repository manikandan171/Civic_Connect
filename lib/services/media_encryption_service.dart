import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
// Note: video_compress removed due to build issues
// Videos are now stored directly without compression

/// Service for encrypting and storing images and videos as Base64 in Firestore
class MediaEncryptionService {
  static final MediaEncryptionService _instance =
      MediaEncryptionService._internal();
  factory MediaEncryptionService() => _instance;
  MediaEncryptionService._internal();

  // AES encryption components
  late final encrypt.Encrypter _encrypter;
  late final encrypt.IV _iv;
  late final encrypt.Key _key;

  final ImagePicker _picker = ImagePicker();

  // Track initialization state
  bool _isInitialized = false;

  // Firestore field size limit (1MB - leave some margin)
  static const int maxFieldSize = 900000; // 900KB to be safe

  void initialize() {
    // Prevent re-initialization
    if (_isInitialized) {
      debugPrint('🔐 MediaEncryptionService already initialized, skipping...');
      return;
    }

    // Generate a consistent 32-byte key for AES-256
    final keyString = 'SIH_CIVIC_CONNECT_2024_SECURE_KEY_FOR_MEDIA';
    final keyBytes = sha256.convert(utf8.encode(keyString)).bytes;
    _key = encrypt.Key(Uint8List.fromList(keyBytes));

    // Generate a fixed IV for consistency (in production, use unique IVs)
    _iv = encrypt.IV.fromBase64('SIVH2024CIVICCON'); // 16 bytes

    // Initialize AES encrypter
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));

    _isInitialized = true;
    debugPrint('🔐 MediaEncryptionService initialized with AES-256 encryption');
  }

  // ============================================================================
  // IMAGE PROCESSING
  // ============================================================================

  /// Compress image to reduce size before Base64 encoding
  Future<Uint8List?> compressImage(
    File imageFile, {
    int quality = 85,
    int maxWidth = 1920,
    int maxHeight = 1080,
  }) async {
    try {
      debugPrint('🔄 Compressing image: ${imageFile.path}');

      final result = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
      );

      if (result != null) {
        debugPrint(
          '✅ Image compressed: ${result.length} bytes (${(result.length / 1024).toStringAsFixed(2)} KB)',
        );
        return result;
      }

      debugPrint('⚠️ Compression returned null, using original file');
      return await imageFile.readAsBytes();
    } catch (e) {
      debugPrint('❌ Error compressing image: $e');
      return await imageFile.readAsBytes();
    }
  }

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      return null;
    }
  }

  /// Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      return null;
    }
  }

  /// Pick multiple images
  Future<List<File>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      return images.map((xfile) => File(xfile.path)).toList();
    } catch (e) {
      debugPrint('❌ Error picking multiple images: $e');
      return [];
    }
  }

  // ============================================================================
  // VIDEO PROCESSING
  // ============================================================================

  /// Pick video from gallery
  Future<File?> pickVideoFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        return File(video.path);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error picking video: $e');
      return null;
    }
  }

  /// Pick video from camera
  Future<File?> pickVideoFromCamera() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
      if (video != null) {
        return File(video.path);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error picking video: $e');
      return null;
    }
  }

  /// Check video file size (no compression available without video_compress)
  /// Note: For production, consider using Firebase Storage for videos
  Future<int> getVideoSize(File videoFile) async {
    try {
      final size = await videoFile.length();
      debugPrint(
        '📹 Video size: $size bytes (${(size / 1024 / 1024).toStringAsFixed(2)} MB)',
      );
      return size;
    } catch (e) {
      debugPrint('❌ Error getting video size: $e');
      return 0;
    }
  }

  /// Get video thumbnail (placeholder - returns null without video_compress)
  /// For production, consider using video_player or video_thumbnail packages
  Future<Uint8List?> getVideoThumbnail(String videoPath) async {
    debugPrint(
      '⚠️ Video thumbnail generation not available (video_compress disabled)',
    );
    debugPrint('💡 Consider using Firebase Storage for videos instead');
    return null;
  }

  // ============================================================================
  // ENCRYPTION & BASE64 CONVERSION
  // ============================================================================

  /// Convert file to bytes
  Future<Uint8List?> fileToBytes(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      final bytes = await file.readAsBytes();
      debugPrint('📁 File converted to bytes: ${bytes.length} bytes');
      return bytes;
    } catch (e) {
      debugPrint('❌ Error converting file to bytes: $e');
      return null;
    }
  }

  /// Encrypt bytes using AES-256
  Uint8List encryptBytes(Uint8List bytes) {
    try {
      debugPrint('🔐 Encrypting ${bytes.length} bytes with AES-256...');

      final encrypted = _encrypter.encryptBytes(bytes, iv: _iv);
      final encryptedBytes = encrypted.bytes;

      debugPrint('✅ Encrypted: ${encryptedBytes.length} bytes');
      return encryptedBytes;
    } catch (e) {
      debugPrint('❌ Error encrypting bytes: $e');
      throw Exception('Failed to encrypt: $e');
    }
  }

  /// Decrypt bytes using AES-256
  Uint8List decryptBytes(Uint8List encryptedBytes) {
    try {
      debugPrint(
        '🔓 Decrypting ${encryptedBytes.length} bytes with AES-256...',
      );

      final encrypted = encrypt.Encrypted(encryptedBytes);
      final decryptedBytes = _encrypter.decryptBytes(encrypted, iv: _iv);
      final result = Uint8List.fromList(decryptedBytes);

      debugPrint('✅ Decrypted: ${result.length} bytes');
      return result;
    } catch (e) {
      debugPrint('❌ Error decrypting bytes: $e');
      throw Exception('Failed to decrypt: $e');
    }
  }

  /// Encrypt and convert to Base64 for Firestore storage
  String encryptToBase64(Uint8List bytes) {
    try {
      debugPrint('🔐 Encrypting for Firestore storage...');

      // Encrypt the bytes
      final encryptedBytes = encryptBytes(bytes);

      // Convert to Base64 string
      final base64String = base64Encode(encryptedBytes);

      debugPrint('✅ Encrypted and converted to Base64');
      debugPrint('📄 Original size: ${bytes.length} bytes');
      debugPrint('📄 Encrypted size: ${encryptedBytes.length} bytes');
      debugPrint('📄 Base64 size: ${base64String.length} characters');

      return base64String;
    } catch (e) {
      debugPrint('❌ Error encrypting to Base64: $e');
      throw Exception('Failed to encrypt: $e');
    }
  }

  /// Decrypt from Base64
  Uint8List decryptFromBase64(String base64String) {
    try {
      debugPrint('🔓 Decrypting Base64 from Firestore...');

      // Convert Base64 back to bytes
      final encryptedBytes = base64Decode(base64String);

      // Decrypt the bytes
      final decryptedBytes = decryptBytes(encryptedBytes);

      debugPrint('✅ Decrypted from Base64');
      debugPrint('📄 Base64 size: ${base64String.length} characters');
      debugPrint('📄 Encrypted size: ${encryptedBytes.length} bytes');
      debugPrint('📄 Decrypted size: ${decryptedBytes.length} bytes');

      return decryptedBytes;
    } catch (e) {
      debugPrint('❌ Error decrypting from Base64: $e');
      throw Exception('Failed to decrypt: $e');
    }
  }

  // ============================================================================
  // FIRESTORE PROCESSING - IMAGES
  // ============================================================================

  /// Process single image for Firestore with compression and size checking
  Future<Map<String, dynamic>?> processImageForFirestore(
    File imageFile,
    String userId, {
    int quality = 85,
    int maxWidth = 1920,
    int maxHeight = 1080,
  }) async {
    try {
      debugPrint('🔄 Processing image for Firestore...');

      // Step 1: Compress image
      final compressedBytes = await compressImage(
        imageFile,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (compressedBytes == null) {
        debugPrint('❌ Failed to read image file');
        return null;
      }

      // Step 2: Encrypt and convert to Base64
      final encryptedBase64 = encryptToBase64(compressedBytes);

      // Step 3: Check if it exceeds Firestore limit
      if (encryptedBase64.length > maxFieldSize) {
        debugPrint(
          '⚠️ Image too large for Firestore (${encryptedBase64.length} chars > ${maxFieldSize} limit)',
        );

        // Try with lower quality
        if (quality > 50) {
          debugPrint('🔄 Retrying with lower quality...');
          return await processImageForFirestore(
            imageFile,
            userId,
            quality: 50,
            maxWidth: 1280,
            maxHeight: 720,
          );
        }

        debugPrint('❌ Image still too large even after compression');
        return null;
      }

      // Step 4: Create metadata
      final imageData = {
        'id': 'img_${userId}_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'image',
        'encryptedData': encryptedBase64,
        'originalFileName': imageFile.path.split('/').last,
        'originalSize': compressedBytes.length,
        'encryptionVersion': 'AES-256-Base64-v1',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'userId': userId,
      };

      debugPrint('✅ Image processed successfully for Firestore');
      return imageData;
    } catch (e) {
      debugPrint('❌ Failed to process image: $e');
      return null;
    }
  }

  /// Process multiple images for Firestore
  Future<List<Map<String, dynamic>>> processImagesForFirestore(
    List<File> imageFiles,
    String userId,
  ) async {
    final List<Map<String, dynamic>> processedImages = [];

    for (int i = 0; i < imageFiles.length; i++) {
      try {
        debugPrint('🔄 Processing image ${i + 1}/${imageFiles.length}...');

        final imageData = await processImageForFirestore(imageFiles[i], userId);

        if (imageData != null) {
          // Update ID to include index
          imageData['id'] =
              'img_${userId}_${DateTime.now().millisecondsSinceEpoch}_$i';
          processedImages.add(imageData);
          debugPrint('✅ Image ${i + 1} processed successfully');
        }
      } catch (e) {
        debugPrint('❌ Failed to process image ${i + 1}: $e');
      }
    }

    debugPrint(
      '📤 Processed ${processedImages.length}/${imageFiles.length} images for Firestore',
    );
    return processedImages;
  }

  // ============================================================================
  // FIRESTORE PROCESSING - VIDEOS
  // ============================================================================

  /// Process single video for Firestore (without compression)
  /// Note: Most videos will be too large for Firestore's 1MB limit
  /// Recommendation: Use Firebase Storage for videos instead
  Future<Map<String, dynamic>?> processVideoForFirestore(
    File videoFile,
    String userId, {
    bool generateThumbnail = true,
  }) async {
    try {
      debugPrint('🔄 Processing video for Firestore...');
      debugPrint(
        '⚠️ Video compression is disabled. Most videos will exceed Firestore limits.',
      );

      // Step 1: Check video size
      final videoSize = await getVideoSize(videoFile);

      if (videoSize == 0) {
        debugPrint('❌ Failed to read video file');
        return null;
      }

      // Step 2: Read video bytes
      final videoBytes = await videoFile.readAsBytes();
      debugPrint(
        '📹 Video size: ${videoBytes.length} bytes (${(videoBytes.length / 1024 / 1024).toStringAsFixed(2)} MB)',
      );

      // Step 3: Check if video is too large for Firestore
      final estimatedBase64Size = (videoBytes.length * 1.37)
          .toInt(); // Base64 increases size by ~37%

      if (estimatedBase64Size > maxFieldSize) {
        debugPrint(
          '⚠️ Video too large for Firestore (${estimatedBase64Size} chars > ${maxFieldSize} limit)',
        );
        debugPrint('💡 Recommendation: Use Firebase Storage for videos');
        debugPrint(
          '💡 See documentation for Firebase Storage integration example',
        );

        // Return metadata indicating video is too large
        return {
          'id': 'vid_${userId}_${DateTime.now().millisecondsSinceEpoch}',
          'type': 'video_too_large',
          'originalFileName': videoFile.path.split('/').last,
          'originalSize': videoBytes.length,
          'estimatedBase64Size': estimatedBase64Size,
          'status': 'too_large_for_firestore',
          'message':
              'Video is too large for Firestore (${(videoBytes.length / 1024 / 1024).toStringAsFixed(2)} MB). Use Firebase Storage instead.',
          'recommendation':
              'Upload to Firebase Storage and store the download URL in Firestore',
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'userId': userId,
        };
      }

      // Step 4: If video is small enough, encrypt and convert to Base64
      debugPrint('✅ Video is small enough for Firestore, encrypting...');
      final encryptedBase64 = encryptToBase64(videoBytes);

      // Step 5: Create metadata
      final videoData = {
        'id': 'vid_${userId}_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'video',
        'encryptedData': encryptedBase64,
        'originalFileName': videoFile.path.split('/').last,
        'originalSize': videoBytes.length,
        'encryptionVersion': 'AES-256-Base64-v1',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'userId': userId,
        'note': 'Video stored without compression',
      };

      debugPrint('✅ Video processed successfully for Firestore');
      return videoData;
    } catch (e) {
      debugPrint('❌ Failed to process video: $e');
      return null;
    }
  }

  /// Process multiple videos for Firestore
  Future<List<Map<String, dynamic>>> processVideosForFirestore(
    List<File> videoFiles,
    String userId,
  ) async {
    final List<Map<String, dynamic>> processedVideos = [];

    for (int i = 0; i < videoFiles.length; i++) {
      try {
        debugPrint('🔄 Processing video ${i + 1}/${videoFiles.length}...');

        final videoData = await processVideoForFirestore(videoFiles[i], userId);

        if (videoData != null) {
          // Update ID to include index
          videoData['id'] =
              'vid_${userId}_${DateTime.now().millisecondsSinceEpoch}_$i';
          processedVideos.add(videoData);
          debugPrint('✅ Video ${i + 1} processed successfully');
        }
      } catch (e) {
        debugPrint('❌ Failed to process video ${i + 1}: $e');
      }
    }

    debugPrint(
      '📤 Processed ${processedVideos.length}/${videoFiles.length} videos for Firestore',
    );
    return processedVideos;
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Check if Base64 string exceeds Firestore field limit
  bool exceedsFirestoreLimit(String base64String) {
    return base64String.length > maxFieldSize;
  }

  /// Get human-readable size
  String getReadableSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }

  /// Clean up resources
  void dispose() {
    // No cleanup needed without video_compress
    debugPrint('🧹 MediaEncryptionService disposed');
  }
}
