import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Restaurant {
  final String id;
  final String name;
  final String cityId;
  final String address;
  final double rating;
  final GeoPoint location;
  final List<String> imageUrls;
  final String description;
  final String cuisine;
  final String phoneNumber;
  final String website;
  final List<String> menuItems;
  final String type;
  final List<String> favoritedBy; // Added this field

  Restaurant({
    required this.id,
    required this.name,
    required this.cityId,
    required this.address,
    required this.rating,
    required this.location,
    required this.imageUrls,
    required this.description,
    required this.cuisine,
    this.phoneNumber = '',
    this.website = '',
    this.menuItems = const [],
    this.type = 'Restaurant',
    this.favoritedBy = const [], // Initialize with empty list
  });

  factory Restaurant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Restaurant(
      id: doc.id,
      name: data['name'] ?? '',
      cityId: data['cityId'] ?? '',
      address: data['address'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      location: data['location'] ?? const GeoPoint(0, 0),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      description: data['description'] ?? '',
      cuisine: data['cuisine'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      website: data['website'] ?? '',
      menuItems: List<String>.from(data['menuItems'] ?? []),
      type: data['type'] ?? 'Restaurant',
      favoritedBy: List<String>.from(
        data['favoritedBy'] ?? [],
      ), // Parse favoritedBy
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
      'cuisine': cuisine,
      'phoneNumber': phoneNumber,
      'website': website,
      'menuItems': menuItems,
      'type': type,
      'favoritedBy': favoritedBy, // Include favoritedBy in Firestore data
    };
  }

  LatLng get latLng => LatLng(location.latitude, location.longitude);

  // Helper method to check if an image is base64 encoded
  static bool isBase64Image(String source) {
    return source.startsWith('data:image') ||
        RegExp(
          r'^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)?$',
        ).hasMatch(source);
  }
}
