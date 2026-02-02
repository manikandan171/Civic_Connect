import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();
  Database? _database;

  // Initialize the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = path.join(documentsDirectory.path, 'images.db');
    
    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          '''CREATE TABLE images(
            id TEXT PRIMARY KEY,
            filename TEXT NOT NULL,
            filepath TEXT NOT NULL,
            size INTEGER NOT NULL,
            mime_type TEXT NOT NULL,
            created_at TEXT NOT NULL,
            metadata TEXT
          )''',
        );
      },
    );
  }

  // Pick image from camera
  Future<ImageData?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        return await _processAndStoreImage(image);
      }
      return null;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  // Pick image from gallery
  Future<ImageData?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        return await _processAndStoreImage(image);
      }
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  // Pick multiple images from gallery
  Future<List<ImageData>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      List<ImageData> processedImages = [];
      for (XFile image in images) {
        final imageData = await _processAndStoreImage(image);
        if (imageData != null) {
          processedImages.add(imageData);
        }
      }
      return processedImages;
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }

  // Process and store image as binary file
  Future<ImageData?> _processAndStoreImage(XFile image) async {
    try {
      // Read image bytes
      final Uint8List imageBytes = await image.readAsBytes();
      
      // Generate unique ID and filename
      final String imageId = _uuid.v4();
      final String extension = path.extension(image.path);
      final String filename = '$imageId$extension';
      
      // Get app documents directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final Directory imagesDir = Directory(path.join(appDocDir.path, 'images'));
      
      // Create images directory if it doesn't exist
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      // Create file path
      final String filePath = path.join(imagesDir.path, filename);
      
      // Write binary data to file
      final File file = File(filePath);
      await file.writeAsBytes(imageBytes);
      
      // Create image data object
      final ImageData imageData = ImageData(
        id: imageId,
        filename: filename,
        filepath: filePath,
        size: imageBytes.length,
        mimeType: image.mimeType ?? 'image/jpeg',
        createdAt: DateTime.now(),
        metadata: {
          'original_name': image.name,
          'original_path': image.path,
        },
      );
      
      // Store metadata in database
      await _storeImageMetadata(imageData);
      
      print('Image stored successfully: $filename (${imageBytes.length} bytes)');
      return imageData;
      
    } catch (e) {
      print('Error processing and storing image: $e');
      return null;
    }
  }

  // Store image metadata in database
  Future<void> _storeImageMetadata(ImageData imageData) async {
    final db = await database;
    await db.insert(
      'images',
      {
        'id': imageData.id,
        'filename': imageData.filename,
        'filepath': imageData.filepath,
        'size': imageData.size,
        'mime_type': imageData.mimeType,
        'created_at': imageData.createdAt.toIso8601String(),
        'metadata': jsonEncode(imageData.metadata),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all stored images
  Future<List<ImageData>> getAllImages() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'images',
        orderBy: 'created_at DESC',
      );
      
      return List.generate(maps.length, (i) {
        return ImageData(
          id: maps[i]['id'],
          filename: maps[i]['filename'],
          filepath: maps[i]['filepath'],
          size: maps[i]['size'],
          mimeType: maps[i]['mime_type'],
          createdAt: DateTime.parse(maps[i]['created_at']),
          metadata: jsonDecode(maps[i]['metadata']),
        );
      });
    } catch (e) {
      print('Error getting all images: $e');
      return [];
    }
  }

  // Get image by ID
  Future<ImageData?> getImageById(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'images',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isNotEmpty) {
        return ImageData(
          id: maps[0]['id'],
          filename: maps[0]['filename'],
          filepath: maps[0]['filepath'],
          size: maps[0]['size'],
          mimeType: maps[0]['mime_type'],
          createdAt: DateTime.parse(maps[0]['created_at']),
          metadata: jsonDecode(maps[0]['metadata']),
        );
      }
      return null;
    } catch (e) {
      print('Error getting image by ID: $e');
      return null;
    }
  }

  // Get image file
  Future<File?> getImageFile(String id) async {
    final imageData = await getImageById(id);
    if (imageData != null) {
      final file = File(imageData.filepath);
      if (await file.exists()) {
        return file;
      }
    }
    return null;
  }

  // Get image bytes
  Future<Uint8List?> getImageBytes(String id) async {
    final file = await getImageFile(id);
    if (file != null) {
      return await file.readAsBytes();
    }
    return null;
  }

  // Delete image
  Future<bool> deleteImage(String id) async {
    try {
      final imageData = await getImageById(id);
      if (imageData != null) {
        // Delete file
        final file = File(imageData.filepath);
        if (await file.exists()) {
          await file.delete();
        }
        
        // Delete from database
        final db = await database;
        await db.delete(
          'images',
          where: 'id = ?',
          whereArgs: [id],
        );
        
        print('Image deleted successfully: ${imageData.filename}');
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  // Get total storage used
  Future<int> getTotalStorageUsed() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT SUM(size) as total FROM images');
      return result.first['total'] as int? ?? 0;
    } catch (e) {
      print('Error getting total storage: $e');
      return 0;
    }
  }

  // Convert image to base64 for API upload
  Future<String?> imageToBase64(String id) async {
    final bytes = await getImageBytes(id);
    if (bytes != null) {
      return base64Encode(bytes);
    }
    return null;
  }

  // Show image picker dialog
  Future<ImageData?> showImagePickerDialog(BuildContext context) async {
    return showDialog<ImageData>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final image = await pickImageFromCamera();
                  if (context.mounted) {
                    Navigator.of(context).pop(image);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final image = await pickImageFromGallery();
                  if (context.mounted) {
                    Navigator.of(context).pop(image);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

// Image data model
class ImageData {
  final String id;
  final String filename;
  final String filepath;
  final int size;
  final String mimeType;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  ImageData({
    required this.id,
    required this.filename,
    required this.filepath,
    required this.size,
    required this.mimeType,
    required this.createdAt,
    required this.metadata,
  });

  // Convert to JSON for API upload
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'size': size,
      'mime_type': mimeType,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  // Get formatted file size
  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
