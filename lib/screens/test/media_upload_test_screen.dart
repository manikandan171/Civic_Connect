import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/media_encryption_service.dart';

/// Test screen for demonstrating image and video Base64 storage in Firestore
class MediaUploadTestScreen extends StatefulWidget {
  const MediaUploadTestScreen({super.key});

  @override
  State<MediaUploadTestScreen> createState() => _MediaUploadTestScreenState();
}

class _MediaUploadTestScreenState extends State<MediaUploadTestScreen> {
  final MediaEncryptionService _mediaService = MediaEncryptionService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _logs = [];
  bool _isLoading = false;
  String? _testResult;

  // Test user ID
  final String _testUserId = 'test_user_123';

  @override
  void initState() {
    super.initState();
    _mediaService.initialize();
    _addLog('✅ MediaEncryptionService initialized');
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} - $message');
    });
    debugPrint(message);
  }

  // ============================================================================
  // IMAGE TESTS
  // ============================================================================

  Future<void> _testSingleImage() async {
    setState(() {
      _isLoading = true;
      _testResult = null;
      _logs.clear();
    });

    try {
      _addLog('📸 Starting single image test...');

      // Step 1: Pick image
      _addLog('📁 Opening image picker...');
      final imageFile = await _mediaService.pickImageFromGallery();

      if (imageFile == null) {
        _addLog('❌ No image selected');
        setState(() {
          _isLoading = false;
          _testResult = 'Test cancelled - no image selected';
        });
        return;
      }

      _addLog('✅ Image selected: ${imageFile.path}');

      // Step 2: Process image for Firestore
      _addLog('🔄 Processing image for Firestore...');
      final imageData = await _mediaService.processImageForFirestore(
        imageFile,
        _testUserId,
      );

      if (imageData == null) {
        _addLog('❌ Failed to process image');
        setState(() {
          _isLoading = false;
          _testResult = 'Failed to process image - might be too large';
        });
        return;
      }

      _addLog('✅ Image processed successfully');
      _addLog('📄 ID: ${imageData['id']}');
      _addLog(
        '📄 Size: ${_mediaService.getReadableSize(imageData['originalSize'])}',
      );
      _addLog('📄 Base64 length: ${imageData['encryptedData'].length} chars');

      // Step 3: Store in Firestore
      _addLog('💾 Storing in Firestore...');
      final docRef = _firestore.collection('test_media').doc(imageData['id']);
      await docRef.set(imageData);
      _addLog('✅ Stored in Firestore successfully');

      // Step 4: Retrieve and decrypt
      _addLog('📥 Retrieving from Firestore...');
      final snapshot = await docRef.get();
      final retrievedData = snapshot.data() as Map<String, dynamic>;

      final encryptedBase64 = retrievedData['encryptedData'] as String;
      _addLog('🔓 Decrypting image...');
      final decryptedBytes = _mediaService.decryptFromBase64(encryptedBase64);

      _addLog('✅ Image decrypted successfully');
      _addLog(
        '📄 Decrypted size: ${_mediaService.getReadableSize(decryptedBytes.length)}',
      );

      // Step 5: Clean up (optional)
      _addLog('🗑️ Cleaning up test document...');
      await docRef.delete();
      _addLog('✅ Test document deleted');

      setState(() {
        _testResult =
            '🎉 Single image test passed!\n\n'
            'Image was successfully:\n'
            '✓ Compressed\n'
            '✓ Encrypted\n'
            '✓ Stored as Base64 in Firestore\n'
            '✓ Retrieved and decrypted';
      });
    } catch (e) {
      _addLog('❌ Test failed with error: $e');
      setState(() {
        _testResult = '❌ Test failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testMultipleImages() async {
    setState(() {
      _isLoading = true;
      _testResult = null;
      _logs.clear();
    });

    try {
      _addLog('📸 Starting multiple images test...');

      // Step 1: Pick multiple images
      _addLog('📁 Opening image picker...');
      final imageFiles = await _mediaService.pickMultipleImages();

      if (imageFiles.isEmpty) {
        _addLog('❌ No images selected');
        setState(() {
          _isLoading = false;
          _testResult = 'Test cancelled - no images selected';
        });
        return;
      }

      _addLog('✅ ${imageFiles.length} images selected');

      // Step 2: Process images for Firestore
      _addLog('🔄 Processing images for Firestore...');
      final processedImages = await _mediaService.processImagesForFirestore(
        imageFiles,
        _testUserId,
      );

      _addLog(
        '✅ Processed ${processedImages.length}/${imageFiles.length} images',
      );

      if (processedImages.isEmpty) {
        _addLog('❌ No images were successfully processed');
        setState(() {
          _isLoading = false;
          _testResult = 'Failed to process images - might be too large';
        });
        return;
      }

      // Step 3: Store in Firestore
      _addLog('💾 Storing images in Firestore...');
      final batch = _firestore.batch();

      for (final imageData in processedImages) {
        final docRef = _firestore.collection('test_media').doc(imageData['id']);
        batch.set(docRef, imageData);
      }

      await batch.commit();
      _addLog('✅ Batch stored in Firestore successfully');

      // Step 4: Clean up
      _addLog('🗑️ Cleaning up test documents...');
      final cleanupBatch = _firestore.batch();

      for (final imageData in processedImages) {
        final docRef = _firestore.collection('test_media').doc(imageData['id']);
        cleanupBatch.delete(docRef);
      }

      await cleanupBatch.commit();
      _addLog('✅ Test documents deleted');

      setState(() {
        _testResult =
            '🎉 Multiple images test passed!\n\n'
            'Successfully processed ${processedImages.length} images:\n'
            '✓ Compressed\n'
            '✓ Encrypted\n'
            '✓ Stored as Base64 in Firestore\n'
            '✓ Batch operations';
      });
    } catch (e) {
      _addLog('❌ Test failed with error: $e');
      setState(() {
        _testResult = '❌ Test failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============================================================================
  // VIDEO TESTS
  // ============================================================================

  Future<void> _testSingleVideo() async {
    setState(() {
      _isLoading = true;
      _testResult = null;
      _logs.clear();
    });

    try {
      _addLog('🎥 Starting single video test...');

      // Step 1: Pick video
      _addLog('📁 Opening video picker...');
      final videoFile = await _mediaService.pickVideoFromGallery();

      if (videoFile == null) {
        _addLog('❌ No video selected');
        setState(() {
          _isLoading = false;
          _testResult = 'Test cancelled - no video selected';
        });
        return;
      }

      _addLog('✅ Video selected: ${videoFile.path}');
      final originalSize = await videoFile.length();
      _addLog(
        '📄 Original size: ${_mediaService.getReadableSize(originalSize)}',
      );

      // Step 2: Process video for Firestore
      _addLog('🔄 Processing video for Firestore (this may take a while)...');
      final videoData = await _mediaService.processVideoForFirestore(
        videoFile,
        _testUserId,
      );

      if (videoData == null) {
        _addLog('❌ Failed to process video');
        setState(() {
          _isLoading = false;
          _testResult = 'Failed to process video - might be too large';
        });
        return;
      }

      _addLog('✅ Video processed successfully');
      _addLog('📄 ID: ${videoData['id']}');
      _addLog('📄 Type: ${videoData['type']}');
      _addLog(
        '📄 Size: ${_mediaService.getReadableSize(videoData['originalSize'])}',
      );

      if (videoData['status'] == 'too_large_for_firestore') {
        _addLog('⚠️ ${videoData['message']}');
        _addLog('📸 Thumbnail was stored instead');

        setState(() {
          _testResult =
              '⚠️ Video is too large for Firestore\n\n'
              '${videoData['message']}\n\n'
              'A thumbnail was generated and stored instead.\n'
              'For large videos, consider using Firebase Storage.';
        });
        return;
      }

      _addLog('📄 Base64 length: ${videoData['encryptedData'].length} chars');

      // Step 3: Store in Firestore
      _addLog('💾 Storing in Firestore...');
      final docRef = _firestore.collection('test_media').doc(videoData['id']);
      await docRef.set(videoData);
      _addLog('✅ Stored in Firestore successfully');

      // Step 4: Retrieve and decrypt
      _addLog('📥 Retrieving from Firestore...');
      final snapshot = await docRef.get();
      final retrievedData = snapshot.data() as Map<String, dynamic>;

      final encryptedBase64 = retrievedData['encryptedData'] as String;
      _addLog('🔓 Decrypting video...');
      final decryptedBytes = _mediaService.decryptFromBase64(encryptedBase64);

      _addLog('✅ Video decrypted successfully');
      _addLog(
        '📄 Decrypted size: ${_mediaService.getReadableSize(decryptedBytes.length)}',
      );

      // Step 5: Clean up
      _addLog('🗑️ Cleaning up test document...');
      await docRef.delete();
      _addLog('✅ Test document deleted');

      setState(() {
        _testResult =
            '🎉 Single video test passed!\n\n'
            'Video was successfully:\n'
            '✓ Compressed\n'
            '✓ Encrypted\n'
            '✓ Stored as Base64 in Firestore\n'
            '✓ Retrieved and decrypted\n'
            '✓ Thumbnail generated';
      });
    } catch (e) {
      _addLog('❌ Test failed with error: $e');
      setState(() {
        _testResult = '❌ Test failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============================================================================
  // UI
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Base64 Storage Test'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Test Buttons
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Test Image & Video Base64 Storage in Firestore',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Image Tests
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testSingleImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Test Single Image'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testMultipleImages,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Test Multiple Images'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),

                const Divider(height: 24),

                // Video Tests
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testSingleVideo,
                  icon: const Icon(Icons.video_library),
                  label: const Text('Test Single Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                ),
              ],
            ),
          ),

          // Results
          if (_testResult != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _testResult!.contains('❌')
                    ? Colors.red[50]
                    : _testResult!.contains('⚠️')
                    ? Colors.orange[50]
                    : Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _testResult!.contains('❌')
                      ? Colors.red
                      : _testResult!.contains('⚠️')
                      ? Colors.orange
                      : Colors.green,
                ),
              ),
              child: Text(
                _testResult!,
                style: TextStyle(
                  color: _testResult!.contains('❌')
                      ? Colors.red[900]
                      : _testResult!.contains('⚠️')
                      ? Colors.orange[900]
                      : Colors.green[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // Loading Indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text(
                    'Processing... This may take a while for videos',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

          // Logs
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      _logs[index],
                      style: TextStyle(
                        color: _logs[index].contains('❌')
                            ? Colors.red[300]
                            : _logs[index].contains('✅')
                            ? Colors.green[300]
                            : _logs[index].contains('⚠️')
                            ? Colors.orange[300]
                            : Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mediaService.dispose();
    super.dispose();
  }
}
