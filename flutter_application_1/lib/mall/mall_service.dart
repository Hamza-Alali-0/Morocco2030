import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/city/city_model.dart';
import 'package:flutter_application_1/mall/mall_model.dart';

class MallService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all malls
  Stream<List<Mall>> getMalls() {
    return _firestore.collection('malls').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Mall.fromFirestore(doc)).toList();
    });
  }

  // Get malls by city
  Stream<List<Mall>> getMallsByCity(String cityId) {
    return _firestore
        .collection('malls')
        .where('cityId', isEqualTo: cityId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Mall.fromFirestore(doc)).toList();
        });
  }

  /// Returns all malls in the given city.
  Future<List<Mall>> getMallsForCity(City city) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('malls')
              .where('cityId', isEqualTo: city.id)
              .get();

      return querySnapshot.docs.map((doc) => Mall.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching malls: $e');
      return [];
    }
  }

  // Get a single mall
  Future<Mall?> getMall(String id) async {
    DocumentSnapshot doc = await _firestore.collection('malls').doc(id).get();
    if (doc.exists) {
      return Mall.fromFirestore(doc);
    }
    return null;
  }

  // Add a new mall
  Future<void> addMall(Mall mall) async {
    try {
      await _firestore.collection('malls').add(mall.toFirestore());
    } catch (e) {
      print('Error adding mall: $e');
      throw e;
    }
  }

  // Update a mall
  Future<void> updateMall(String mallId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('malls').doc(mallId).update(data);
    } catch (e) {
      print('Error updating mall: $e');
      throw e;
    }
  }

  // Delete a mall
  Future<void> deleteMall(String mallId) async {
    try {
      await _firestore.collection('malls').doc(mallId).delete();
    } catch (e) {
      print('Error deleting mall: $e');
      throw e;
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite(
    String mallId,
    String userId,
    bool isFavorited,
  ) async {
    try {
      final mallRef = _firestore.collection('malls').doc(mallId);

      if (isFavorited) {
        await mallRef.update({
          'favoritedBy': FieldValue.arrayRemove([userId]),
        });
      } else {
        await mallRef.update({
          'favoritedBy': FieldValue.arrayUnion([userId]),
        });
      }
    } catch (e) {
      print('Error toggling mall favorite status: $e');
      throw e;
    }
  }

  // Get malls by their IDs
  Future<List<Mall>> getMallsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    try {
      // For large lists, you might need to batch the queries
      if (ids.length > 10) {
        List<Mall> allResults = [];

        // Process in batches of 10 (Firestore limit for whereIn)
        for (int i = 0; i < ids.length; i += 10) {
          final endIdx = (i + 10 < ids.length) ? i + 10 : ids.length;
          final batchIds = ids.sublist(i, endIdx);

          final batch =
              await _firestore
                  .collection('malls')
                  .where(FieldPath.documentId, whereIn: batchIds)
                  .get();

          allResults.addAll(
            batch.docs.map((doc) => Mall.fromFirestore(doc)).toList(),
          );
        }

        return allResults;
      } else {
        final querySnapshot =
            await _firestore
                .collection('malls')
                .where(FieldPath.documentId, whereIn: ids)
                .get();

        return querySnapshot.docs
            .map((doc) => Mall.fromFirestore(doc))
            .toList();
      }
    } catch (e) {
      print('Error fetching malls by ids: $e');
      return [];
    }
  }
}
