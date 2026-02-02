# Media Base64 Storage in Firestore - Complete Guide

This guide demonstrates how to store images and videos as encrypted Base64 strings directly in Firestore using the `MediaEncryptionService`.

## 📋 Table of Contents
- [Overview](#overview)
- [Setup](#setup)
- [Basic Usage](#basic-usage)
- [Advanced Usage](#advanced-usage)
- [Best Practices](#best-practices)
- [Limitations](#limitations)
- [Examples](#examples)

## 🎯 Overview

The `MediaEncryptionService` provides a comprehensive solution for:
- **Image Processing**: Compress, encrypt, and store images as Base64 in Firestore
- **Video Processing**: Compress, encrypt, and store videos as Base64 in Firestore
- **Security**: AES-256 encryption for all media files
- **Size Management**: Automatic compression to fit Firestore's 1MB field limit
- **Thumbnail Generation**: Automatic video thumbnail generation

## 🔧 Setup

### 1. Add Dependencies

The required dependencies are already added to `pubspec.yaml`:

```yaml
dependencies:
  # Existing dependencies
  encrypt: ^5.0.3
  crypto: ^3.0.3
  image_picker: ^1.0.7
  
  # New dependencies for media compression
  flutter_image_compress: ^2.1.0
  video_compress: ^3.1.2
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Initialize the Service

In your `main.dart` or where you initialize services:

```dart
import 'package:your_app/services/media_encryption_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Media Encryption Service
  final mediaService = MediaEncryptionService();
  mediaService.initialize();
  
  runApp(MyApp());
}
```

## 📖 Basic Usage

### Image Upload

#### Single Image

```dart
import 'package:your_app/services/media_encryption_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final mediaService = MediaEncryptionService();
final firestore = FirebaseFirestore.instance;

// 1. Initialize service
mediaService.initialize();

// 2. Pick image from gallery
final imageFile = await mediaService.pickImageFromGallery();

if (imageFile != null) {
  // 3. Process image (compress, encrypt, convert to Base64)
  final imageData = await mediaService.processImageForFirestore(
    imageFile,
    'user_123', // Your user ID
  );
  
  if (imageData != null) {
    // 4. Store in Firestore
    await firestore.collection('images').doc(imageData['id']).set(imageData);
    
    print('✅ Image stored successfully!');
  } else {
    print('❌ Image too large or processing failed');
  }
}
```

#### Multiple Images

```dart
// 1. Pick multiple images
final imageFiles = await mediaService.pickMultipleImages();

if (imageFiles.isNotEmpty) {
  // 2. Process all images
  final processedImages = await mediaService.processImagesForFirestore(
    imageFiles,
    'user_123',
  );
  
  // 3. Store using batch operation
  final batch = firestore.batch();
  
  for (final imageData in processedImages) {
    final docRef = firestore.collection('images').doc(imageData['id']);
    batch.set(docRef, imageData);
  }
  
  await batch.commit();
  
  print('✅ ${processedImages.length} images stored successfully!');
}
```

### Video Upload

```dart
// 1. Pick video
final videoFile = await mediaService.pickVideoFromGallery();

if (videoFile != null) {
  // 2. Process video (compress, encrypt, convert to Base64)
  final videoData = await mediaService.processVideoForFirestore(
    videoFile,
    'user_123',
    generateThumbnail: true, // Optional: generate thumbnail
  );
  
  if (videoData != null) {
    // Check if video fits in Firestore
    if (videoData['status'] == 'too_large_for_firestore') {
      print('⚠️ Video is too large for Firestore');
      print('💡 Consider using Firebase Storage instead');
      // A thumbnail was generated and stored in videoData['encryptedData']
    } else {
      // 3. Store in Firestore
      await firestore.collection('videos').doc(videoData['id']).set(videoData);
      print('✅ Video stored successfully!');
    }
  }
}
```

### Retrieving and Decrypting Media

```dart
// 1. Retrieve from Firestore
final docSnapshot = await firestore.collection('images').doc('image_id').get();
final data = docSnapshot.data() as Map<String, dynamic>;

// 2. Get encrypted Base64 string
final encryptedBase64 = data['encryptedData'] as String;

// 3. Decrypt to bytes
final decryptedBytes = mediaService.decryptFromBase64(encryptedBase64);

// 4. Display in Flutter
// For images:
Image.memory(decryptedBytes)

// For videos, save to temp file first:
final tempDir = await getTemporaryDirectory();
final tempFile = File('${tempDir.path}/video.mp4');
await tempFile.writeAsBytes(decryptedBytes);
// Then use a video player with tempFile.path
```

## 🚀 Advanced Usage

### Custom Image Compression

```dart
final imageData = await mediaService.processImageForFirestore(
  imageFile,
  userId,
  quality: 75,        // Lower quality = smaller size (default: 85)
  maxWidth: 1280,     // Maximum width (default: 1920)
  maxHeight: 720,     // Maximum height (default: 1080)
);
```

### Storing with Issue Reports

```dart
// Example: Store images with an issue report
class IssueService {
  final mediaService = MediaEncryptionService();
  final firestore = FirebaseFirestore.instance;
  
  Future<void> submitIssue({
    required String title,
    required String description,
    required List<File> images,
    File? video,
    required String userId,
  }) async {
    // 1. Process images
    final processedImages = await mediaService.processImagesForFirestore(
      images,
      userId,
    );
    
    // 2. Process video (if provided)
    Map<String, dynamic>? processedVideo;
    if (video != null) {
      processedVideo = await mediaService.processVideoForFirestore(
        video,
        userId,
      );
    }
    
    // 3. Create issue document
    final issueData = {
      'id': 'issue_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'description': description,
      'userId': userId,
      'encryptedImages': processedImages,
      'encryptedVideo': processedVideo,
      'createdAt': FieldValue.serverTimestamp(),
    };
    
    // 4. Store in Firestore
    await firestore.collection('issues').doc(issueData['id']).set(issueData);
  }
}
```

### Displaying Encrypted Images in a List

```dart
class EncryptedImageWidget extends StatefulWidget {
  final String encryptedBase64;
  
  const EncryptedImageWidget({required this.encryptedBase64});
  
  @override
  State<EncryptedImageWidget> createState() => _EncryptedImageWidgetState();
}

class _EncryptedImageWidgetState extends State<EncryptedImageWidget> {
  final mediaService = MediaEncryptionService();
  Uint8List? decryptedBytes;
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _decryptImage();
  }
  
  Future<void> _decryptImage() async {
    try {
      mediaService.initialize();
      final bytes = mediaService.decryptFromBase64(widget.encryptedBase64);
      setState(() {
        decryptedBytes = bytes;
        isLoading = false;
      });
    } catch (e) {
      print('Error decrypting image: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const CircularProgressIndicator();
    }
    
    if (decryptedBytes == null) {
      return const Icon(Icons.error);
    }
    
    return Image.memory(decryptedBytes!);
  }
}
```

## 💡 Best Practices

### 1. **Always Compress Before Storing**
The service automatically compresses media, but you can adjust quality:

```dart
// For small file sizes (e.g., thumbnails)
processImageForFirestore(file, userId, quality: 60, maxWidth: 800, maxHeight: 600);

// For higher quality (e.g., important documents)
processImageForFirestore(file, userId, quality: 90, maxWidth: 2560, maxHeight: 1440);
```

### 2. **Handle Size Limits**
Always check if processing was successful:

```dart
final imageData = await mediaService.processImageForFirestore(file, userId);

if (imageData == null) {
  // Image is too large even after compression
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Image Too Large'),
      content: const Text('Please select a smaller image or lower quality photo.'),
    ),
  );
}
```

### 3. **Use Batch Operations**
For multiple images, use Firestore batch operations:

```dart
final batch = firestore.batch();

for (final imageData in processedImages) {
  final docRef = firestore.collection('images').doc(imageData['id']);
  batch.set(docRef, imageData);
}

await batch.commit(); // Single network call
```

### 4. **Error Handling**

```dart
try {
  final imageData = await mediaService.processImageForFirestore(file, userId);
  
  if (imageData != null) {
    await firestore.collection('images').doc(imageData['id']).set(imageData);
  }
} catch (e) {
  print('Error: $e');
  // Show user-friendly error message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Failed to upload image: $e')),
  );
}
```

### 5. **Clean Up Resources**
Dispose of video compression resources when done:

```dart
@override
void dispose() {
  mediaService.dispose(); // Cleans up video compression cache
  super.dispose();
}
```

## ⚠️ Limitations

### Firestore Field Size Limit
- **Maximum field size**: 1MB (1,048,576 bytes)
- **Recommended max**: 900KB to account for Base64 encoding overhead
- **Base64 overhead**: ~37% size increase

### File Size Guidelines

| Media Type | Recommended Max Size | After Compression | Base64 Size |
|------------|---------------------|-------------------|-------------|
| Image      | 2-3 MB (original)   | ~200-400 KB       | ~275-550 KB |
| Video      | 5-10 MB (original)  | ~500-800 KB       | ~685-1096 KB |

**Note**: Videos larger than ~650KB (before Base64 encoding) will likely exceed the 1MB Firestore limit.

### Alternative for Large Videos
For videos that exceed the Firestore limit, consider:

1. **Firebase Storage**: Store full video, only store URL in Firestore
2. **Chunking**: Split video into chunks (complex, not recommended)
3. **Thumbnail Only**: Store thumbnail in Firestore, full video in Storage

```dart
// Hybrid approach: Thumbnail in Firestore, full video in Storage
final videoData = await mediaService.processVideoForFirestore(video, userId);

if (videoData['status'] == 'too_large_for_firestore') {
  // Upload full video to Firebase Storage
  final storageRef = FirebaseStorage.instance.ref().child('videos/${userId}_${DateTime.now().millisecondsSinceEpoch}.mp4');
  await storageRef.putFile(video);
  final videoUrl = await storageRef.getDownloadURL();
  
  // Store thumbnail + URL in Firestore
  await firestore.collection('videos').doc(videoData['id']).set({
    ...videoData,
    'fullVideoUrl': videoUrl, // Store Storage URL
  });
}
```

## 📝 Examples

### Complete Issue Report Flow

```dart
class IssueReportScreen extends StatefulWidget {
  @override
  State<IssueReportScreen> createState() => _IssueReportScreenState();
}

class _IssueReportScreenState extends State<IssueReportScreen> {
  final mediaService = MediaEncryptionService();
  final firestore = FirebaseFirestore.instance;
  
  final List<File> selectedImages = [];
  File? selectedVideo;
  
  @override
  void initState() {
    super.initState();
    mediaService.initialize();
  }
  
  Future<void> pickImages() async {
    final images = await mediaService.pickMultipleImages();
    setState(() {
      selectedImages.addAll(images);
    });
  }
  
  Future<void> pickVideo() async {
    final video = await mediaService.pickVideoFromGallery();
    setState(() {
      selectedVideo = video;
    });
  }
  
  Future<void> submitIssue() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      // Process images
      final processedImages = await mediaService.processImagesForFirestore(
        selectedImages,
        'user_123',
      );
      
      // Process video
      Map<String, dynamic>? processedVideo;
      if (selectedVideo != null) {
        processedVideo = await mediaService.processVideoForFirestore(
          selectedVideo!,
          'user_123',
        );
      }
      
      // Create issue
      final issueData = {
        'id': 'issue_${DateTime.now().millisecondsSinceEpoch}',
        'title': 'Issue Title',
        'description': 'Issue Description',
        'encryptedImages': processedImages,
        'encryptedVideo': processedVideo,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      await firestore.collection('issues').doc(issueData['id']).set(issueData);
      
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Issue submitted successfully!')),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Issue')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: pickImages,
            child: const Text('Pick Images'),
          ),
          ElevatedButton(
            onPressed: pickVideo,
            child: const Text('Pick Video'),
          ),
          Text('${selectedImages.length} images selected'),
          Text(selectedVideo != null ? '1 video selected' : 'No video'),
          ElevatedButton(
            onPressed: submitIssue,
            child: const Text('Submit Issue'),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    mediaService.dispose();
    super.dispose();
  }
}
```

## 🧪 Testing

A test screen is provided at `lib/screens/test/media_upload_test_screen.dart`:

```dart
// Navigate to test screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const MediaUploadTestScreen(),
  ),
);
```

This test screen allows you to:
- Test single image upload
- Test multiple images upload
- Test video upload
- View detailed logs of the process
- Verify encryption/decryption

## 🔒 Security Notes

1. **Encryption**: All media is encrypted with AES-256 before storage
2. **Keys**: Currently using a fixed key (see `media_encryption_service.dart`)
3. **Production**: Consider using unique keys per user or per file
4. **Storage**: Encrypted data is stored as Base64 strings in Firestore

## 📚 Additional Resources

- [Flutter Image Compress Documentation](https://pub.dev/packages/flutter_image_compress)
- [Video Compress Documentation](https://pub.dev/packages/video_compress)
- [Firestore Limits](https://firebase.google.com/docs/firestore/quotas)
- [Firebase Storage](https://firebase.google.com/docs/storage) (alternative for large files)

## ❓ FAQ

**Q: Why not use Firebase Storage?**  
A: Base64 storage in Firestore is suitable for small to medium files and provides atomic operations with document data. For large files (>1MB), Firebase Storage is recommended.

**Q: What happens if my image is too large?**  
A: The service automatically attempts to compress with lower quality. If it still exceeds limits, `processImageForFirestore` returns `null`.

**Q: Can I store videos larger than 1MB?**  
A: Not directly in Firestore. The service will return a thumbnail instead. Use Firebase Storage for large videos.

**Q: Is the encryption secure?**  
A: Yes, AES-256 encryption is used. However, for production, consider implementing unique keys per user or file.

**Q: How do I display encrypted images in a ListView?**  
A: Use the `EncryptedImageWidget` example shown in the Advanced Usage section, or implement caching for better performance.

---

**Need help?** Check the test screen implementation for complete working examples!

