import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/activity/activity_model.dart';
import 'package:flutter_application_1/activity/activity_detail_screen.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_application_1/city/city_model.dart';

class RedeemableActivitiesScreen extends StatefulWidget {
  const RedeemableActivitiesScreen({Key? key}) : super(key: key);

  @override
  State<RedeemableActivitiesScreen> createState() =>
      _RedeemableActivitiesScreenState();
}

class _RedeemableActivitiesScreenState
    extends State<RedeemableActivitiesScreen> {
  final user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  List<Activity> _activities = [];
  int _userPoints = 0;
  String _selectedCityFilter = 'All';
  List<String> _availableCities = ['All'];
  List<Activity> _filteredActivities = [];

  // Main app color - matching app theme
  final Color primaryColor = const Color(0xFFFDCB00);
  final Color secondaryColor = const Color(0xFF065d67);

  @override
  void initState() {
    super.initState();
    _loadUserPoints();
    _loadRedeemableActivities();
    _loadCities();
  }

  Future<void> _loadUserPoints() async {
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .get();

      if (userDoc.exists) {
        setState(() {
          // Changed from 'points' to 'fidelityPoints' to match the field used elsewhere
          _userPoints = userDoc.data()?['fidelityPoints'] ?? 0;
        });
      }
    } catch (e) {
      print('Error loading user points: $e');
    }
  }

  Future<void> _loadRedeemableActivities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all activities with points requirements
      final snapshot =
          await FirebaseFirestore.instance
              .collection('activities')
              .where('pointsRequired', isGreaterThan: 0)
              .orderBy('pointsRequired')
              .get();

      setState(() {
        _activities =
            snapshot.docs.map((doc) => Activity.fromFirestore(doc)).toList();
        _applyFilters(); // Apply any existing filters
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading redeemable activities: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCities() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('cities').get();
      final cityNames =
          snapshot.docs.map((doc) => doc['name'] as String).toSet().toList();

      setState(() {
        _availableCities = ['All', ...cityNames];
      });
    } catch (e) {
      print('Error loading cities: $e');
    }
  }

  void _applyFilters() {
    if (_selectedCityFilter == 'All') {
      _filteredActivities = List.from(_activities);
    } else {
      _filteredActivities =
          _activities
              .where((activity) => activity.cityName == _selectedCityFilter)
              .toList();
    }
  }

  Future<void> _redeemActivity(Activity activity) async {
    if (_userPoints < activity.pointsRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough points to redeem this activity'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update user points - using the same approach as in ActivityDetailScreen
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .update({
            'fidelityPoints': FieldValue.increment(-activity.pointsRequired),
          })
          .then((_) {
            // Log the redemption in the same 'redemptions' collection
            return FirebaseFirestore.instance.collection('redemptions').add({
              'userId': user?.uid,
              'activityId': activity.id,
              'activityName': activity.name,
              'pointsUsed': activity.pointsRequired,
              'timestamp': FieldValue.serverTimestamp(),
            });
          });

      // Refresh user points
      await _loadUserPoints();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully redeemed ${activity.name}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error redeeming activity: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error redeeming activity: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToActivityDetail(Activity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityDetailScreen(activity: activity),
      ),
    );
  }

  // Add this method inside your _RedeemableActivitiesScreenState class
  Widget _buildImageWidget(String imageUrl) {
    // Handle base64 encoded images
    if (imageUrl.startsWith('data:image') ||
        RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(imageUrl)) {
      try {
        Uint8List imageBytes;
        if (imageUrl.startsWith('data:image')) {
          // Extract base64 data from data URL
          imageBytes = base64Decode(imageUrl.split(',')[1]);
        } else {
          // Regular base64 string
          imageBytes = base64Decode(imageUrl);
        }

        return Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading base64 image: $error');
            return _buildImageErrorPlaceholder();
          },
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return _buildImageErrorPlaceholder();
      }
    } else {
      // Network image
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder:
            (context, url) =>
                Center(child: CircularProgressIndicator(color: primaryColor)),
        errorWidget: (context, url, error) => _buildImageErrorPlaceholder(),
      );
    }
  }

  Widget _buildImageErrorPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 40),
    );
  }

  // Add this method to _RedeemableActivitiesScreenState class

  Future<bool> _isActivityRedeemed(String activityId) async {
    if (user == null) return false;

    try {
      // Check redemptions collection
      final QuerySnapshot redemptionSnapshot = await FirebaseFirestore.instance
          .collection('redemptions')
          .where('userId', isEqualTo: user!.uid)
          .where('activityId', isEqualTo: activityId)
          .limit(1)
          .get();

      // Check bookings collection
      final QuerySnapshot bookingSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user!.uid)
          .where('activityId', isEqualTo: activityId)
          .where('type', isEqualTo: 'activity')
          .limit(1)
          .get();

      return redemptionSnapshot.docs.isNotEmpty || bookingSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if activity is redeemed: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redeem Your Points'),
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Points balance card - FIXED width constraints
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 16.0,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [secondaryColor, secondaryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Points Balance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_userPoints points',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.stars_rounded, color: primaryColor, size: 36),
                ],
              ),
            ),

            // City filter dropdown
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Filter by City',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                ),
                value: _selectedCityFilter,
                items:
                    _availableCities.map((city) {
                      return DropdownMenuItem(value: city, child: Text(city));
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCityFilter = value!;
                    _applyFilters();
                  });
                },
              ),
            ),

            // FIXED: Activities list with proper Expanded
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredActivities.isEmpty
                      ? Center(
                        child: Text(
                          'No activities available for ${_selectedCityFilter != 'All' ? _selectedCityFilter : 'redemption'}',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _filteredActivities.length,
                        itemBuilder: (context, index) {
                          final activity = _filteredActivities[index];
                          final bool canRedeem =
                              _userPoints >= activity.pointsRequired;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            clipBehavior: Clip.antiAlias,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () => _navigateToActivityDetail(activity),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image section
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(12),
                                            ),
                                        child: SizedBox(
                                          height: 160,
                                          width: double.infinity,
                                          child:
                                              activity.imageUrls.isNotEmpty
                                                  ? _buildImageWidget(
                                                    activity.imageUrls.first,
                                                  )
                                                  : Container(
                                                    color: Colors.grey[200],
                                                    child: Center(
                                                      child: Icon(
                                                        Icons.image,
                                                        color: Colors.grey[400],
                                                        size: 40,
                                                      ),
                                                    ),
                                                  ),
                                        ),
                                      ),
                                      // Points badge
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            '${activity.pointsRequired}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Content section
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          activity.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          activity.cityName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          activity.description,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            height: 1.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 16),
                                        // Redeem button with proper constraints
                                        FutureBuilder<bool>(
                                          future: _isActivityRedeemed(activity.id),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              return SizedBox(
                                                width: 120, // Set the same width as your redeem button
                                                child: ElevatedButton(
                                                  onPressed: null,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.grey[300],
                                                    foregroundColor: Colors.grey[600],
                                                  ),
                                                  child: SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: primaryColor,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }

                                            final bool isRedeemed = snapshot.data ?? false;

                                            if (isRedeemed) {
                                              return Container(
                                                width: 120, // Set an appropriate width
                                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: Colors.grey[400]!),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                                                    const SizedBox(width: 4),
                                                    const Text(
                                                      'Redeemed',
                                                      style: TextStyle(
                                                        color: Colors.black87,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }

                                            return SizedBox(
                                              width: 120, // Set an appropriate width
                                              child: ElevatedButton(
                                                onPressed: canRedeem ? () => _redeemActivity(activity) : null,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: primaryColor,
                                                  foregroundColor: secondaryColor,
                                                  disabledBackgroundColor: Colors.grey[300],
                                                ),
                                                child: const Text('Redeem'),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Extracted widgets to improve layout
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 80.0,
            color: secondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16.0),
          Text(
            'No activities available',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: secondaryColor,
            ),
          ),
          const SizedBox(height: 8.0),
          const Text(
            'Check back later or try a different filter',
            style: TextStyle(fontSize: 16.0, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _filteredActivities.length,
      itemBuilder: (context, index) {
        final activity = _filteredActivities[index];
        final bool canRedeem = _userPoints >= activity.pointsRequired;

        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 8.0,
          ), // Wider margins
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: InkWell(
            onTap: () => _navigateToActivityDetail(activity),
            borderRadius: BorderRadius.circular(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Adjust image height to be shorter
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12.0),
                        topRight: Radius.circular(12.0),
                      ),
                      child: SizedBox(
                        height: 120.0, // Reduced from 150.0
                        width: double.infinity,
                        child: CachedNetworkImage(
                          imageUrl:
                              activity.imageUrls.isNotEmpty
                                  ? activity.imageUrls.first
                                  : 'https://via.placeholder.com/300x150?text=No+Image',
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => const Icon(Icons.error),
                        ),
                      ),
                    ),
                    // Points badge
                    Positioned(
                      top: 12.0,
                      right: 12.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6.0,
                          horizontal: 12.0,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.stars,
                              color: Colors.white,
                              size: 16.0,
                            ),
                            const SizedBox(width: 4.0),
                            Text(
                              '${activity.pointsRequired} points',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Activity details
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.name,
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16.0,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4.0),
                          Expanded(
                            child: Text(
                              activity.cityName,
                              style: TextStyle(color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),
                      Row(
                        children: [
                          Text(
                            'Original Price: ',
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                          Text(
                            '${activity.price.toStringAsFixed(2)} DH',
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            canRedeem
                                ? 'Available to Redeem'
                                : 'Need More Points',
                            style: TextStyle(
                              color: canRedeem ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Instead of just ElevatedButton
                          SizedBox(
                            width: 120, // Set an appropriate width
                            child: ElevatedButton(
                              onPressed:
                                  canRedeem
                                      ? () => _redeemActivity(activity)
                                      : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: secondaryColor,
                                disabledBackgroundColor: Colors.grey[300],
                              ),
                              child: const Text('Redeem'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
