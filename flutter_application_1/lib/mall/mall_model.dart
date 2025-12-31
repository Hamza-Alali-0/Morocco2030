import 'package:cloud_firestore/cloud_firestore.dart';

class Mall {
  final String id;
  final String name;
  final String cityId;
  final String address;
  final double rating;
  final GeoPoint location;
  final List<String> imageUrls;
  final String description;
  final String type;
  final String openingHours;
  final int storeCount;
  final bool hasParking;
  final bool hasWifi;
  final bool hasFoodCourt;
  final bool hasChildrenArea;
  final bool isOpen;
  final List<String> favoritedBy;
  final List<dynamic> stores; // For store references or store data

  Mall({
    required this.id,
    required this.name,
    required this.cityId,
    required this.address,
    required this.rating,
    required this.location,
    required this.imageUrls,
    required this.description,
    this.type = 'Shopping Mall',
    this.openingHours = '10:00 AM - 10:00 PM',
    this.storeCount = 0,
    this.hasParking = false,
    this.hasWifi = false,
    this.hasFoodCourt = false,
    this.hasChildrenArea = false,
    this.isOpen = true,
    this.favoritedBy = const [],
    this.stores = const [],
  });

  factory Mall.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Mall(
      id: doc.id,
      name: data['name'] ?? '',
      cityId: data['cityId'] ?? '',
      address: data['address'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      location: data['location'] ?? const GeoPoint(0, 0),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      description: data['description'] ?? '',
      type: data['type'] ?? 'Shopping Mall',
      openingHours: data['openingHours'] ?? '10:00 AM - 10:00 PM',
      storeCount: data['storeCount'] ?? 0,
      hasParking: data['hasParking'] ?? false,
      hasWifi: data['hasWifi'] ?? false,
      hasFoodCourt: data['hasFoodCourt'] ?? false,
      hasChildrenArea: data['hasChildrenArea'] ?? false,
      isOpen: data['isOpen'] ?? true,
      favoritedBy: List<String>.from(data['favoritedBy'] ?? []),
      stores: List<dynamic>.from(data['stores'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'cityId': cityId,
      'address': address,
      'rating': rating,
      'location': location,
      'imageUrls': imageUrls,
      'description': description,
      'type': type,
      'openingHours': openingHours,
      'storeCount': storeCount,
      'hasParking': hasParking,
      'hasWifi': hasWifi,
      'hasFoodCourt': hasFoodCourt,
      'hasChildrenArea': hasChildrenArea,
      'isOpen': isOpen,
      'favoritedBy': favoritedBy,
      'stores': stores,
    };
  }

  // Convenience method to create a copy of the mall with some attributes changed
  Mall copyWith({
    String? id,
    String? name,
    String? cityId,
    String? address,
    double? rating,
    GeoPoint? location,
    List<String>? imageUrls,
    String? description,
    String? type,
    String? openingHours,
    int? storeCount,
    bool? hasParking,
    bool? hasWifi,
    bool? hasFoodCourt,
    bool? hasChildrenArea,
    bool? isOpen,
    List<String>? favoritedBy,
    List<dynamic>? stores,
  }) {
    return Mall(
      id: id ?? this.id,
      name: name ?? this.name,
      cityId: cityId ?? this.cityId,
      address: address ?? this.address,
      rating: rating ?? this.rating,
      location: location ?? this.location,
      imageUrls: imageUrls ?? this.imageUrls,
      description: description ?? this.description,
      type: type ?? this.type,
      openingHours: openingHours ?? this.openingHours,
      storeCount: storeCount ?? this.storeCount,
      hasParking: hasParking ?? this.hasParking,
      hasWifi: hasWifi ?? this.hasWifi,
      hasFoodCourt: hasFoodCourt ?? this.hasFoodCourt,
      hasChildrenArea: hasChildrenArea ?? this.hasChildrenArea,
      isOpen: isOpen ?? this.isOpen,
      favoritedBy: favoritedBy ?? this.favoritedBy,
      stores: stores ?? this.stores,
    );
  }

  // Helper method to check if a user has favorited this mall
  bool isFavoritedBy(String userId) {
    return favoritedBy.contains(userId);
  }

  // Helper method to get a formatted display of opening hours
  String get formattedOpeningHours {
    return openingHours.isEmpty ? 'Hours not available' : openingHours;
  }

  // Helper method to get a short description for cards
  String get shortDescription {
    if (description.length <= 100) return description;
    return '${description.substring(0, 97)}...';
  }

  // Helper to get category display name
  String get categoryDisplayName {
    switch (type.toLowerCase()) {
      case 'shopping mall':
        return 'Shopping Mall';
      case 'outlet mall':
        return 'Outlet Mall';
      case 'open-air mall':
        return 'Open-Air Mall';
      case 'strip mall':
        return 'Strip Mall';
      default:
        return type;
    }
  }

  // Helper to get a suitable icon name for the mall type
  String get typeIconName {
    switch (type.toLowerCase()) {
      case 'outlet mall':
        return 'local_mall';
      case 'open-air mall':
        return 'park';
      case 'strip mall':
        return 'storefront';
      default:
        return 'shopping_bag';
    }
  }

  // Helper to get store count
  int get storecount {
    if (stores != null && stores.isNotEmpty) {
      return stores.length;
    }
    return 0;
  }

  // Helper to check if mall has stores
  bool get hasStores {
    return stores != null && stores.isNotEmpty;
  }
}
