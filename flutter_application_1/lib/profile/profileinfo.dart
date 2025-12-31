import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/home_page.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class ProfileInfoPage extends StatefulWidget {
  static route() =>
      MaterialPageRoute(builder: (context) => const ProfileInfoPage());

  const ProfileInfoPage({Key? key}) : super(key: key);

  @override
  State<ProfileInfoPage> createState() => _ProfileInfoPageState();
}

class _ProfileInfoPageState extends State<ProfileInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _countryController = TextEditingController();
  final _referralCodeController = TextEditingController();

  DateTime? _selectedDate;
  String _phoneNumber = '';
  String _phoneCountryCode = '+1';
  String _phoneCountryIsoCode = '';

  File? _profileImage;
  String? _base64Image;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  String? _errorMessage;

  LatLng? _selectedLocation;
  String _locationAddress = '';
  bool _isCheckingReferral = false;
  bool? _isReferralValid;
  String? _referralMessage;
  Timer? _debounce;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _countryController.dispose();
    _referralCodeController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _checkReferralCode(String code) async {
    // Clear previous validation state if empty
    if (code.isEmpty) {
      setState(() {
        _isReferralValid = null;
        _referralMessage = null;
      });
      return;
    }

    setState(() {
      _isCheckingReferral = true;
      _isReferralValid = null;
      _referralMessage = null;
    });

    try {
      // Simplify: First check if the code format is valid (8 characters)
      if (code.length != 8) {
        setState(() {
          _isReferralValid = false;
          _referralMessage = 'Format de code invalide';
        });
        return;
      }

      print('Checking referral code: $code');

      // Check if the code exists in Firestore
      final QuerySnapshot referrerQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('referralCode', isEqualTo: code)
              .get();

      print('Query completed: ${referrerQuery.docs.length} matches found');

      if (referrerQuery.docs.isEmpty) {
        setState(() {
          _isReferralValid = false;
          _referralMessage = 'Code de parrainage invalide';
        });
        return;
      }

      // Success case - simplified
      setState(() {
        _isReferralValid = true;
        _referralMessage = 'Code valide! Vous recevrez 25 points';
      });
    } catch (e) {
      print('Error checking referral code: $e');
      // Show error but allow the user to proceed
      setState(() {
        _isReferralValid = null; // Set to null instead of false
        _referralMessage = 'Vérification temporairement indisponible';
      });
    } finally {
      setState(() {
        _isCheckingReferral = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300, // Restrict image size
        maxHeight: 300,
        imageQuality: 70, // Compress the image
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });

        // Convert to base64
        final bytes = await _profileImage!.readAsBytes();

        // Check if image size is too large (800KB limit to stay under Firestore's 1MB document limit)
        if (bytes.length > 800 * 1024) {
          setState(() {
            _errorMessage = "Image too large. Please select a smaller image.";
            _profileImage = null;
          });
          return;
        }

        setState(() {
          _base64Image = base64Encode(bytes);
        });
      }
    } on PlatformException catch (e) {
      setState(() {
        _errorMessage = "Failed to pick image: ${e.message}";
      });
    } catch (e) {
      setState(() {
        _errorMessage = "An error occurred while selecting image";
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final location = loc.Location();

      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          return;
        }
      }

      loc.PermissionStatus permissionStatus = await location.hasPermission();
      if (permissionStatus == loc.PermissionStatus.denied) {
        permissionStatus = await location.requestPermission();
        if (permissionStatus != loc.PermissionStatus.granted) {
          return;
        }
      }

      final locationData = await location.getLocation();
      final latLng = LatLng(locationData.latitude!, locationData.longitude!);

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        locationData.latitude!,
        locationData.longitude!,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _selectedLocation = latLng;
          _locationAddress =
              '${place.street}, ${place.locality}, ${place.country}';
          _countryController.text = place.country ?? '';
        });
      }
    } catch (e) {
      print("Error getting location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to get location. Please try again.")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showLocationPicker() async {
    // For simplicity, we're just using current location
    await _getCurrentLocation();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if phone number is provided
    if (_phoneNumber.isEmpty) {
      setState(() {
        _errorMessage = "Please enter your phone number";
      });
      return;
    }

    // Check if date of birth is selected
    if (_selectedDate == null) {
      setState(() {
        _errorMessage = "Please select your date of birth";
      });
      return;
    }

    // Check if user is 18 or older
    final DateTime today = DateTime.now();
    final DateTime minimumDate = DateTime(
      today.year - 18,
      today.month,
      today.day,
    );

    if (_selectedDate!.isAfter(minimumDate)) {
      setState(() {
        _errorMessage = "You must be at least 18 years old to register";
      });
      return;
    }

    // Check if location is selected
    if (_selectedLocation == null) {
      setState(() {
        _errorMessage = "Please select your location";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }
      final String? referralCode =
          _referralCodeController.text.trim().isNotEmpty
              ? _referralCodeController.text.trim()
              : null;

      // Process referral if code was provided
      if (referralCode != null) {
        await _processReferral(referralCode, user.uid);
      }

      // Create unique referral code for this user
      final String userReferralCode = user.uid.substring(0, 8);

      // Create profile data with optional base64 image
      final profileData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'country': _countryController.text.trim(),
        'phoneNumber': _phoneNumber,
        'phoneCountryCode': _phoneCountryCode,
        'phoneCountryIsoCode': _phoneCountryIsoCode,
        'dateOfBirth': Timestamp.fromDate(_selectedDate!),
        'location': GeoPoint(
          _selectedLocation!.latitude,
          _selectedLocation!.longitude,
        ),
        'locationAddress': _locationAddress,
        'profileImageBase64': _base64Image, // Store image as base64 string
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'hasCompletedProfile': true,
        'referralCode': userReferralCode, // Save user's own referral code
        'fidelityPoints':
            referralCode != null
                ? 25
                : 0, // Start with 25 points if used a referral
      };
      // Save to Firestore database
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(profileData);

      // Navigate to home page
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MyHomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to save profile: ${e.toString()}";
      });
      print("Error saving profile: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

 Future<void> _processReferral(String referralCode, String newUserId) async {
  try {
    print('Starting referral process with code: $referralCode');

    // Find the user with this referral code
    final QuerySnapshot referrerQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('referralCode', isEqualTo: referralCode)
        .limit(1)
        .get();

    if (referrerQuery.docs.isEmpty) {
      print('Referral code not found during processing: $referralCode');
      return;
    }

    final String referrerId = referrerQuery.docs.first.id;
    print('Found referrer with ID: $referrerId');

    // Don't allow self-referrals
    if (referrerId == newUserId) {
      print('Self-referral attempt rejected');
      return;
    }

    // Get current referrer document
    final DocumentSnapshot referrerDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(referrerId)
        .get();

    // Check if document exists
    if (!referrerDoc.exists) {
      print('Referrer document not found');
      return;
    }

    // Update referrer's points
    final Map<String, dynamic> referrerUpdates = {};
    int referrerCurrentPoints = 0;
    if (referrerDoc.data() != null) {
      final referrerData = referrerDoc.data() as Map<String, dynamic>;
      referrerCurrentPoints = referrerData['fidelityPoints'] ?? 0;
    }
    referrerUpdates['fidelityPoints'] = referrerCurrentPoints + 25;

    // Update referred users array
    List<String> referredUsers = [];
    if (referrerDoc.data() != null) {
      final referrerData = referrerDoc.data() as Map<String, dynamic>;
      if (referrerData.containsKey('referredUsers')) {
        referredUsers = List<String>.from(referrerData['referredUsers']);
      }
    }

    // Add the new user if not already in the list
    if (!referredUsers.contains(newUserId)) {
      referredUsers.add(newUserId);
    }
    referrerUpdates['referredUsers'] = referredUsers;

    // Update the referrer's document
    print(
      'Updating referrer with points (current: $referrerCurrentPoints, new: ${referrerCurrentPoints + 25})',
    );
    await FirebaseFirestore.instance
        .collection('users')
        .doc(referrerId)
        .update(referrerUpdates);

    print('Successfully awarded 25 points to referrer');

    // Update the new user's points
    final DocumentSnapshot newUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(newUserId)
        .get();

    if (newUserDoc.exists) {
      final Map<String, dynamic> newUserUpdates = {};
      int newUserCurrentPoints = 0;
      if (newUserDoc.data() != null) {
        final newUserData = newUserDoc.data() as Map<String, dynamic>;
        newUserCurrentPoints = newUserData['fidelityPoints'] ?? 0;
      }
      newUserUpdates['fidelityPoints'] = newUserCurrentPoints + 25;

      // Update the new user's document
      print(
        'Updating new user with points (current: $newUserCurrentPoints, new: ${newUserCurrentPoints + 25})',
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(newUserId)
          .update(newUserUpdates);

      print('Successfully awarded 25 points to new user');
    }
  } catch (e) {
    print('Error in referral processing: $e');
    // We'll still continue with user creation even if referral fails
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: const Color(0xFF065d67),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                          _profileImage != null
                              ? FileImage(_profileImage!) as ImageProvider
                              : const AssetImage(
                                'assets/images/placeholder_profile.jpg',
                              ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF065d67),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'Please complete your profile',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // First Name
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Last Name
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Country of Residence
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Country of Residence',
                  prefixIcon: Icon(Icons.flag_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your country';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Phone Number with country code
              IntlPhoneField(
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                initialCountryCode: 'MA',
                onChanged: (phone) {
                  setState(() {
                    _phoneNumber = phone.number;
                    _phoneCountryCode = phone.countryCode;
                    _phoneCountryIsoCode =
                        phone.countryISOCode; // Add this line
                  });
                },
                validator: (phone) {
                  if (phone == null || phone.number.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Date of Birth
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _selectedDate == null
                        ? 'Select your date of birth'
                        : DateFormat('MMMM d, yyyy').format(_selectedDate!),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Location picker
              InkWell(
                onTap: _showLocationPicker,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Your Location',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _locationAddress.isEmpty
                        ? 'Select your location'
                        : _locationAddress,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Get current location button
              TextButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Use current location'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF065d67),
                ),
              ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),

              // Referral Code (Optional)
              TextFormField(
                controller: _referralCodeController,
                decoration: InputDecoration(
                  labelText: 'Code de parrainage (Optionnel)',
                  prefixIcon: Icon(Icons.card_giftcard),
                  border: OutlineInputBorder(),
                  hintText: 'Entrez un code si vous en avez un',
                  helperText:
                      _referralMessage ??
                      'Recevez 25 points en entrant un code de parrainage',
                  helperStyle: TextStyle(
                    color:
                        _isReferralValid == null
                            ? Colors.grey
                            : (_isReferralValid! ? Colors.green : Colors.red),
                  ),
                  suffixIcon:
                      _isCheckingReferral
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : _isReferralValid == null
                          ? null
                          : Icon(
                            _isReferralValid!
                                ? Icons.check_circle
                                : Icons.error,
                            color:
                                _isReferralValid! ? Colors.green : Colors.red,
                          ),
                ),
                onChanged: (value) {
                  // Debounce input to avoid too many requests
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 800), () {
                    _checkReferralCode(value.trim());
                  });
                },
              ),

              const SizedBox(height: 24),

              // Submit button
              _isLoading
                  ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF065d67),
                    ),
                  )
                  : ElevatedButton(
                    onPressed: _submitProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF065d67),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'SAVE PROFILE',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
