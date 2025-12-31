import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/shorts/short_model.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ShortsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get shorts for a specific city
  Stream<List<Short>> getShortsForCity(String cityId) {
    print('Fetching shorts for city: $cityId');
    print('Current user: ${FirebaseAuth.instance.currentUser?.uid}');

    // Add this line to force a server fetch each time
    FirebaseFirestore.instance.clearPersistence();

    return _firestore
        .collection('shorts')
        .where('cityId', isEqualTo: cityId)
        .orderBy('createdAt', descending: true)
        // Add these options to always fetch from server
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          print('Shorts query returned ${snapshot.docs.length} documents');
          snapshot.docs.forEach(
            (doc) =>
                print('Short ID: ${doc.id}, User ID: ${doc.data()['userId']}'),
          );

          return snapshot.docs.map((doc) => Short.fromFirestore(doc)).toList();
        });
  }

  // Convert image file to base64
  Future<String> _imageToBase64(File imageFile) async {
    // Read file as bytes
    final bytes = await imageFile.readAsBytes();

    // Optionally resize/compress the image to reduce size
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize to reasonable dimensions for a short
    final resized = img.copyResize(
      image,
      width: 600, // Reduced width for Firestore size limits
    );

    // Encode as JPG with quality setting to reduce size
    final compressedBytes = img.encodeJpg(resized, quality: 70);

    // Convert to base64
    final base64String = base64Encode(compressedBytes);
    return base64String;
  }

  // Upload a short using a local image file
  Future<Short?> uploadShort({
    required File imageFile,
    required String caption,
    required String cityId,
    required String cityName,
    String animationType = 'zoom',
    String? userName,
    String? userProfileImageBase64,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Generate unique ID for the short
      final shortId = const Uuid().v4();

      // Convert image to base64
      print('Converting image to base64...');
      final imageBase64 = await _imageToBase64(imageFile);
      print('Image converted to base64, length: ${imageBase64.length}');

      // Get user data - only if not provided
      String finalUserName;
      String finalUserProfileUrl;
      
      if (userName != null && userName.isNotEmpty) {
        // Use the provided name
        finalUserName = userName;
      } else {
        // Fallback to database
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        final userData = userDoc.data() ?? {};
        finalUserName = userData['displayName'] ?? user.displayName ?? 'Anonymous';
      }
      
      if (userProfileImageBase64 != null && userProfileImageBase64.isNotEmpty) {
        // If directly provided in the call, use it
        finalUserProfileUrl = userProfileImageBase64;
      } else {
        // Get from database using our helper method
        finalUserProfileUrl = await _getUserProfileImage(user.uid);
        
        // If still empty, try Firebase Auth
        if (finalUserProfileUrl.isEmpty && user.photoURL != null) {
          finalUserProfileUrl = user.photoURL!;
        }
      }

      // Create short document
      final shortData = Short(
        id: shortId,
        userId: user.uid,
        userName: finalUserName,
        userProfileUrl: finalUserProfileUrl,
        imageBase64: imageBase64,
        caption: caption,
        cityId: cityId,
        cityName: cityName,
        likesCount: 0,
        likedBy: [],
        createdAt: Timestamp.now(),
        animationType: animationType,
      );

      // Save to Firestore
      print('Saving short to Firestore...');
      await _firestore.collection('shorts').doc(shortId).set(shortData.toMap());
      print('Short saved successfully');

      return shortData;
    } catch (e) {
      print('Error uploading short: $e');
      return null;
    }
  }

  // Toggle like on a short
  Future<bool> toggleLike(String shortId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final shortRef = _firestore.collection('shorts').doc(shortId);
      final shortDoc = await shortRef.get();

      if (!shortDoc.exists) {
        throw Exception('Short not found');
      }

      final short = Short.fromFirestore(shortDoc);
      final isLiked = short.likedBy.contains(user.uid);

      try {
        if (isLiked) {
          // Unlike
          await shortRef.update({
            'likedBy': FieldValue.arrayRemove([user.uid]),
          });
        } else {
          // Like
          await shortRef.update({
            'likedBy': FieldValue.arrayUnion([user.uid]),
          });
        }
        return true;
      } catch (e) {
        print('Firebase error toggling like: $e');
        return false;
      }
    } catch (e) {
      print('Error toggling like: $e');
      // Re-throw so the UI can handle it
      throw e;
    }
  }

  // Delete a short
  Future<bool> deleteShort(String shortId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final shortRef = _firestore.collection('shorts').doc(shortId);
      final shortDoc = await shortRef.get();

      if (!shortDoc.exists) {
        throw Exception('Short not found');
      }

      final short = Short.fromFirestore(shortDoc);

      // Only the creator can delete
      if (short.userId != user.uid) {
        throw Exception('Not authorized to delete this short');
      }

      await shortRef.delete();
      return true;
    } catch (e) {
      print('Error deleting short: $e');
      return false;
    }
  }

  // Add this method
  Future<List<Short>> fetchShortsForCityDirectly(String cityId) async {
    print('Direct fetch for shorts with cityId: $cityId');

    final snapshot =
        await _firestore
            .collection('shorts')
            .where('cityId', isEqualTo: cityId)
            .get();

    print('Direct query returned ${snapshot.docs.length} shorts');

    return snapshot.docs.map((doc) => Short.fromFirestore(doc)).toList();
  }

  // Add this helper method to get profile image correctly
  Future<String> _getUserProfileImage(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return '';
      
      final userData = userDoc.data() ?? {};
      
      // Add profileImageBase64 to the list of field names to check
      final profileImage = userData['profileImageBase64'] ?? 
                          userData['profileImage'] ?? 
                          userData['profileImageUrl'] ?? 
                          userData['profilePicture'] ?? 
                          userData['photoURL'] ?? 
                          userData['avatar'] ?? 
                          '';
                          
      return profileImage;
    } catch (e) {
      print('Error fetching profile image: $e');
      return '';
    }
  }
}
