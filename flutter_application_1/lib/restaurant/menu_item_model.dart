import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItem {
  final String id;
  final String name;
  final double price;
  final String description;
  final String imageUrl; // Can be base64 or URL
  final String category; // For grouping menu items
  final bool isAvailable;
  final bool isBestseller; // New field
  final String restaurantId; // Reference to restaurant
  final String restaurantName; // Store restaurant name for convenience
  final String cityId; // Reference to city

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    this.description = '',
    this.imageUrl = '',
    this.category = '',
    this.isAvailable = true,
    this.isBestseller = false, // Default to false
    required this.restaurantId,
    required this.restaurantName,
    required this.cityId,
  });

  factory MenuItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MenuItem(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      isBestseller: data['isBestseller'] ?? false, // Add bestseller field
      restaurantId: data['restaurantId'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      cityId: data['cityId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'isAvailable': isAvailable,
      'isBestseller': isBestseller, // Add bestseller field
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'cityId': cityId,
    };
  }
}
