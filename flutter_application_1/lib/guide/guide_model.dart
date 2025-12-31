import 'package:cloud_firestore/cloud_firestore.dart';

class Guide {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String educationLevel;
  final String profileImageUrl; // New field for profile picture
  final List<String> imageUrls;
  final List<String> activities;
  final String description;
  final int yearsOfExperience;
  final List<String> languages;
  final String cityId;
  final String cityName;
  final double rating;
  final String specialization;
  final List<String> favoritedBy;
  final double hourlyRate;

  Guide({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.educationLevel,
    this.profileImageUrl = '', // Default empty string
    required this.imageUrls,
    required this.activities,
    required this.description,
    required this.yearsOfExperience,
    required this.languages,
    required this.cityId,
    required this.cityName,
    required this.rating,
    required this.specialization,
    this.favoritedBy = const [],
    required this.hourlyRate,
  });

  String get fullName => '$firstName $lastName';

  factory Guide.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Guide(
      id: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      educationLevel: data['educationLevel'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      activities: List<String>.from(data['activities'] ?? []),
      description: data['description'] ?? '',
      yearsOfExperience: (data['yearsOfExperience'] ?? 0),
      languages: List<String>.from(data['languages'] ?? []),
      cityId: data['cityId'] ?? '',
      cityName: data['cityName'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      specialization: data['specialization'] ?? '',
      favoritedBy: List<String>.from(data['favoritedBy'] ?? []),
      hourlyRate: (data['hourlyRate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'educationLevel': educationLevel,
      'profileImageUrl': profileImageUrl,
      'imageUrls': imageUrls,
      'activities': activities,
      'description': description,
      'yearsOfExperience': yearsOfExperience,
      'languages': languages,
      'cityId': cityId,
      'cityName': cityName,
      'rating': rating,
      'specialization': specialization,
      'favoritedBy': favoritedBy,
      'hourlyRate': hourlyRate,
    };
  }
}
