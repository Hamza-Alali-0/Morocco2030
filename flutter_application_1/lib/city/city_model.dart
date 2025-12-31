import 'package:cloud_firestore/cloud_firestore.dart';

class City {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String? imageBase64; // Add this field
  final GeoPoint location;
  final List<String> favoritedBy;
  final String type;

  City({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.imageBase64, // Optional for backward compatibility
    required this.location,
    required this.favoritedBy,
    required this.type,
  });

  factory City.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return City(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      imageBase64: data['imageBase64'], // Get Base64 string if available
      location: data['location'] ?? const GeoPoint(0, 0),
      favoritedBy: List<String>.from(data['favoritedBy'] ?? []),
      type: data['type'] ?? 'Other',
    );
  }
}
