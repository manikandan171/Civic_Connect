import 'dart:convert';
import 'package:http/http.dart' as http;

class GeoapifyService {
  static const String _apiKey = '0b547b82c3e94cda8d55b2db2256d3d';
  static const String _baseUrl = 'https://api.geoapify.com/v1';

  /// Get geocoding (address to coordinates)
  static Future<GeoapifyLocation?> geocodeAddress(String address) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/geocode/search?text=${Uri.encodeComponent(address)}&apiKey=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List<dynamic>?;
        
        if (features != null && features.isNotEmpty) {
          final feature = features.first;
          final geometry = feature['geometry'];
          final coordinates = geometry['coordinates'] as List<dynamic>;
          final properties = feature['properties'];
          
          return GeoapifyLocation(
            latitude: coordinates[1].toDouble(),
            longitude: coordinates[0].toDouble(),
            address: properties['formatted'] ?? address,
            city: properties['city'],
            country: properties['country'],
            state: properties['state'],
          );
        }
      }
      return null;
    } catch (e) {
      print('Error in geocoding: $e');
      return null;
    }
  }

  /// Get reverse geocoding (coordinates to address)
  static Future<String?> reverseGeocode(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/geocode/reverse?lat=$latitude&lon=$longitude&apiKey=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List<dynamic>?;
        
        if (features != null && features.isNotEmpty) {
          final feature = features.first;
          final properties = feature['properties'];
          return properties['formatted'] as String?;
        }
      }
      return null;
    } catch (e) {
      print('Error in reverse geocoding: $e');
      return null;
    }
  }

  /// Get map tile URL for a specific zoom level and coordinates
  static String getMapTileUrl({
    required double latitude,
    required double longitude,
    int zoom = 15,
    String style = 'osm-bright',
    int width = 800,
    int height = 600,
  }) {
    return 'https://maps.geoapify.com/v1/staticmap?style=$style&width=$width&height=$height&center=lonlat:$longitude,$latitude&zoom=$zoom&apiKey=$_apiKey';
  }

  /// Get interactive map URL
  static String getInteractiveMapUrl({
    required double latitude,
    required double longitude,
    int zoom = 15,
    String style = 'osm-bright',
  }) {
    return 'https://apidocs.geoapify.com/playground/map-tiles/?lat=$latitude&lon=$longitude&z=$zoom&style=$style&apiKey=$_apiKey';
  }

  /// Search for places near a location
  static Future<List<GeoapifyPlace>> searchNearby({
    required double latitude,
    required double longitude,
    String? category,
    int radius = 1000,
    int limit = 20,
  }) async {
    try {
      String url = '$_baseUrl/places/nearby?lat=$latitude&lon=$longitude&radius=$radius&limit=$limit&apiKey=$_apiKey';
      
      if (category != null) {
        url += '&categories=$category';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List<dynamic>? ?? [];
        
        return features.map((feature) => GeoapifyPlace.fromJson(feature)).toList();
      }
      return [];
    } catch (e) {
      print('Error searching nearby places: $e');
      return [];
    }
  }

  /// Get routing between two points
  static Future<GeoapifyRoute?> getRoute({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    String mode = 'drive', // drive, walk, bicycle
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/routing?waypoints=$startLat,$startLon|$endLat,$endLon&mode=$mode&apiKey=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List<dynamic>?;
        
        if (features != null && features.isNotEmpty) {
          return GeoapifyRoute.fromJson(features.first);
        }
      }
      return null;
    } catch (e) {
      print('Error getting route: $e');
      return null;
    }
  }
}

class GeoapifyLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String? city;
  final String? country;
  final String? state;

  GeoapifyLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.city,
    this.country,
    this.state,
  });
}

class GeoapifyPlace {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? category;
  final String? address;
  final Map<String, dynamic>? properties;

  GeoapifyPlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.category,
    this.address,
    this.properties,
  });

  factory GeoapifyPlace.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'];
    final coordinates = geometry['coordinates'] as List<dynamic>;
    final properties = json['properties'] as Map<String, dynamic>;
    
    return GeoapifyPlace(
      id: json['id'] ?? '',
      name: properties['name'] ?? 'Unknown',
      latitude: coordinates[1].toDouble(),
      longitude: coordinates[0].toDouble(),
      category: properties['categories']?.first,
      address: properties['formatted'],
      properties: properties,
    );
  }
}

class GeoapifyRoute {
  final List<List<double>> coordinates;
  final double distance; // in meters
  final double duration; // in seconds
  final String? instructions;

  GeoapifyRoute({
    required this.coordinates,
    required this.distance,
    required this.duration,
    this.instructions,
  });

  factory GeoapifyRoute.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'];
    final coordinates = (geometry['coordinates'] as List<dynamic>)
        .map<List<double>>((coord) => [coord[0].toDouble(), coord[1].toDouble()])
        .toList();
    
    final properties = json['properties'] as Map<String, dynamic>;
    
    return GeoapifyRoute(
      coordinates: coordinates,
      distance: (properties['distance'] ?? 0).toDouble(),
      duration: (properties['time'] ?? 0).toDouble(),
      instructions: properties['instructions']?.toString(),
    );
  }
}
