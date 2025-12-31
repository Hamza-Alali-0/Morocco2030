import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/activity/activity_model.dart';
import 'package:flutter_application_1/city/city_model.dart';

class ActivityService {
  final CollectionReference _activitiesCollection = FirebaseFirestore.instance
      .collection('activities');

  // Get all activities for a specific city
  Future<List<Activity>> getActivitiesForCity(City city) async {
    try {
      final snapshot =
          await _activitiesCollection.where('cityId', isEqualTo: city.id).get();

      return snapshot.docs.map((doc) => Activity.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting activities: $e');
      return [];
    }
  }

  // Add a new activity
  Future<String> addActivity(Activity activity) async {
    try {
      final docRef = await _activitiesCollection.add(activity.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding activity: $e');
      rethrow;
    }
  }

  // Update an existing activity
  Future<void> updateActivity(Activity activity) async {
    try {
      await _activitiesCollection.doc(activity.id).update(activity.toMap());
    } catch (e) {
      print('Error updating activity: $e');
      rethrow;
    }
  }

  // Delete an activity
  Future<void> deleteActivity(String activityId) async {
    try {
      await _activitiesCollection.doc(activityId).delete();
    } catch (e) {
      print('Error deleting activity: $e');
      rethrow;
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String activityId, String userId) async {
    try {
      final activityDoc = await _activitiesCollection.doc(activityId).get();
      final activity = Activity.fromFirestore(activityDoc);

      List<String> updatedFavorites = List.from(activity.favoritedBy);

      if (updatedFavorites.contains(userId)) {
        updatedFavorites.remove(userId);
      } else {
        updatedFavorites.add(userId);
      }

      await _activitiesCollection.doc(activityId).update({
        'favoritedBy': updatedFavorites,
      });
    } catch (e) {
      print('Error toggling favorite: $e');
      rethrow;
    }
  }
}
