import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/guide/guide_model.dart';
import 'package:flutter_application_1/city/city_model.dart';

class GuideService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all guides for a specific city
  Future<List<Guide>> getGuidesForCity(City city) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('guides')
              .where('cityId', isEqualTo: city.id)
              .get();

      return querySnapshot.docs.map((doc) => Guide.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching guides: $e');
      return [];
    }
  }

  // Add a new guide
  Future<void> addGuide(Guide guide) async {
    try {
      await _firestore.collection('guides').add(guide.toFirestore());
    } catch (e) {
      print('Error adding guide: $e');
      throw e;
    }
  }

  // Update guide details
  Future<void> updateGuide(String guideId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('guides').doc(guideId).update(data);
    } catch (e) {
      print('Error updating guide: $e');
      throw e;
    }
  }

  // Delete a guide
  Future<void> deleteGuide(String guideId) async {
    try {
      await _firestore.collection('guides').doc(guideId).delete();
    } catch (e) {
      print('Error deleting guide: $e');
      throw e;
    }
  }

  // Toggle favorite status for a guide
  Future<void> toggleFavorite(
    String guideId,
    String userId,
    bool isFavorited,
  ) async {
    try {
      final guideRef = _firestore.collection('guides').doc(guideId);

      if (isFavorited) {
        await guideRef.update({
          'favoritedBy': FieldValue.arrayRemove([userId]),
        });
      } else {
        await guideRef.update({
          'favoritedBy': FieldValue.arrayUnion([userId]),
        });
      }
    } catch (e) {
      print('Error toggling guide favorite status: $e');
      throw e;
    }
  }

  // Get guides by their IDs
  Future<List<Guide>> getGuidesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('guides')
              .where(FieldPath.documentId, whereIn: ids)
              .get();

      return querySnapshot.docs.map((doc) => Guide.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching guides by ids: $e');
      return [];
    }
  }
}
