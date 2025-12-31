import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/mall/store_model.dart';
import 'package:flutter_application_1/mall/mall_model.dart';
import 'package:flutter_application_1/mall/mall_service.dart';

class StoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MallService _mallService = MallService();

  // Get all stores for a mall
  Future<List<Store>> getStoresForMall(String mallId) async {
    try {
      print('Querying Firestore for mallId: $mallId');

      // Query stores where mallId matches
      final querySnapshot =
          await _firestore
              .collection('stores')
              .where('mallId', isEqualTo: mallId)
              .get();

      final results =
          querySnapshot.docs.map((doc) => Store.fromFirestore(doc)).toList();

      print('Found ${results.length} stores for mallId: $mallId');

      return results;
    } catch (e) {
      print('Error fetching stores: $e');
      rethrow; // Allow proper error handling upstream
    }
  }

  // Add a new store
  Future<void> addStore(Store store) async {
    try {
      // Add store to Firestore
      DocumentReference storeRef = await _firestore
          .collection('stores')
          .add(store.toFirestore());

      // Update the mall's stores list
      DocumentReference mallRef = _firestore
          .collection('malls')
          .doc(store.mallId);

      await mallRef.update({
        'stores': FieldValue.arrayUnion([store.name]),
      });

      print('Store added successfully with ID: ${storeRef.id}');
    } catch (e) {
      print('Error adding store: $e');
      throw e;
    }
  }

  // Update store
  Future<void> updateStore(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('stores').doc(id).update(data);
    } catch (e) {
      print('Error updating store: $e');
      throw e;
    }
  }

  // Delete store
  Future<void> deleteStore(Store store) async {
    try {
      // Delete the store
      await _firestore.collection('stores').doc(store.id).delete();

      // Also update the mall to remove this store from its list
      DocumentReference mallRef = _firestore
          .collection('malls')
          .doc(store.mallId);

      await mallRef.update({
        'stores': FieldValue.arrayRemove([store.name]),
      });

      print('Store deleted successfully');
    } catch (e) {
      print('Error deleting store: $e');
      throw e;
    }
  }

  // Get featured stores
  Future<List<Store>> getFeaturedStores() async {
    try {
      final querySnapshot =
          await _firestore
              .collection('stores')
              .where('isFeatured', isEqualTo: true)
              .limit(10)
              .get();

      return querySnapshot.docs.map((doc) => Store.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching featured stores: $e');
      return [];
    }
  }
}
