import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/image_encryption_service.dart';
import '../../widgets/firebase_encrypted_image_widget.dart';

class EncryptionTestScreen extends StatefulWidget {
  const EncryptionTestScreen({super.key});

  @override
  State<EncryptionTestScreen> createState() => _EncryptionTestScreenState();
}

class _EncryptionTestScreenState extends State<EncryptionTestScreen> {
  final ImageEncryptionService _encryptionService = ImageEncryptionService();
  bool _isLoading = false;
  String? _uploadedImageUrl;
  String? _testResult;
  List<String> _testLogs = [];

  @override
  void initState() {
    super.initState();
    _encryptionService.initialize();
  }

  void _addLog(String message) {
    setState(() {
      _testLogs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
    debugPrint(message);
  }

  Future<void> _testImageEncryption() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!authProvider.isAuthenticated) {
      _addLog('❌ User not authenticated');
      return;
    }

    setState(() {
      _isLoading = true;
      _testResult = null;
      _testLogs.clear();
      _uploadedImageUrl = null;
    });

    try {
      _addLog('🚀 Starting Firebase Storage encryption test...');
      
      // Step 1: Pick image from gallery
      _addLog('📷 Picking image from gallery...');
      final imageBytes = await _encryptionService.pickImageAsBytes();
      
      if (imageBytes == null) {
        _addLog('❌ No image selected');
        setState(() {
          _testResult = 'Test cancelled - no image selected';
          _isLoading = false;
        });
        return;
      }
      
      _addLog('✅ Image picked: ${imageBytes.length} bytes');
      
      // Step 2: Test encryption
      _addLog('🔐 Testing AES-256 encryption...');
      final encryptedBytes = _encryptionService.encryptImageBytes(imageBytes);
      _addLog('✅ Image encrypted: ${encryptedBytes.length} bytes');
      
      // Step 3: Test decryption
      _addLog('🔓 Testing AES-256 decryption...');
      final decryptedBytes = _encryptionService.decryptImageBytes(encryptedBytes);
      _addLog('✅ Image decrypted: ${decryptedBytes.length} bytes');
      
      // Step 4: Verify integrity
      if (imageBytes.length == decryptedBytes.length) {
        bool isIdentical = true;
        for (int i = 0; i < imageBytes.length; i++) {
          if (imageBytes[i] != decryptedBytes[i]) {
            isIdentical = false;
            break;
          }
        }
        
        if (isIdentical) {
          _addLog('✅ Encryption/Decryption integrity verified');
        } else {
        }
      } else {
        _addLog('❌ Size mismatch after encryption/decryption');
      }
      
      // Step 5: Convert to Base64 for Firestore storage
      _addLog('🔥 Converting encrypted image to Base64 for Firestore...');
      final base64String = _encryptionService.encryptImageToBase64(imageBytes);
      
      _addLog('✅ Image converted to Base64 successfully');
      _addLog('📄 Base64 length: ${base64String.length} characters');
      
      setState(() {
        _uploadedImageUrl = 'firestore_base64_image'; // Placeholder for display
      });
      
      // Step 6: Test decryption from Base64
      _addLog('📥 Testing decryption from Base64...');
      final decryptedFromBase64 = _encryptionService.decryptImageFromBase64(base64String);
      
      _addLog('✅ Image decrypted from Base64: ${decryptedFromBase64.length} bytes');
      
      // Verify Base64 round-trip integrity
      if (imageBytes.length == decryptedFromBase64.length) {
        bool isIdentical = true;
        for (int i = 0; i < imageBytes.length; i++) {
          if (imageBytes[i] != decryptedFromBase64[i]) {
            isIdentical = false;
            break;
          }
        }
        
        if (isIdentical) {
          _addLog('✅ Base64 round-trip integrity verified');
          setState(() {
            _testResult = '🎉 All tests passed! Firestore Base64 encryption working perfectly.';
          });
        } else {
          _addLog('❌ Base64 round-trip integrity failed');
          setState(() {
            _testResult = '❌ Test failed: Base64 image doesn\'t match original';
          });
        }
      } else {
        _addLog('❌ Base64 image size mismatch');
        setState(() {
          _testResult = '❌ Test failed: Base64 image size mismatch';
        });
      }
      
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

  Future<void> _testCameraCapture() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!authProvider.isAuthenticated) {
      _addLog('❌ User not authenticated');
      return;
    }

    setState(() {
      _isLoading = true;
      _testResult = null;
      _testLogs.clear();
      _uploadedImageUrl = null;
    });

    try {
      _addLog('📸 Testing camera capture...');
      
      final imageBytes = await _encryptionService.captureImageAsBytes();
      
      if (imageBytes == null) {
        _addLog('❌ No image captured');
        setState(() {
          _testResult = 'Test cancelled - no image captured';
          _isLoading = false;
        });
        return;
      }
      
      _addLog('✅ Image captured: ${imageBytes.length} bytes');
      
      // Convert the captured image to Base64
      final currentUser = authProvider.currentUser!;
      final base64String = _encryptionService.encryptImageToBase64(imageBytes);
      
      _addLog('✅ Camera image encrypted to Base64 successfully');
      _addLog('📄 Base64 length: ${base64String.length} characters');
      
      setState(() {
        _uploadedImageUrl = 'firestore_camera_base64'; // Placeholder
        _testResult = '📸 Camera test successful!';
      });
      
    } catch (e) {
      _addLog('❌ Camera test failed: $e');
      setState(() {
        _testResult = '❌ Camera test failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Encryption Test'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testImageEncryption,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Test Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testCameraCapture,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Test Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Loading indicator
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Running encryption tests...'),
                  ],
                ),
              ),
            
            // Test result
            if (_testResult != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testResult!.startsWith('🎉') 
                      ? Colors.green[100] 
                      : _testResult!.startsWith('❌')
                          ? Colors.red[100]
                          : Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _testResult!.startsWith('🎉')
                        ? Colors.green
                        : _testResult!.startsWith('❌')
                            ? Colors.red
                            : Colors.blue,
                  ),
                ),
                child: Text(
                  _testResult!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Uploaded image display
            if (_uploadedImageUrl != null) ...[
              const Text(
                'Encrypted Image from Firebase Storage:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FirebaseEncryptedImageWidget(
                  downloadUrl: _uploadedImageUrl!,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Test logs
            const Text(
              'Test Logs:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _testLogs.isEmpty
                    ? const Center(
                        child: Text(
                          'No test logs yet. Run a test to see logs.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _testLogs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              _testLogs[index],
                              style: const TextStyle(
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
      ),
    );
  }
}
