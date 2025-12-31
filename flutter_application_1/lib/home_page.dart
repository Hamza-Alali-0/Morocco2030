import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/authentification/login_page.dart';
import 'package:flutter_application_1/city/city_model.dart';
import 'package:flutter_application_1/profile/profileview.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_application_1/utils/url_utils.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/city/city_detail_screen.dart';
import 'package:flutter_application_1/activity/redeemable_activities_screen.dart';


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final user = FirebaseAuth.instance.currentUser;
  int fidelityPoints = 0;
  String userReferralCode = '';

  // City filtering
  List<City> _cities = [];
  List<City> _filteredCities = [];
  String _selectedFilter = 'All';
  String _selectedTypeFilter = 'All';
  bool _isLoading = true;
  GeoPoint? _userLocation;
  bool _isLoadingUserLocation = true;
  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    _loadCities();
    _loadUserPoints();
  }

  Future<void> _loadUserPoints() async {
    if (user == null) return;

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get();

      if (userDoc.exists) {
        setState(() {
          // Get fidelity points with fallback to 0
          fidelityPoints = userDoc.data()!['fidelityPoints'] ?? 0;
          // Get referral code with fallback
          userReferralCode =
              userDoc.data()!['referralCode'] ?? user!.uid.substring(0, 8);
        });
      }
    } catch (e) {
      print('Error loading user points: $e');
    }
  }

  Future<void> _loadUserLocation() async {
    setState(() {
      _isLoadingUserLocation = true;
    });

    try {
      if (user != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user!.uid)
                .get();

        if (userDoc.exists && userDoc.data()!.containsKey('location')) {
          setState(() {
            _userLocation = userDoc.data()!['location'] as GeoPoint;
          });
        }
      }
    } catch (e) {
      print('Error loading user location: $e');
    } finally {
      setState(() {
        _isLoadingUserLocation = false;
      });
    }
  }

  double _calculateDistance(GeoPoint point1, GeoPoint point2) {
    const double earthRadius = 6371; // Earth radius in kilometers

    // Convert to radians
    final lat1 = point1.latitude * (pi / 180);
    final lon1 = point1.longitude * (pi / 180);
    final lat2 = point2.latitude * (pi / 180);
    final lon2 = point2.longitude * (pi / 180);

    // Haversine formula
    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = earthRadius * c;

    return distance;
  }

  Future<void> _loadCities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final citiesRef = FirebaseFirestore.instance.collection('cities');
      final snapshot = await citiesRef.get();

      _cities = snapshot.docs.map((doc) => City.fromFirestore(doc)).toList();
      _filterCities(_selectedFilter, typeFilter: _selectedTypeFilter);
    } catch (e) {
      print('Error loading cities: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load cities: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterCities(String filter, {String? typeFilter}) {
    setState(() {
      _selectedFilter = filter;
      if (typeFilter != null) _selectedTypeFilter = typeFilter;

      _filteredCities =
          _cities.where((city) {
            bool matchesName =
                _selectedFilter == 'All' || city.name == _selectedFilter;
            bool matchesType =
                _selectedTypeFilter == 'All' ||
                city.type == _selectedTypeFilter;
            return matchesName && matchesType;
          }).toList();
    });
  }

  Future<void> _toggleFavorite(City city) async {
    if (user == null) return;

    try {
      final cityRef = FirebaseFirestore.instance
          .collection('cities')
          .doc(city.id);

      if (city.favoritedBy.contains(user!.uid)) {
        // Remove from favorites
        await cityRef.update({
          'favoritedBy': FieldValue.arrayRemove([user!.uid]),
        });
      } else {
        // Add to favorites
        await cityRef.update({
          'favoritedBy': FieldValue.arrayUnion([user!.uid]),
        });
      }

      // Refresh cities
      _loadCities();
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update favorite status')),
      );
    }
  }

  Future<void> _openGoogleMaps(GeoPoint location) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open maps')));
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  // Get all unique city names for filter
  List<String> get _uniqueCityNames {
    final Set<String> names = {'All'};
    for (var city in _cities) {
      names.add(city.name);
    }
    return names.toList();
  }

  // Get all unique city types for filter
  List<String> get _uniqueTypes {
    final Set<String> types = {'All'};
    for (var city in _cities) {
      types.add(city.type);
    }
    return types.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove the AppBar
      appBar: null,
      body: Stack(
        children: [
          // Column for structured layout
          Column(
            children: [
              // Banner image at the top with reduced height
              Image.asset(
                'assets/images/banner2030.png',
                height: 180, // Reduced height
                width: double.infinity,
                fit: BoxFit.cover,
              ),

              // Spacer to push content below the overlapping card
              const SizedBox(height: 50), // Keep this for card positioning
              // Filter section
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filter header row with dropdown for city types
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter By City',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065d67),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                          child: DropdownButton<String>(
                            value: _selectedTypeFilter,
                            isDense: true,
                            hint: Text(
                              ' City Type ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            items:
                                _uniqueTypes.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        type == 'All'
                                            ? const Icon(
                                              Icons.category,
                                              size: 16,
                                              color: Color(0xFF065d67),
                                            )
                                            : (type == 'Métropole'
                                                ? const Icon(
                                                  Icons.location_city,
                                                  size: 16,
                                                  color: Color(0xFF065d67),
                                                )
                                                : type == 'Côtier'
                                                ? const Icon(
                                                  Icons.beach_access,
                                                  size: 16,
                                                  color: Color(0xFF065d67),
                                                )
                                                : type == 'Montagneux'
                                                ? const Icon(
                                                  Icons.landscape,
                                                  size: 16,
                                                  color: Color(0xFF065d67),
                                                )
                                                : const Icon(
                                                  Icons.place,
                                                  size: 16,
                                                  color: Color(0xFF065d67),
                                                )),
                                        const SizedBox(width: 6),
                                        Text(
                                          type == 'All' ? 'All types' : type,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                _filterCities(
                                  _selectedFilter,
                                  typeFilter: newValue,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Reset filters + active filters display row
                    if (_selectedFilter != 'All' ||
                        _selectedTypeFilter != 'All')
                      Row(
                        children: [
                          // Reset button
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedFilter = 'All';
                                _selectedTypeFilter = 'All';
                                _filterCities('All', typeFilter: 'All');
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDCB00).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.refresh,
                                    size: 14,
                                    color: const Color(0xFF065d67),
                                  ),
                                  const SizedBox(width: 2),
                                  const Text(
                                    'Reset',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF065d67),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Active filters display
                          Expanded(
                            child: Text(
                              'Actif: ${_selectedFilter != 'All' ? _selectedFilter : ''}${_selectedFilter != 'All' && _selectedTypeFilter != 'All' ? ', ' : ''}${_selectedTypeFilter != 'All' ? _selectedTypeFilter : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 10),

                    // City filter chips - horizontal scrollable
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                          height: 36,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _uniqueCityNames.length,
                            separatorBuilder:
                                (context, index) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final cityName = _uniqueCityNames[index];
                              final isSelected = _selectedFilter == cityName;
                              return InkWell(
                                onTap: () {
                                  _filterCities(
                                    cityName,
                                    typeFilter: _selectedTypeFilter,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? const Color(0xFF065d67)
                                            : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? const Color(0xFF065d67)
                                              : Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    cityName == 'All' ? 'Toutes' : cityName,
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.black87,
                                      fontSize: 13,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                  ],
                ),
              ),

              // City cards section
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredCities.isEmpty
                        ? const Center(child: Text('No cities found'))
                        : RefreshIndicator(
                          onRefresh: _loadCities,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredCities.length,
                            itemBuilder: (context, index) {
                              final city = _filteredCities[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildCityCard(city),
                              );
                            },
                          ),
                        ),
              ),
            ],
          ),

          // Position navbar icons directly on top of the banner
          Positioned(
            top: 40, // Adjust this value as needed for proper positioning
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProfileView(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person, color: Colors.white),
                  ),
              
                  IconButton(
                    onPressed: _showFidelityPointsSystem,
                    icon: const Icon(Icons.card_giftcard, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          // Fidelity points card positioned to overlap the banner and content
          Positioned(
            top:
                140, // Adjust this down from 140 to match the reduced banner height
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Icon on the left
                      const Icon(
                        Icons.monetization_on,
                        color: Color(0xFF065d67),
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Fidelity Points',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd/MM/yyyy').format(DateTime.now()),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Points on the right
                  Text(
                    '$fidelityPoints,00',
                    style: const TextStyle(
                      color: Color(0xFF065d67),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF065d67),
        onPressed: _loadCities,
        child: const Icon(Icons.refresh),
      ),
    );
  }

 void _showFidelityPointsSystem() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Icon(
                  Icons.card_giftcard,
                  color: Color(0xFF065d67),
                  size: 56,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Fidelity Points System',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF065d67),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You currently have $fidelityPoints points',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // How to earn points
                const ListTile(
                  leading: Icon(Icons.add_circle, color: Color(0xFFFDCB00)),
                  title: Text('How to earn points'),
                  subtitle: Text(
                    'Start Booking , share the app or refer friends',
                  ),
                ),

                // Redeem points
                InkWell(
  onTap: () {
    Navigator.of(context).pop(); // Close the dialog
    // Navigate to redemption page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RedeemableActivitiesScreen(),
      ),
    );
  },
  child: const ListTile(
    leading: Icon(Icons.redeem, color: Color(0xFFFDCB00)),
    title: Text('Redeem points'),
    subtitle: Text('Ski, Karting, VIP Beaches and more'),
    trailing: Icon(Icons.arrow_forward_ios, size: 16),
  ),
),
                const Divider(height: 32),

                // Referral section
                const ListTile(
                  leading: Icon(Icons.share, color: Color(0xFFFDCB00)),
                  title: Text('Refer your friends'),
                  subtitle: Text(
                    'You receive 25 points when a friend signs up with your code',
                  ),
                ),

                const SizedBox(height: 8),

                // Referral code display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        userReferralCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1.2,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.copy,
                          color: Color(0xFF065d67),
                        ),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: userReferralCode),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Code copied to clipboard',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Share button
                ElevatedButton.icon(
                  onPressed: () {
                    // Share referral code
                    final shareMessage =
                        'Join me on CityGuide! Use my code $userReferralCode to get 25 points. https://cityguide.app/download';

                    // Show a snackbar for now (would use share plugin in real app)
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Sharing code: $userReferralCode'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share my code'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF065d67),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Keep logout for user convenience
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    signOut();
                  },
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  Widget _buildCityCard(City city) {
    bool isFavorited = city.favoritedBy.contains(user?.uid);

    // Calculate distance if user location is available
    String distanceText = '';
    if (_userLocation != null) {
      double distance = _calculateDistance(_userLocation!, city.location);
      if (distance < 1) {
        // If less than 1 km, show in meters
        distanceText = '${(distance * 1000).toStringAsFixed(0)} m';
      } else {
        // Otherwise show in kilometers
        distanceText = '${distance.toStringAsFixed(1)} km';
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => CityDetailScreen(city: city)),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // City image with action buttons overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child:
                      city.imageBase64 != null && city.imageBase64!.isNotEmpty
                          ? Image.memory(
                            base64Decode(city.imageBase64!),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                          : CachedNetworkImage(
                            imageUrl: city.imageUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                            errorWidget:
                                (context, url, error) =>
                                    const Icon(Icons.error),
                          ),
                ),
                // Type indicator
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      city.type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Heart/Favorite button
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () => _toggleFavorite(city),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavorited ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: isFavorited ? Colors.red : Colors.grey[600],
                      ),
                    ),
                  ),
                ),

                // Maps button
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () => _openGoogleMaps(city.location),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.map,
                        size: 20,
                        color: const Color(0xFF065d67),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // City details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          city.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (distanceText.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDCB00).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 16,
                                color: Color(0xFF065d67),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                distanceText,
                                style: const TextStyle(
                                  color: Color(0xFF065d67),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    city.description,
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.people, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${city.favoritedBy.length} ',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
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
  }
}
