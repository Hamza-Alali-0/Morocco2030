import 'package:cloud_firestore/cloud_firestore.dart';

class Monument {
  String id;
  String cityId;
  String name;
  String description;
  String address;
  List<String> imageUrls;
  GeoPoint location;
  double rating;
  List<String> favoritedBy;
  String type;
  int yearBuilt;
  double entranceFee;
  bool isOpen;
  String openingHours;
  bool hasVirtualTour;
  bool isAccessible;
  bool hasGuidedTours;

  Monument({
    required this.id,
    required this.cityId,
    required this.name,
    required this.description,
    required this.address,
    required this.imageUrls,
    required this.location,
    this.rating = 0.0,
    this.favoritedBy = const [],
    required this.type,
    this.yearBuilt = 0,
    this.entranceFee = 0.0,
    this.isOpen = true,
    this.openingHours = '9:00 AM - 5:00 PM',
    this.hasVirtualTour = false,
    this.isAccessible = false,
    this.hasGuidedTours = false,
  });

  factory Monument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Handle location that might be either a GeoPoint or a Map
    GeoPoint locationGeoPoint;
    if (data['location'] is GeoPoint) {
      locationGeoPoint = data['location'] as GeoPoint;
    } else if (data['location'] is Map) {
      final locationMap = data['location'] as Map<String, dynamic>;
      double lat = (locationMap['latitude'] ?? 0).toDouble();
      double lng = (locationMap['longitude'] ?? 0).toDouble();
      locationGeoPoint = GeoPoint(lat, lng);
    } else {
      locationGeoPoint = const GeoPoint(0, 0);
    }

    return Monument(
      id: doc.id,
      cityId: data['cityId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      location: locationGeoPoint,
      rating: (data['rating'] ?? 0.0).toDouble(),
      favoritedBy: List<String>.from(data['favoritedBy'] ?? []),
      type: data['type'] ?? 'Historical',
      yearBuilt: data['yearBuilt'] ?? 0,
      entranceFee: (data['entranceFee'] ?? 0.0).toDouble(),
      isOpen: data['isOpen'] ?? true,
      openingHours: data['openingHours'] ?? '9:00 AM - 5:00 PM',
      hasVirtualTour: data['hasVirtualTour'] ?? false,
      isAccessible: data['isAccessible'] ?? false,
      hasGuidedTours: data['hasGuidedTours'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'cityId': cityId,
      'name': name,
      'description': description,
      'address': address,
      'imageUrls': imageUrls,
      'location': location,
      'rating': rating,
      'favoritedBy': favoritedBy,
      'type': type,
      'yearBuilt': yearBuilt,
      'entranceFee': entranceFee,
      'isOpen': isOpen,
      'openingHours': openingHours,
      'hasVirtualTour': hasVirtualTour,
      'isAccessible': isAccessible,
      'hasGuidedTours': hasGuidedTours,
    };
  }
}
