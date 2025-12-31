import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/city/city_model.dart';
import 'package:flutter_application_1/monument/monument_model.dart';

class MonumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all monuments for a specific city
  Future<List<Monument>> getMonumentsForCity(City city) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('monuments')
              .where('cityId', isEqualTo: city.id)
              .get();

      return querySnapshot.docs
          .map((doc) => Monument.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching monuments: $e');
      return [];
    }
  }

  // Add a new monument
  Future<void> addMonument(Monument monument) async {
    try {
      await _firestore.collection('monuments').add(monument.toFirestore());
    } catch (e) {
      print('Error adding monument: $e');
      throw e;
    }
  }

  // Update monument details
  Future<void> updateMonument(
    String monumentId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('monuments').doc(monumentId).update(data);
    } catch (e) {
      print('Error updating monument: $e');
      throw e;
    }
  }

  // Delete a monument
  Future<void> deleteMonument(String monumentId) async {
    try {
      await _firestore.collection('monuments').doc(monumentId).delete();
    } catch (e) {
      print('Error deleting monument: $e');
      throw e;
    }
  }

  // Toggle favorite status for a monument
  Future<void> toggleFavorite(
    String monumentId,
    String userId,
    bool isFavorited,
  ) async {
    try {
      final monumentRef = _firestore.collection('monuments').doc(monumentId);

      if (isFavorited) {
        await monumentRef.update({
          'favoritedBy': FieldValue.arrayRemove([userId]),
        });
      } else {
        await monumentRef.update({
          'favoritedBy': FieldValue.arrayUnion([userId]),
        });
      }
    } catch (e) {
      print('Error toggling monument favorite status: $e');
      throw e;
    }
  }

  // Get monuments by their IDs
  Future<List<Monument>> getMonumentsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    try {
      // For large lists, you might need to batch the queries
      if (ids.length > 10) {
        List<Monument> allResults = [];

        // Process in batches of 10 (Firestore limit for whereIn)
        for (int i = 0; i < ids.length; i += 10) {
          final endIdx = (i + 10 < ids.length) ? i + 10 : ids.length;
          final batchIds = ids.sublist(i, endIdx);

          final batch =
              await _firestore
                  .collection('monuments')
                  .where(FieldPath.documentId, whereIn: batchIds)
                  .get();

          allResults.addAll(
            batch.docs.map((doc) => Monument.fromFirestore(doc)).toList(),
          );
        }

        return allResults;
      } else {
        final querySnapshot =
            await _firestore
                .collection('monuments')
                .where(FieldPath.documentId, whereIn: ids)
                .get();

        return querySnapshot.docs
            .map((doc) => Monument.fromFirestore(doc))
            .toList();
      }
    } catch (e) {
      print('Error fetching monuments by ids: $e');
      return [];
    }
  }
}
