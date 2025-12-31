import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/city/city_model.dart';
import 'package:flutter_application_1/location/location_model.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all locations for a city
  Future<List<Location>> getLocationsForCity(City city, {String? type}) async {
    try {
      Query query = _firestore
          .collection('locations')
          .where('cityId', isEqualTo: city.id);
        
      // Only apply type filter if a specific type is selected
      if (type != null && type.isNotEmpty) {
        query = query.where('type', isEqualTo: type);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) => Location.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching locations: $e');
      throw Exception('Failed to load locations: $e');
    }
  }

  // Add a new location
  Future<void> addLocation(Location location) async {
    try {
      await _firestore.collection('locations').add(location.toFirestore());
    } catch (e) {
      print('Error adding location: $e');
      throw e;
    }
  }

  // Update a location
  Future<void> updateLocation(String locationId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('locations').doc(locationId).update(data);
    } catch (e) {
      print('Error updating location: $e');
      throw e;
    }
  }

  // Update location images
  Future<void> updateLocationImages(String locationId, List<String> imageUrls) async {
    try {
      await FirebaseFirestore.instance
          .collection('locations')
          .doc(locationId)
          .update({'imageUrls': imageUrls});
      return;
    } catch (e) {
      print('Error updating location images: $e');
      throw Exception('Failed to update location images');
    }
  }

  // Delete a location
  Future<void> deleteLocation(String locationId) async {
    try {
      await _firestore.collection('locations').doc(locationId).delete();
    } catch (e) {
      print('Error deleting location: $e');
      throw e;
    }
  }

  // ADDED: Toggle favorite status for a location
  Future<void> toggleFavorite(
    String locationId,
    String userId,
    bool isFavorited,
  ) async {
    try {
      final locationRef = _firestore.collection('locations').doc(locationId);

      if (isFavorited) {
        await locationRef.update({
          'favoritedBy': FieldValue.arrayRemove([userId]),
        });
      } else {
        await locationRef.update({
          'favoritedBy': FieldValue.arrayUnion([userId]),
        });
      }
    } catch (e) {
      print('Error toggling location favorite status: $e');
      throw e;
    }
  }

  // ADDED: Get locations by their IDs
  Future<List<Location>> getLocationsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('locations')
              .where(FieldPath.documentId, whereIn: ids)
              .get();

      return querySnapshot.docs.map((doc) => Location.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching locations by ids: $e');
      return [];
    }
  }

  // ADDED: Get locations favorited by a user
  Future<List<Location>> getFavoritedLocations(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('locations')
          .where('favoritedBy', arrayContains: userId)
          .get();

      return querySnapshot.docs.map((doc) => Location.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching favorited locations: $e');
      return [];
    }
  }

  // ADDED: Get featured locations
  Future<List<Location>> getFeaturedLocations({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('locations')
          .where('isFeatured', isEqualTo: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) => Location.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching featured locations: $e');
      return [];
    }
  }

  // ADDED: Get top-rated locations
  Future<List<Location>> getTopRatedLocations({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('locations')
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) => Location.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching top-rated locations: $e');
      return [];
    }
  }

  // ADDED: Search locations by name
  Future<List<Location>> searchLocations(String searchTerm) async {
    try {
      // Firestore doesn't support direct text search, so we use a startAt/endAt range
      // This creates a range query that matches documents where the name field starts with the searchTerm
      final querySnapshot = await _firestore
          .collection('locations')
          .orderBy('name')
          .startAt([searchTerm])
          .endAt([searchTerm + '\uf8ff'])
          .get();

      return querySnapshot.docs.map((doc) => Location.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error searching locations: $e');
      return [];
    }
  }
}