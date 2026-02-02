import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ImageEncryptionService {
  static final ImageEncryptionService _instance = ImageEncryptionService._internal();
  factory ImageEncryptionService() => _instance;
  ImageEncryptionService._internal();

  // AES encryption components
  late final encrypt.Encrypter _encrypter;
  late final encrypt.IV _iv;
  late final encrypt.Key _key;
  
  // Firebase Storage reference
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  
  // Track initialization state
  bool _isInitialized = false;
  
  void initialize() {
    // Prevent re-initialization
    if (_isInitialized) {
      debugPrint('🔐 ImageEncryptionService already initialized, skipping...');
      return;
    }
    
    // Generate a consistent 32-byte key for AES-256
    final keyString = 'SIH_CIVIC_CONNECT_2024_SECURE_KEY_FOR_IMAGES';
    final keyBytes = sha256.convert(utf8.encode(keyString)).bytes;
    _key = encrypt.Key(Uint8List.fromList(keyBytes));
    
    // Generate a fixed IV for consistency (in production, use unique IVs)
    _iv = encrypt.IV.fromBase64('SIVH2024CIVICCON'); // 16 bytes
    
    // Initialize AES encrypter
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
    
    _isInitialized = true;
    debugPrint('🔐 ImageEncryptionService initialized with AES-256 encryption');
  }

  /// Pick image from gallery and convert to bytes
  Future<Uint8List?> pickImageAsBytes() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return null;

      // Convert to bytes (binary data)
      Uint8List imageBytes = await image.readAsBytes();
      debugPrint('📷 Image picked: ${imageBytes.length} bytes');
      return imageBytes;
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      return null;
    }
  }

  /// Pick image from camera and convert to bytes
  Future<Uint8List?> captureImageAsBytes() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image == null) return null;

      // Convert to bytes (binary data)
      Uint8List imageBytes = await image.readAsBytes();
      debugPrint('📸 Image captured: ${imageBytes.length} bytes');
      return imageBytes;
    } catch (e) {
      debugPrint('❌ Error capturing image: $e');
      return null;
    }
  }

  /// Convert existing file to bytes
  Future<Uint8List?> fileToBytes(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }
      
      final imageBytes = await file.readAsBytes();
      debugPrint('📁 File converted to bytes: ${imageBytes.length} bytes');
      return imageBytes;
    } catch (e) {
      debugPrint('❌ Error converting file to bytes: $e');
      return null;
    }
  }

  /// Encrypt image bytes using AES-256
  Uint8List encryptImageBytes(Uint8List imageBytes) {
    try {
      debugPrint('🔐 Encrypting ${imageBytes.length} bytes with AES-256...');
      
      final encrypted = _encrypter.encryptBytes(imageBytes, iv: _iv);
      final encryptedBytes = encrypted.bytes;
      
      debugPrint('✅ Image encrypted: ${encryptedBytes.length} bytes');
      return encryptedBytes;
    } catch (e) {
      debugPrint('❌ Error encrypting image bytes: $e');
      throw Exception('Failed to encrypt image: $e');
    }
  }

  /// Decrypt image bytes using AES-256
  Uint8List decryptImageBytes(Uint8List encryptedBytes) {
    try {
      debugPrint('🔓 Decrypting ${encryptedBytes.length} bytes with AES-256...');
      
      final encrypted = encrypt.Encrypted(encryptedBytes);
      final decryptedBytes = _encrypter.decryptBytes(encrypted, iv: _iv);
      final result = Uint8List.fromList(decryptedBytes);
      
      debugPrint('✅ Image decrypted: ${result.length} bytes');
      return result;
    } catch (e) {
      debugPrint('❌ Error decrypting image bytes: $e');
      throw Exception('Failed to decrypt image: $e');
    }
  }

  /// Encrypt image and convert to Base64 for Firestore storage
  String encryptImageToBase64(Uint8List imageBytes) {
    try {
      debugPrint('🔐 Encrypting image for Firestore storage...');
      
      // Encrypt the image bytes
      final encryptedBytes = encryptImageBytes(imageBytes);
      
      // Convert to Base64 string
      final base64String = base64Encode(encryptedBytes);
      
      debugPrint('✅ Image encrypted and converted to Base64');
      debugPrint('📄 Original size: ${imageBytes.length} bytes');
      debugPrint('📄 Encrypted size: ${encryptedBytes.length} bytes');
      debugPrint('📄 Base64 size: ${base64String.length} characters');
      
      return base64String;
    } catch (e) {
      debugPrint('❌ Error encrypting image to Base64: $e');
      throw Exception('Failed to encrypt image: $e');
    }
  }

  /// Decrypt Base64 image from Firestore
  Uint8List decryptImageFromBase64(String base64String) {
    try {
      debugPrint('🔓 Decrypting Base64 image from Firestore...');
      
      // Convert Base64 back to bytes
      final encryptedBytes = base64Decode(base64String);
      
      // Decrypt the image bytes
      final decryptedBytes = decryptImageBytes(encryptedBytes);
      
      debugPrint('✅ Image decrypted from Base64');
      debugPrint('📄 Base64 size: ${base64String.length} characters');
      debugPrint('📄 Encrypted size: ${encryptedBytes.length} bytes');
      debugPrint('📄 Decrypted size: ${decryptedBytes.length} bytes');
      
      return decryptedBytes;
    } catch (e) {
      debugPrint('❌ Error decrypting Base64 image: $e');
      throw Exception('Failed to decrypt image: $e');
    }
  }

  /// Process multiple images for Firestore storage
  Future<List<Map<String, dynamic>>> processImagesForFirestore(List<File> imageFiles, String userId) async {
    final List<Map<String, dynamic>> processedImages = [];
    
    for (int i = 0; i < imageFiles.length; i++) {
      try {
        debugPrint('🔄 Processing image ${i + 1}/${imageFiles.length} for Firestore...');
        
        final imageFile = imageFiles[i];
        final imageBytes = await fileToBytes(imageFile.path);
        
        if (imageBytes == null) {
          debugPrint('❌ Failed to read image file: ${imageFile.path}');
          continue;
        }
        
        // Encrypt and convert to Base64
        final encryptedBase64 = encryptImageToBase64(imageBytes);
        
        // Create image metadata (simplified for Firestore compatibility)
        final imageData = <String, dynamic>{
          'id': 'img_${userId}_${DateTime.now().millisecondsSinceEpoch}_$i',
          'encryptedData': encryptedBase64,
          'originalFileName': imageFile.path.split('/').last,
          'originalSize': imageBytes.length,
          'encryptionVersion': 'AES-256-Base64-v1',
          'createdAt': DateTime.now().millisecondsSinceEpoch, // Use timestamp instead of string
          'userId': userId,
        };
        
        // Handle large images that exceed Firestore's 1MB field limit
        if (encryptedBase64.length > 1000000) {
          debugPrint('⚠️ Image too large for Firestore (${encryptedBase64.length} chars > 1MB limit)');
          debugPrint('🔄 Skipping large image - consider implementing image compression');
          continue; // Skip this image for now
        }
        
        processedImages.add(imageData);
        debugPrint('✅ Image ${i + 1} processed successfully');
        
      } catch (e) {
        debugPrint('❌ Failed to process image ${i + 1}: $e');
        // Continue with other images
      }
    }
    
    debugPrint('📤 Processed ${processedImages.length}/${imageFiles.length} images for Firestore');
    return processedImages;
  }

  /// Download and decrypt image from Firebase Storage
  Future<Uint8List?> downloadAndDecryptImage(String downloadUrl) async {
    try {
      debugPrint('🔓 Downloading encrypted image from Firebase Storage...');
      
      // Extract file name from URL to get storage reference
      final uri = Uri.parse(downloadUrl);
      final pathSegments = uri.pathSegments;
      final fileName = pathSegments.last.split('?').first; // Remove query parameters
      
      // Get reference to the file in Firebase Storage
      final storageRef = _storage.ref().child('images/encrypted/$fileName');
      
      // Download the encrypted data
      final Uint8List? encryptedData = await storageRef.getData();
      if (encryptedData == null) {
        throw Exception('Failed to download encrypted image data');
      }
      
      debugPrint('📥 Downloaded encrypted data: ${encryptedData.length} bytes');
      
      // Decrypt the image bytes
      final decryptedBytes = decryptImageBytes(encryptedData);
      
      debugPrint('✅ Image downloaded and decrypted successfully');
      return decryptedBytes;
    } catch (e) {
      debugPrint('❌ Error downloading and decrypting image: $e');
      return null;
    }
  }

  /// Download encrypted image by file name
  Future<Uint8List?> downloadEncryptedImageByName(String fileName) async {
    try {
      debugPrint('🔓 Downloading encrypted image by name: $fileName');
      
      final storageRef = _storage.ref().child('images/encrypted/$fileName');
      
      // Download the encrypted data
      final Uint8List? encryptedData = await storageRef.getData();
      if (encryptedData == null) {
        throw Exception('Failed to download encrypted image data');
      }
      
      debugPrint('📥 Downloaded encrypted data: ${encryptedData.length} bytes');
      
      // Decrypt the image bytes
      final decryptedBytes = decryptImageBytes(encryptedData);
      
      debugPrint('✅ Image downloaded and decrypted successfully');
      return decryptedBytes;
    } catch (e) {
      debugPrint('❌ Error downloading encrypted image by name: $e');
      return null;
    }
  }

  /// Legacy method for backward compatibility - now downloads from Firebase
  Future<Uint8List> decryptImage(String imageUrl) async {
    try {
      debugPrint('🔓 Legacy decryptImage called with: $imageUrl');
      
      // Check if it's a Firebase Storage URL
      if (imageUrl.contains('firebasestorage.googleapis.com')) {
        final result = await downloadAndDecryptImage(imageUrl);
        if (result != null) {
          return result;
        }
      }
      
      // Fallback: try as local file path
      final encryptedFile = File(imageUrl);
      if (await encryptedFile.exists()) {
        final encryptedBytes = await encryptedFile.readAsBytes();
        return decryptImageBytes(encryptedBytes);
      }
      
      throw Exception('Could not decrypt image from: $imageUrl');
    } catch (e) {
      debugPrint('❌ Error in legacy decryptImage: $e');
      throw Exception('Failed to decrypt image: $e');
    }
  }

  /// Check if a URL is a Firebase Storage URL
  bool isFirebaseStorageUrl(String url) {
    return url.contains('firebasestorage.googleapis.com');
  }

  /// Check if a path is an encrypted file
  bool isEncryptedFile(String path) {
    return path.endsWith('.enc') || isFirebaseStorageUrl(path);
  }

  /// Utility method to process multiple images for Firestore
  Future<List<String>> processMultipleImagesForFirestore(List<Uint8List> imageBytesList, String userId) async {
    final List<String> base64Images = [];
    
    for (int i = 0; i < imageBytesList.length; i++) {
      try {
        final base64String = encryptImageToBase64(imageBytesList[i]);
        base64Images.add(base64String);
        debugPrint('✅ Processed image ${i + 1}/${imageBytesList.length} for Firestore');
      } catch (e) {
        debugPrint('❌ Failed to process image ${i + 1}: $e');
        // Continue with other images
      }
    }
    
    debugPrint('📤 Processed ${base64Images.length}/${imageBytesList.length} images for Firestore');
    return base64Images;
  }

  /// Test Firebase Storage permissions and connectivity
  Future<bool> testFirebaseStorageAccess(String userId) async {
    try {
      debugPrint('🔥 Testing Firebase Storage access for user: $userId');
      
      // Test 1: Basic write permission
      final testRef = _storage.ref().child('test/access_test_${userId}_${DateTime.now().millisecondsSinceEpoch}.txt');
      await testRef.putString('Access test from SIH Civic Connect');
      debugPrint('✅ Firebase Storage write access confirmed');
      
      // Test 2: Read permission
      final downloadUrl = await testRef.getDownloadURL();
      debugPrint('✅ Firebase Storage read access confirmed');
      debugPrint('📄 Test URL: ${downloadUrl.substring(0, 50)}...');
      
      // Test 3: Delete permission
      await testRef.delete();
      debugPrint('✅ Firebase Storage delete access confirmed');
      
      // Test 4: Directory structure access
      final imageTestRef = _storage.ref().child('images/encrypted/test_${userId}.txt');
      await imageTestRef.putString('Directory test');
      await imageTestRef.delete();
      debugPrint('✅ Firebase Storage directory access confirmed');
      
      return true;
    } catch (e) {
      debugPrint('❌ Firebase Storage access test failed: $e');
      debugPrint('📄 This might be a Firebase Security Rules issue');
      debugPrint('📄 Check your Firebase Storage rules allow authenticated users to read/write');
      return false;
    }
  }

  /// Legacy method for backward compatibility - converts file to bytes and uploads
  Future<String> encryptAndSaveImage(String originalImagePath, String userId) async {
    try {
      debugPrint('🔄 Legacy encryptAndSaveImage called - converting to Firebase Storage...');
      
      // Convert file to bytes
      final imageBytes = await fileToBytes(originalImagePath);
      if (imageBytes == null) {
        throw Exception('Failed to convert file to bytes');
      }
      
      // Convert to Base64 for Firestore storage (legacy compatibility)
      final base64String = encryptImageToBase64(imageBytes);
      
      debugPrint('✅ Legacy method completed - converted to Base64 for Firestore');
      return base64String; // Return Base64 string instead of URL
    } catch (e) {
      debugPrint('❌ Error in legacy encryptAndSaveImage: $e');
      throw Exception('Failed to encrypt and save image: $e');
    }
  }
}
