import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String id;
  final String name;
  final String description;
  final double price;
  final int pointsRequired;
  final List<String> imageUrls;
  final GeoPoint location;
  final String address;
  final String type;
  final double rating;
  final String cityId;
  final String cityName;
  final bool isAvailable;
  final String provider;
  final String duration;
  final int capacity;
  final List<String> inclusions;
  final List<String> exclusions;
  final List<String> favoritedBy;
  final String contactPhone;
  final String contactEmail;
  final String website;

  Activity({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.pointsRequired,
    required this.imageUrls,
    required this.location,
    required this.address,
    required this.type,
    required this.rating,
    required this.cityId,
    required this.cityName,
    this.isAvailable = true,
    required this.provider,
    required this.duration,
    this.capacity = 0, // Removed 'required' since it has a default value
    required this.inclusions,
    required this.exclusions,
    required this.favoritedBy,
    this.contactPhone = '',
    this.contactEmail = '',
    this.website = '',
  });

  factory Activity.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Handle location which might be a Map or GeoPoint
    GeoPoint locationPoint;
    if (data['location'] is GeoPoint) {
      locationPoint = data['location'] as GeoPoint;
    } else if (data['location'] is Map) {
      // Convert Map to GeoPoint
      Map<String, dynamic> locationMap =
          data['location'] as Map<String, dynamic>;
      locationPoint = GeoPoint(
        locationMap['latitude'] ?? 0.0,
        locationMap['longitude'] ?? 0.0,
      );
    } else {
      // Default location if missing
      locationPoint = const GeoPoint(0, 0);
    }

    return Activity(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      pointsRequired: data['pointsRequired'] ?? 0,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      location: locationPoint,
      address: data['address'] ?? '',
      type: data['type'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      cityId: data['cityId'] ?? '',
      cityName: data['cityName'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      provider: data['provider'] ?? '',
      duration: data['duration'] ?? '',
      capacity: data['capacity'] ?? 0,
      inclusions: List<String>.from(data['inclusions'] ?? []),
      exclusions: List<String>.from(data['exclusions'] ?? []),
      favoritedBy: List<String>.from(data['favoritedBy'] ?? []),
      contactPhone: data['contactPhone'] ?? '',
      contactEmail: data['contactEmail'] ?? '',
      website: data['website'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'pointsRequired': pointsRequired,
      'imageUrls': imageUrls,
      'location': location,
      'address': address,
      'type': type,
      'rating': rating,
      'cityId': cityId,
      'cityName': cityName,
      'isAvailable': isAvailable,
      'provider': provider,
      'duration': duration,
      'capacity': capacity,
      'inclusions': inclusions,
      'exclusions': exclusions,
      'favoritedBy': favoritedBy,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'website': website,
    };
  }
}
