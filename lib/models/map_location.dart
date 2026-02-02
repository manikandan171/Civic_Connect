class MapLocation {
  final double latitude;
  final double longitude;

  const MapLocation(this.latitude, this.longitude);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapLocation &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  @override
  String toString() => 'MapLocation(lat: $latitude, lng: $longitude)';
}

class MapBounds {
  final MapLocation southwest;
  final MapLocation northeast;

  const MapBounds({required this.southwest, required this.northeast});

  @override
  String toString() =>
      'MapBounds(southwest: $southwest, northeast: $northeast)';
}
