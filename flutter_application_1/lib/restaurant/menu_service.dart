import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/restaurant/menu_item_model.dart';

class MenuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all menu items for a restaurant
  Future<List<MenuItem>> getMenuForRestaurant(String restaurantId) async {
    try {
      print('Querying Firestore for restaurantId: $restaurantId');

      // Use a simple query without ordering to avoid index requirements
      final querySnapshot =
          await _firestore
              .collection('menuItems')
              .where('restaurantId', isEqualTo: restaurantId)
              .get();

      final results =
          querySnapshot.docs.map((doc) => MenuItem.fromFirestore(doc)).toList();

      print(
        'Found ${results.length} menu items for restaurantId: $restaurantId',
      );

      // Sort the results in memory instead of in the query
      results.sort((a, b) => a.category.compareTo(b.category));

      return results;
    } catch (e) {
      print('Error fetching menu items: $e');
      rethrow; // Allow proper error handling upstream
    }
  }

  // Add a new menu item
  Future<void> addMenuItem(MenuItem menuItem) async {
    try {
      await _firestore.collection('menuItems').add(menuItem.toFirestore());
    } catch (e) {
      print('Error adding menu item: $e');
      throw e;
    }
  }

  // Update menu item
  Future<void> updateMenuItem(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('menuItems').doc(id).update(data);
    } catch (e) {
      print('Error updating menu item: $e');
      throw e;
    }
  }

  // Delete menu item
  Future<void> deleteMenuItem(String id) async {
    try {
      await _firestore.collection('menuItems').doc(id).delete();
    } catch (e) {
      print('Error deleting menu item: $e');
      throw e;
    }
  }

  // Get menu items for a city (for browsing)
  Future<List<MenuItem>> getMenuItemsForCity(String cityId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('menuItems')
              .where('cityId', isEqualTo: cityId)
              .get();

      return querySnapshot.docs
          .map((doc) => MenuItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching city menu items: $e');
      return [];
    }
  }
}
