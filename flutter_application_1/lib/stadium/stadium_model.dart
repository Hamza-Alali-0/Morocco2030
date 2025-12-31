import 'package:cloud_firestore/cloud_firestore.dart';

class Stadium {
  String id;
  final String cityId;
  final String name;
  final String address;
  final int capacity;
  final String description;
  final List<String> imageUrls;
  final GeoPoint location;
  final double rating;
  final List<String> amenities;
  final String type;
  final DateTime lastUpdated;
  final List<String> favoritedBy; // Added favoritedBy field

  Stadium({
    required this.id,
    required this.cityId,
    required this.name,
    required this.address,
    required this.capacity,
    required this.description,
    required this.imageUrls,
    required this.location,
    this.rating = 0.0,
    this.amenities = const [],
    this.type = 'Stadium',
    DateTime? lastUpdated,
    this.favoritedBy = const [], // Initialize as empty list by default
  }) : this.lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'cityId': cityId,
      'name': name,
      'address': address,
      'capacity': capacity,
      'description': description,
      'imageUrls': imageUrls,
      'location': location,
      'rating': rating,
      'amenities': amenities,
      'type': type,
      'lastUpdated': lastUpdated,
      'createdAt': FieldValue.serverTimestamp(),
      'favoritedBy': favoritedBy, // Include in map for Firestore
    };
  }

  factory Stadium.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Stadium(
      id: doc.id,
      cityId: data['cityId'] ?? '',
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      capacity: data['capacity'] ?? 0,
      description: data['description'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      location: data['location'] ?? const GeoPoint(0, 0),
      rating: (data['rating'] ?? 0.0).toDouble(),
      amenities: List<String>.from(data['amenities'] ?? []),
      type: data['type'] ?? 'Stadium',
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      favoritedBy: List<String>.from(
        data['favoritedBy'] ?? [],
      ), // Read from Firestore
    );
  }
}
