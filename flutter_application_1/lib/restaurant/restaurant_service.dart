import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/restaurant/restaurant_model.dart';
import 'package:flutter_application_1/city/city_model.dart';

class RestaurantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Restaurant>> getRestaurantsForCity(City city) async {
    try {
      // Query restaurants where cityId matches the current city's id
      final querySnapshot =
          await _firestore
              .collection('restaurants')
              .where('cityId', isEqualTo: city.id)
              .get();

      return querySnapshot.docs
          .map((doc) => Restaurant.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching restaurants: $e');
      return [];
    }
  }

  // Method to add a new restaurant
  Future<void> addRestaurant(Restaurant restaurant) async {
    try {
      await _firestore.collection('restaurants').add(restaurant.toFirestore());
    } catch (e) {
      print('Error adding restaurant: $e');
      throw e;
    }
  }

  // Method to delete a restaurant
  Future<void> deleteRestaurant(String restaurantId) async {
    try {
      await _firestore.collection('restaurants').doc(restaurantId).delete();
    } catch (e) {
      print('Error deleting restaurant: $e');
      throw e;
    }
  }

  // Method to update a restaurant
  Future<void> updateRestaurant(
    String restaurantId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('restaurants').doc(restaurantId).update(data);
    } catch (e) {
      print('Error updating restaurant: $e');
      throw e;
    }
  }

  // Method to get restaurants by their IDs
 // Example for RestaurantService
Future<List<Restaurant>> getRestaurantsByIds(List<String> ids) async {
  try {
    if (ids.isEmpty) return [];
    
    print('Restaurant service fetching IDs: $ids');
    
    // For large lists, you might need to batch the queries
    if (ids.length > 10) {
      List<Restaurant> allResults = [];
      
      // Process in batches of 10 (Firestore limit for whereIn)
      for (int i = 0; i < ids.length; i += 10) {
        final endIdx = (i + 10 < ids.length) ? i + 10 : ids.length;
        final batchIds = ids.sublist(i, endIdx);
        
        final batch = await FirebaseFirestore.instance
            .collection('restaurants')
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();
            
        allResults.addAll(batch.docs.map((doc) => Restaurant.fromFirestore(doc)).toList());
      }
      
      return allResults;
    } else {
      final snapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .where(FieldPath.documentId, whereIn: ids)
          .get();
          
      return snapshot.docs.map((doc) => Restaurant.fromFirestore(doc)).toList();
    }
  } catch (e) {
    print('Error in getRestaurantsByIds: $e');
    return [];
  }
}
}
