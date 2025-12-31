import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/city/city_model.dart';
import 'package:flutter_application_1/stadium/stadium_model.dart';

class StadiumService {
  final CollectionReference stadiumCollection = FirebaseFirestore.instance
      .collection('stadiums');

  // Get all stadiums for a specific city
  Future<List<Stadium>> getStadiumsForCity(City city) async {
    try {
      QuerySnapshot querySnapshot =
          await stadiumCollection
              .where('cityId', isEqualTo: city.id)
              .orderBy('name')
              .get();

      return querySnapshot.docs
          .map((doc) => Stadium.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting stadiums: $e');
      return [];
    }
  }

  // Add a new stadium
  Future<void> addStadium(Stadium stadium) async {
    try {
      DocumentReference docRef = await stadiumCollection.add(stadium.toMap());
      stadium.id = docRef.id;
    } catch (e) {
      print('Error adding stadium: $e');
      throw e;
    }
  }

  // Get a specific stadium by ID
  Future<Stadium?> getStadiumById(String id) async {
    try {
      DocumentSnapshot doc = await stadiumCollection.doc(id).get();
      if (doc.exists) {
        return Stadium.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting stadium: $e');
      return null;
    }
  }

  // Update a stadium
  Future<void> updateStadium(Stadium stadium) async {
    try {
      await stadiumCollection.doc(stadium.id).update(stadium.toMap());
    } catch (e) {
      print('Error updating stadium: $e');
      throw e;
    }
  }

  // Delete a stadium
  Future<void> deleteStadium(String id) async {
    try {
      await stadiumCollection.doc(id).delete();
    } catch (e) {
      print('Error deleting stadium: $e');
      throw e;
    }
  }

  // Get favorite stadiums for user
  Future<List<Stadium>> getFavoriteStadiums(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (!userDoc.exists) return [];

      final userData = userDoc.data() as Map<String, dynamic>;
      List<String> favoriteIds = List<String>.from(
        userData['favoriteStadiums'] ?? [],
      );

      if (favoriteIds.isEmpty) return [];

      QuerySnapshot querySnapshot =
          await stadiumCollection
              .where(FieldPath.documentId, whereIn: favoriteIds)
              .get();

      return querySnapshot.docs
          .map((doc) => Stadium.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting favorite stadiums: $e');
      return [];
    }
  }

  // Get stadiums by IDs
  Future<List<Stadium>> getStadiumsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('stadiums')
              .where(FieldPath.documentId, whereIn: ids)
              .get();

      return querySnapshot.docs
          .map((doc) => Stadium.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching stadiums by ids: $e');
      return [];
    }
  }

  // Add favoritedBy field to stadiums
  Future<void> addFavoritedByFieldToStadiums() async {
    final stadiumsSnapshot =
        await FirebaseFirestore.instance.collection('stadiums').get();

    for (var doc in stadiumsSnapshot.docs) {
      final data = doc.data();
      if (!data.containsKey('favoritedBy')) {
        await FirebaseFirestore.instance
            .collection('stadiums')
            .doc(doc.id)
            .update({'favoritedBy': []});
        print('Added favoritedBy field to stadium: ${doc.id}');
      }
    }
  }

  // Toggle favorite status for a stadium
  Future<void> toggleFavorite(
    String stadiumId,
    String userId,
    bool isFavorited,
  ) async {
    try {
      final stadiumRef = FirebaseFirestore.instance
          .collection('stadiums')
          .doc(stadiumId);

      if (isFavorited) {
        await stadiumRef.update({
          'favoritedBy': FieldValue.arrayRemove([userId]),
        });
      } else {
        await stadiumRef.update({
          'favoritedBy': FieldValue.arrayUnion([userId]),
        });
      }
    } catch (e) {
      print('Error toggling stadium favorite status: $e');
      throw e;
    }
  }
}
