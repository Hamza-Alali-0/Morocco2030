import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/shorts/shorts_service.dart';
import 'package:flutter_application_1/city/city_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadShortScreen extends StatefulWidget {
  final City city;

  const UploadShortScreen({Key? key, required this.city}) : super(key: key);

  @override
  State<UploadShortScreen> createState() => _UploadShortScreenState();
}

class _UploadShortScreenState extends State<UploadShortScreen> {
  final ShortsService _shortsService = ShortsService();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();

  File? _imageFile;
  bool _isUploading = false;
  String _selectedAnimation = 'zoom';
  bool _needsDisplayName = false;

  String _firstName = '';
  String _lastName = '';
  String? _profileImageBase64;

  final Color primaryColor = const Color(0xFFFDCB00);
  final Color secondaryColor = const Color(0xFF065d67);

  // Animation options
  final List<Map<String, dynamic>> _animationOptions = [
    {'name': 'Zoom', 'value': 'zoom', 'icon': Icons.zoom_in},
    {'name': 'Pulse', 'value': 'pulse', 'icon': Icons.favorite},
    {'name': 'Pan', 'value': 'pan', 'icon': Icons.pan_tool},
  ];

  @override
  void initState() {
    super.initState();
    _checkUserDisplayName();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _checkUserDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Get user profile data
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      
      setState(() {
        // Get first and last name from profile
        _firstName = userData['firstName'] ?? '';
        _lastName = userData['lastName'] ?? '';
        _profileImageBase64 = userData['profileImageBase64'];
        
        // If we didn't get name data from profile, we might need other sources
        _needsDisplayName = _firstName.isEmpty && _lastName.isEmpty && 
                           (userData['displayName'] == null && user.displayName == null);
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200, // Reduce image size
      imageQuality: 80, // Reduce quality to save space
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200, // Reduce image size
      imageQuality: 80, // Reduce quality to save space
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadShort() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Use the user's name from profile
      final user = FirebaseAuth.instance.currentUser;
      String displayName = '';
      
      if (user != null) {
        // Use first/last name from database
        if (_firstName.isNotEmpty || _lastName.isNotEmpty) {
          displayName = '$_firstName $_lastName'.trim();
        } else {
          // Fallback if no first/last name
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          final userData = userDoc.data() ?? {};
          displayName = userData['displayName'] ?? user.displayName ?? 'Anonymous';
        }
      }
    
      final result = await _shortsService.uploadShort(
        imageFile: _imageFile!,
        caption: _captionController.text.trim(),
        cityId: widget.city.id,
        cityName: widget.city.name,
        animationType: _selectedAnimation,
        userName: displayName,                   // Pass the name explicitly
        userProfileImageBase64: _profileImageBase64,  // Pass the profile pic
      );

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Short uploaded successfully')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to upload short')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Animated Short'),
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_imageFile != null)
            TextButton(
              onPressed: _isUploading ? null : _uploadShort,
              child: const Text(
                'Post',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview area
            Container(
              height: 400,
              color: Colors.black,
              child:
                  _imageFile == null
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Select or take a photo',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      )
                      : Image.file(_imageFile!, fit: BoxFit.contain),
            ),

            // Caption input
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _captionController,
                decoration: InputDecoration(
                  hintText: 'Write a caption...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
            ),

            // Animation selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Animation',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children:
                        _animationOptions.map((option) {
                          final bool isSelected =
                              _selectedAnimation == option['value'];
                          return ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  option['icon'],
                                  size: 16,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : secondaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  option['name'],
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : secondaryColor,
                                  ),
                                ),
                              ],
                            ),
                            selected: isSelected,
                            selectedColor: secondaryColor,
                            backgroundColor: Colors.grey[200],
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  _selectedAnimation = option['value'];
                                }
                              });
                            },
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),

            // Info text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Your short will be associated with ${widget.city.name}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            // Display name input (if needed)
            if (_needsDisplayName)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _displayNameController,
                  decoration: InputDecoration(
                    hintText: 'Your display name (shown with your shorts)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            // Upload status
            if (_isUploading)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      'Uploading your short...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
