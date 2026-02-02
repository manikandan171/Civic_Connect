import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/image_encryption_service.dart';

class SimpleUploadTest extends StatefulWidget {
  const SimpleUploadTest({super.key});

  @override
  State<SimpleUploadTest> createState() => _SimpleUploadTestState();
}

class _SimpleUploadTestState extends State<SimpleUploadTest> {
  final ImageEncryptionService _encryptionService = ImageEncryptionService();
  bool _isLoading = false;
  String _status = 'Ready to test Firestore Base64 encryption';
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _encryptionService.initialize();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
    debugPrint(message);
  }

  Future<void> _testFirestoreEncryption() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing Firestore Base64 encryption...';
      _logs.clear();
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (!authProvider.isAuthenticated) {
        _addLog('❌ User not authenticated');
        setState(() {
          _status = 'Error: User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final currentUser = authProvider.currentUser!;
      _addLog('👤 Current user: ${currentUser.email}');

      // Test 1: Image picker
      _addLog('📷 Testing image picker...');
      final imageBytes = await _encryptionService.pickImageAsBytes();
      
      if (imageBytes == null) {
        _addLog('❌ No image selected');
        setState(() {
          _status = 'Test cancelled - no image selected';
          _isLoading = false;
        });
        return;
      }

      _addLog('✅ Image picked: ${imageBytes.length} bytes');

      // Test 2: Encryption
      _addLog('🔐 Testing AES-256 encryption...');
      final encryptedBytes = _encryptionService.encryptImageBytes(imageBytes);
      _addLog('✅ Image encrypted: ${encryptedBytes.length} bytes');

      // Test 3: Convert to Base64 for Firestore
      _addLog('🔥 Converting to Base64 for Firestore storage...');
      final base64String = _encryptionService.encryptImageToBase64(imageBytes);
      _addLog('✅ Base64 conversion successful!');
      _addLog('📄 Base64 length: ${base64String.length} characters');

      // Test 4: Decrypt from Base64
      _addLog('📥 Testing decryption from Base64...');
      final decryptedBytes = _encryptionService.decryptImageFromBase64(base64String);
      
      _addLog('✅ Base64 decryption successful: ${decryptedBytes.length} bytes');
        
      // Test 5: Verify integrity
      if (imageBytes.length == decryptedBytes.length) {
        bool isIdentical = true;
        for (int i = 0; i < imageBytes.length; i++) {
          if (imageBytes[i] != decryptedBytes[i]) {
            isIdentical = false;
            break;
          }
        }
        
        if (isIdentical) {
          _addLog('✅ Data integrity verified - perfect match!');
          setState(() {
            _status = '🎉 All tests passed! Firestore Base64 encryption working perfectly.';
          });
        } else {
          _addLog('❌ Data integrity check failed - bytes don\'t match');
          setState(() {
            _status = '❌ Data integrity check failed';
          });
        }
      } else {
        _addLog('❌ Size mismatch: original ${imageBytes.length} vs decrypted ${decryptedBytes.length}');
        setState(() {
          _status = '❌ Size mismatch after encryption/decryption';
        });
      }

    } catch (e, stackTrace) {
      _addLog('❌ Test failed with error: $e');
      _addLog('📄 Stack trace: ${stackTrace.toString().substring(0, 200)}...');
      setState(() {
        _status = 'Test failed: $e';
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
        title: const Text('Firestore Base64 Test'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testFirestoreEncryption,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.security),
              label: Text(_isLoading ? 'Testing...' : 'Test Firestore Base64 Encryption'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _status.startsWith('🎉') 
                    ? Colors.green[100]
                    : _status.startsWith('❌')
                        ? Colors.red[100]
                        : Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _status.startsWith('🎉')
                      ? Colors.green
                      : _status.startsWith('❌')
                          ? Colors.red
                          : Colors.blue,
                ),
              ),
              child: Text(
                _status,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Logs
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
                child: _logs.isEmpty
                    ? const Center(
                        child: Text(
                          'No logs yet. Run a test to see detailed logs.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            child: Text(
                              _logs[index],
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
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
