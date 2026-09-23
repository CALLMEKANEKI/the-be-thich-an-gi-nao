class NearbyPlace {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distance;
  final double rating;
  final String map_url;

  NearbyPlace({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.rating,
    required this.map_url,
  });

  factory NearbyPlace.fromJson (Map<String, dynamic> json){
    return NearbyPlace (
      name: json['name'],
      address: json['address'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distance: (json['distance_m'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      map_url: json['map_url']
    );
  }
}