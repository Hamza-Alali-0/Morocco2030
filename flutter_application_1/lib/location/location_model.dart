import 'package:cloud_firestore/cloud_firestore.dart';

class Location {
  final String id;
  final String name;
  final String cityId;
  final String cityName; // Added to match Guide model
  final String address;
  final double rating;
  final int reviewCount; // Added to match other models
  final GeoPoint location;
  final String profileImageUrl; // Added main image like Guide model
  final List<String> imageUrls;
  final String description;
  final String type; // hotel, apartment, hostel
  final String phoneNumber;
  final String website;
  final double pricePerNight;
  final List<String> amenities;
  final int numberOfRooms;
  final bool isAvailable;
  final List<String> favoritedBy; // Added to match Guide model
  final List<String> features; // Added like Guide's activities

  Location({
    required this.id,
    required this.name,
    required this.cityId,
    this.cityName = '', // New field
    required this.address,
    required this.rating,
    this.reviewCount = 0, // New field
    required this.location,
    this.profileImageUrl = '', // New field
    required this.imageUrls,
    required this.description,
    required this.type,
    required this.phoneNumber,
    required this.website,
    required this.pricePerNight,
    required this.amenities,
    required this.numberOfRooms,
    this.isAvailable = true,
    this.favoritedBy = const [], // New field
    this.features = const [], // New field
  });

  factory Location.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Location(
      id: doc.id,
      name: data['name'] ?? '',
      cityId: data['cityId'] ?? '',
      cityName: data['cityName'] ?? '', // New field
      address: data['address'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0, // New field
      location: data['location'] ?? const GeoPoint(0, 0),
      profileImageUrl: data['profileImageUrl'] ?? '', // New field
      imageUrls:
          (data['imageUrls'] as List<dynamic>?)
              ?.map((dynamic item) => item.toString())
              .toList() ??
          [],
      description: data['description'] ?? '',
      type: data['type'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      website: data['website'] ?? '',
      pricePerNight: (data['pricePerNight'] ?? 0.0).toDouble(),
      amenities: List<String>.from(data['amenities'] ?? []),
      numberOfRooms: data['numberOfRooms'] ?? 0,
      isAvailable: data['isAvailable'] ?? true,
      favoritedBy: List<String>.from(data['favoritedBy'] ?? []), // New field
      features: List<String>.from(data['features'] ?? []), // New field
    );
  }

  static Location fromMap(Map<String, dynamic> data, String id) {
    return Location(
      id: id,
      name: data['name'] ?? '',
      cityId: data['cityId'] ?? '',
      cityName: data['cityName'] ?? '', // New field
      address: data['address'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0, // New field
      location: data['location'] as GeoPoint? ?? const GeoPoint(0, 0),
      profileImageUrl: data['profileImageUrl'] ?? '', // New field
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      description: data['description'] ?? '',
      type: data['type'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      website: data['website'] ?? '',
      pricePerNight: (data['pricePerNight'] ?? 0.0).toDouble(),
      amenities: List<String>.from(data['amenities'] ?? []),
      numberOfRooms: data['numberOfRooms'] ?? 0,
      isAvailable: data['isAvailable'] ?? true,
      favoritedBy: List<String>.from(data['favoritedBy'] ?? []), // New field
      features: List<String>.from(data['features'] ?? []), // New field
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'cityId': cityId,
      'cityName': cityName, // New field
      'address': address,
      'rating': rating,
      'reviewCount': reviewCount, // New field
      'location': location,
      'profileImageUrl': profileImageUrl, // New field
      'imageUrls': imageUrls,
      'description': description,
      'type': type,
      'phoneNumber': phoneNumber,
      'website': website,
      'pricePerNight': pricePerNight,
      'amenities': amenities,
      'numberOfRooms': numberOfRooms,
      'isAvailable': isAvailable,
      'favoritedBy': favoritedBy, // New field
      'features': features, // New field
    };
  }

  Map<String, dynamic> toMap() {
    return toFirestore();
  }

  Location copyWith({
    String? id,
    String? name,
    String? cityId,
    String? cityName, // New field
    String? address,
    double? rating,
    int? reviewCount, // New field
    GeoPoint? location,
    String? profileImageUrl, // New field
    List<String>? imageUrls,
    String? description,
    String? type,
    String? phoneNumber,
    String? website,
    double? pricePerNight,
    List<String>? amenities,
    int? numberOfRooms,
    bool? isAvailable,
    List<String>? favoritedBy, // New field
    List<String>? features, // New field
  }) {
    return Location(
      id: id ?? this.id,
      name: name ?? this.name,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName, // New field
      address: address ?? this.address,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount, // New field
      location: location ?? this.location,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl, // New field
      imageUrls: imageUrls ?? this.imageUrls,
      description: description ?? this.description,
      type: type ?? this.type,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      amenities: amenities ?? this.amenities,
      numberOfRooms: numberOfRooms ?? this.numberOfRooms,
      isAvailable: isAvailable ?? this.isAvailable,
      favoritedBy: favoritedBy ?? this.favoritedBy, // New field
      features: features ?? this.features, // New field
    );
  }
  
  // Add helper method to check if location is favorited by user
  bool isFavoritedBy(String userId) {
    return favoritedBy.contains(userId);
  }
}
