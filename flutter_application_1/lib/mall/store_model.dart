import 'package:cloud_firestore/cloud_firestore.dart';

class Store {
  final String id;
  final String name;
  final String description;
  final String category;
  final String imageUrl; // Can be base64 or URL
  final bool isFeatured;
  final int floorNumber;
  final String contactInfo;
  final String openingHours;
  final String mallId; // Reference to mall
  final String mallName; // Store mall name for convenience

  Store({
    required this.id,
    required this.name,
    this.description = '',
    this.category = '',
    this.imageUrl = '',
    this.isFeatured = false,
    this.floorNumber = 1,
    this.contactInfo = '',
    this.openingHours = '',
    required this.mallId,
    required this.mallName,
  });

  factory Store.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Store(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      isFeatured: data['isFeatured'] ?? false,
      floorNumber: data['floorNumber'] ?? 1,
      contactInfo: data['contactInfo'] ?? '',
      openingHours: data['openingHours'] ?? '',
      mallId: data['mallId'] ?? '',
      mallName: data['mallName'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'isFeatured': isFeatured,
      'floorNumber': floorNumber,
      'contactInfo': contactInfo,
      'openingHours': openingHours,
      'mallId': mallId,
      'mallName': mallName,
    };
  }
}
