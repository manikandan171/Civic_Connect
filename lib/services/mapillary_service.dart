import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

class MapillaryService {
  static const String _baseUrl = 'https://graph.mapillary.com';
  static const String _apiKey =
      'MLY|24197444293272639|aa5294f3922fa84e8dd0f0002e59fdea';

  /// Get images near a specific location
  static Future<List<MapillaryImage>> getImagesNearLocation({
    required double latitude,
    required double longitude,
    double radius = 1000, // meters
    int limit = 50,
  }) async {
    try {
      // Calculate bounding box
      double latDelta =
          radius / 111000; // Rough conversion from meters to degrees
      double lngDelta = radius / (111000 * math.cos(latitude * math.pi / 180));

      double minLat = latitude - latDelta;
      double maxLat = latitude + latDelta;
      double minLng = longitude - lngDelta;
      double maxLng = longitude + lngDelta;

      final url = Uri.parse(
        '$_baseUrl/images?fields=id,geometry,thumb_256_url,thumb_1024_url,thumb_2048_url,captured_at,compass_angle&access_token=$_apiKey&bbox=$minLng,$minLat,$maxLng,$maxLat&limit=$limit',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> images = data['data'] ?? [];

        return images.map((image) => MapillaryImage.fromJson(image)).toList();
      } else {
        throw Exception('Failed to load images: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching Mapillary images: $e');
    }
  }

  /// Get images for a specific area (bounding box)
  static Future<List<MapillaryImage>> getImagesInBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    int limit = 100,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/images?fields=id,geometry,thumb_256_url,thumb_1024_url,thumb_2048_url,captured_at,compass_angle&access_token=$_apiKey&bbox=$minLng,$minLat,$maxLng,$maxLat&limit=$limit',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> images = data['data'] ?? [];

        return images.map((image) => MapillaryImage.fromJson(image)).toList();
      } else {
        throw Exception('Failed to load images: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching Mapillary images: $e');
    }
  }

  /// Get street view URL for a specific location
  static String getStreetViewUrl({
    required double latitude,
    required double longitude,
    double heading = 0,
    double pitch = 0,
    int zoom = 1,
  }) {
    return 'https://www.mapillary.com/embed?pKey=$_apiKey&lat=$latitude&lng=$longitude&heading=$heading&pitch=$pitch&zoom=$zoom';
  }

  /// Get Mapillary viewer URL for a specific location
  static String getMapillaryViewerUrl({
    required double latitude,
    required double longitude,
  }) {
    return 'https://www.mapillary.com/app/?lat=$latitude&lng=$longitude&z=17&focus=map&pKey=$_apiKey';
  }
}

class MapillaryImage {
  final String id;
  final double latitude;
  final double longitude;
  final String? thumb256Url;
  final String? thumb1024Url;
  final String? thumb2048Url;
  final DateTime? capturedAt;
  final double? compassAngle;

  MapillaryImage({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.thumb256Url,
    this.thumb1024Url,
    this.thumb2048Url,
    this.capturedAt,
    this.compassAngle,
  });

  factory MapillaryImage.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>?;
    final coordinates = geometry?['coordinates'] as List<dynamic>?;

    return MapillaryImage(
      id: json['id'] as String,
      latitude: coordinates?[1]?.toDouble() ?? 0.0,
      longitude: coordinates?[0]?.toDouble() ?? 0.0,
      thumb256Url: json['thumb_256_url'] as String?,
      thumb1024Url: json['thumb_1024_url'] as String?,
      thumb2048Url: json['thumb_2048_url'] as String?,
      capturedAt: json['captured_at'] != null
          ? DateTime.tryParse(json['captured_at'] as String)
          : null,
      compassAngle: (json['compass_angle'] as num?)?.toDouble(),
    );
  }
}
