import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BackendService {
  static final BackendService _instance = BackendService._internal();
  factory BackendService() => _instance;
  BackendService._internal();

  // Base URL for your API (replace with your actual backend URL)
  static const String baseUrl = 'https://your-api-url.com/api';
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Check if Firebase is connected
  bool get isFirebaseConnected {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  // Check if user is authenticated
  bool get isUserAuthenticated {
    return _auth.currentUser != null;
  }
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Test backend connection
  Future<bool> testConnection() async {
    try {
      // Test Firebase connection
      if (!isFirebaseConnected) {
        print('Firebase is not connected');
        return false;
      }
      
      // Test HTTP connection (replace with your actual health check endpoint)
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        print('Backend connection successful');
        return true;
      } else {
        print('Backend connection failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Backend connection error: $e');
      return false;
    }
  }
  
  // Generic GET request
  Future<Map<String, dynamic>?> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('GET request failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('GET request error: $e');
      return null;
    }
  }
  
  // Generic POST request
  Future<Map<String, dynamic>?> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: json.encode(data),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        print('POST request failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('POST request error: $e');
      return null;
    }
  }
  
  // Get headers with authentication token if available
  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    // Add Firebase auth token if user is authenticated
    if (isUserAuthenticated) {
      try {
        final token = await _auth.currentUser!.getIdToken();
        headers['Authorization'] = 'Bearer $token';
      } catch (e) {
        print('Failed to get auth token: $e');
      }
    }
    
    return headers;
  }
  
  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      print('Sign in failed: $e');
      return null;
    }
  }
  
  // Sign up with email and password
  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      print('Sign up failed: $e');
      return null;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out failed: $e');
    }
  }
  
  // Upload image to backend
  Future<Map<String, dynamic>?> uploadImage(String imageId, {Map<String, dynamic>? metadata}) async {
    try {
      // This would typically use your ImageService to get the image
      // For now, we'll create a placeholder implementation
      
      final data = {
        'image_id': imageId,
        'metadata': metadata ?? {},
        'uploaded_at': DateTime.now().toIso8601String(),
      };
      
      return await post('/images/upload', data);
    } catch (e) {
      print('Image upload error: $e');
      return null;
    }
  }
  
  // Upload multiple images
  Future<List<Map<String, dynamic>>> uploadMultipleImages(List<String> imageIds) async {
    List<Map<String, dynamic>> results = [];
    
    for (String imageId in imageIds) {
      final result = await uploadImage(imageId);
      if (result != null) {
        results.add(result);
      }
    }
    
    return results;
  }
  
  // Get uploaded images from backend
  Future<List<Map<String, dynamic>>> getUploadedImages() async {
    try {
      final response = await get('/images');
      if (response != null && response['images'] is List) {
        return List<Map<String, dynamic>>.from(response['images']);
      }
      return [];
    } catch (e) {
      print('Error getting uploaded images: $e');
      return [];
    }
  }

  // Get connection status
  Future<Map<String, bool>> getConnectionStatus() async {
    return {
      'firebase': isFirebaseConnected,
      'authentication': isUserAuthenticated,
      'backend_api': await testConnection(),
    };
  }
}
