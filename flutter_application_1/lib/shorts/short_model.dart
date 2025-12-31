import 'package:cloud_firestore/cloud_firestore.dart';

class Short {
  final String id;
  final String userId;
  final String userName;
  final String userProfileUrl;
  final String imageBase64; // Changed to base64 string
  final String caption;
  final String cityId;
  final String cityName;
  final int likesCount;
  final List<String> likedBy;
  final Timestamp createdAt;
  final String animationType;

  Short({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userProfileUrl,
    required this.imageBase64, // Base64 encoded image
    required this.caption,
    required this.cityId,
    required this.cityName,
    required this.likesCount,
    required this.likedBy,
    required this.createdAt,
    required this.animationType,
  });

  factory Short.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Short(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userProfileUrl: data['userProfileUrl'] ?? '',
      imageBase64: data['imageBase64'] ?? '',
      caption: data['caption'] ?? '',
      cityId: data['cityId'] ?? '',
      cityName: data['cityName'] ?? '',
      likesCount: data['likesCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      animationType: data['animationType'] ?? 'zoom',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userProfileUrl': userProfileUrl,
      'imageBase64': imageBase64,
      'caption': caption,
      'cityId': cityId,
      'cityName': cityName,
      'likesCount': likesCount,
      'likedBy': likedBy,
      'createdAt': createdAt,
      'animationType': animationType,
    };
  }

  // Add this helper method to the Short class
  bool get isProfileImageBase64 {
    return userProfileUrl.startsWith('data:image') ||
        RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(userProfileUrl);
  }
}
