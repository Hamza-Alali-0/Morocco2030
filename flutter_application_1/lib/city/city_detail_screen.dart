import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/city/city_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/restaurant/restaurant_model.dart';
import 'package:flutter_application_1/restaurant/restaurant_service.dart';
import 'package:flutter_application_1/restaurant/restaurant_detail.dart';
import 'package:flutter_application_1/restaurant/menu_item_model.dart';
import 'package:flutter_application_1/restaurant/menu_service.dart';
import 'package:flutter_application_1/restaurant/add_menu_item_screen.dart';
import 'package:flutter_application_1/restaurant/menu_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_application_1/guide/guide_model.dart';
import 'package:flutter_application_1/guide/guide_service.dart';
import 'package:flutter_application_1/guide/guide_detail_screen.dart';
import 'package:flutter_application_1/stadium/stadium_model.dart';
import 'package:flutter_application_1/stadium/stadium_service.dart';
import 'package:flutter_application_1/stadium/stadium_detail_screen.dart';
import 'package:flutter_application_1/monument/monument_model.dart';
import 'package:flutter_application_1/monument/monument_service.dart';
import 'package:flutter_application_1/monument/monument_detail_screen.dart';
import 'package:flutter_application_1/mall/mall_model.dart';
import 'package:flutter_application_1/mall/mall_service.dart';
import 'package:flutter_application_1/mall/mall_detail_screen.dart';
import 'package:flutter_application_1/shorts/short_model.dart';
import 'package:flutter_application_1/shorts/short_player_screen.dart';
import 'package:flutter_application_1/shorts/short_thumbnail.dart';
import 'package:flutter_application_1/shorts/shorts_service.dart';
import 'package:flutter_application_1/shorts/upload_short_screen.dart';
import 'package:flutter_application_1/transportation/transportation_model.dart';
import 'package:flutter_application_1/transportation/transportation_service.dart';
import 'package:flutter_application_1/transportation/transportation_screen.dart';
import 'package:flutter_application_1/transportation/fare_calculator_screen.dart';
import 'package:flutter_application_1/activity/redeemable_activities_screen.dart';
import 'package:flutter_application_1/location/location_model.dart';
import 'package:flutter_application_1/location/location_service.dart';
import 'package:flutter_application_1/location/location_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class CityDetailScreen extends StatefulWidget {
  final City city;

  const CityDetailScreen({Key? key, required this.city}) : super(key: key);

  @override
  State<CityDetailScreen> createState() => _CityDetailScreenState();
}

class _CityDetailScreenState extends State<CityDetailScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final user = FirebaseAuth.instance.currentUser;
  int fidelityPoints = 0;
  String selectedCategory = 'Tendance'; // Default selected category
  bool isLoading = false;
  late AnimationController _animationController;
  final RestaurantService _restaurantService = RestaurantService();
  List<Restaurant> _restaurants = [];
  String _selectedRestaurantType = 'All';
  List<String> _restaurantTypes = [
    'All',
    'Restaurant',
    'Café',
    'Fast Food',
    'Bakery',
  ];
  List<Restaurant> _filteredRestaurants = [];

  final ShortsService _shortsService = ShortsService();
  List<Short> _shorts = [];
  bool _isShortsLoading = false;
  Map<String, int> _categoryLikesCount = {};
  List<String> _mostLikedCategories = [];
  final GuideService _guideService = GuideService();
  List<Guide> _guides = [];
  String _selectedGuideSpecialization = 'All';
  List<String> _guideSpecializations = [
    'All',
    'Historical Sites',
    'Cultural Tours',
    'Adventure Tourism',
    'Culinary Experiences',
    'Art & Museums',
    'Nature & Wildlife',
    'Religious Sites',
  ];
  List<Guide> _filteredGuides = [];
  String _selectedStadiumType = 'All';
  List<String> _stadiumTypes = [
    'All',
    'Soccer',
    'Basketball',
    'Tennis',
    'Olympic',
    'Multi-sport',
  ];
  // Location state
final LocationService _locationService = LocationService();
List<Location> _locations = [];
String _selectedLocationType = 'All';
List<String> _locationTypes = [
  'All',
  'Hotel',
  'Apartment',
  'Hostel',
  'Villa',
  'Riad',
];
List<Location> _filteredLocations = [];
List<Location> _likedLocations = [];

  final MonumentService _monumentService = MonumentService();
  List<Monument> _monuments = [];
  String _selectedMonumentType = 'All';
  List<String> _monumentTypes = [
    'All',
    'Historical',
    'Religious',
    'Cultural',
    'Museum',
    'Natural',
    'Archaeological',
    'Modern',
  ];
  final MallService _mallService = MallService();
  List<Mall> _malls = [];
  String _selectedMallCategory = 'All';
  List<String> _mallCategories = [
    'All',
    'Shopping Mall',
    'Outlet Mall',
    'Strip Mall',
    'Lifestyle Center',
    'Open-Air Mall',
  ];
  
List<String> _transportTypes = [
  'All',
  'Taxi',
  'Bus',
  'Tram',
  'Train',
  'Ride-sharing',
];
String _selectedTransportType = 'All';
  // Stadium state
  final StadiumService _stadiumService = StadiumService();
  List<Stadium> _stadiums = [];
  List<Stadium> _filteredStadiums = [];
  List<Monument> _filteredMonuments = [];
  List<Monument> _likedMonuments = [];
  List<Mall> _filteredMalls = [];
  List<Mall> _likedMalls = [];
  List<Short> _likedShorts = [];
  // Transportation state
final TransportationService _transportService = TransportationService();
List<TransportRoute> _transportRoutes = [];
List<TransportRoute> _filteredTransportRoutes = [];
  // Liked items tracking
  bool _isLoadingLikedItems = false;
  List<Restaurant> _likedRestaurants = [];
  List<Guide> _likedGuides = [];
  List<Stadium> _likedStadiums = [];
// Add to your state class variables
Map<String, bool> _collapsedCategories = {};
final ScrollController _categoriesScrollController = ScrollController();
  // Main app color
  final Color primaryColor = const Color(0xFFFDCB00);
  final Color secondaryColor = const Color(0xFF065d67);

  @override
  void initState() {
    super.initState();
    _loadUserPoints();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _searchController.addListener(_onSearchChanged);

    // Initialize with restaurants if that's the default category
    if (selectedCategory == 'Tendance') {
      _loadShorts();
      _loadAllCategories();
    }
    if (selectedCategory == 'Location') {
  _loadLocations();
}
    if (selectedCategory == 'Restau & café') {
      _loadRestaurants();
    }
    // Initialize with guides if that's the selected category
    if (selectedCategory == 'Guides') {
      _loadGuides();
    }
    // Initialize with stadiums if that's the selected category
    if (selectedCategory == 'Stadium') {
      _loadStadiums();
    }
    if (selectedCategory == 'Monuments') {
      _loadMonuments();
    }
    if (selectedCategory == 'Malls') {
      _loadMalls();
    }

    // Load liked items when the screen is initialized
    if (user != null) {
      _loadLikedItems();
    }
  }

  Future<void> _loadAllCategories() async {
    setState(() {
      isLoading = true;
    });

    try {
      await Future.wait([
        _loadRestaurants(),
        _loadGuides(),
        _loadStadiums(),
        _loadMonuments(),
        _loadMalls(),
      ]);

      _calculateMostLikedCategories();
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading all categories: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
  Future<void> _loadLocations() async {
  setState(() {
    isLoading = true;
  });

  try {
    final locations = await _locationService.getLocationsForCity(widget.city);

    setState(() {
      _locations = locations;
      _filterLocationsByType(); // Apply filter
      isLoading = false;
    });

    // Start animation after data is loaded
    _animationController.reset();
    _animationController.forward();
  } catch (e) {
    print('Error loading locations: $e');
    setState(() {
      isLoading = false;
    });
  }
}

void _filterLocationsByType() {
  if (_selectedLocationType == 'All') {
    _filteredLocations = List.from(_locations);
  } else {
    _filteredLocations = _locations
        .where((location) => location.type == _selectedLocationType)
        .toList();
  }
}
Future<void> _loadTransportation() async {
  setState(() {
    isLoading = true;
  });

  try {
    final routes = await _transportService.getRoutesForCity(widget.city);

    setState(() {
      _transportRoutes = routes;
      _filterTransportByType(); // Apply filter
      isLoading = false;
    });

    // Start animation after data is loaded
    _animationController.reset();
    _animationController.forward();
  } catch (e) {
    print('Error loading transportation routes: $e');
    setState(() {
      isLoading = false;
    });
  }
}
  Future<void> _loadShorts() async {
  setState(() {
    _isShortsLoading = true;
  });

  try {
    // Force a server fetch to get the most up-to-date data
    final snapshot = await FirebaseFirestore.instance
      .collection('shorts')
      .where('cityId', isEqualTo: widget.city.id)
      .get(const GetOptions(source: Source.server)); // Force server fetch
      
    final shorts = snapshot.docs.map((doc) => Short.fromFirestore(doc)).toList();

    if (mounted) {
      setState(() {
        _shorts = shorts;
        _isShortsLoading = false;
      });

      // Start animation after data is loaded
      _animationController.reset();
      _animationController.forward();
    }
  } catch (e) {
    print('Error loading shorts: $e');
    
    // Fallback to regular query if server query fails
    try {
      final shortsStream = _shortsService.getShortsForCity(widget.city.id);
      final shorts = await shortsStream.first;
      
      if (mounted) {
        setState(() {
          _shorts = shorts;
          _isShortsLoading = false;
        });
      }
    } catch (secondaryError) {
      print('Error in fallback shorts loading: $secondaryError');
      if (mounted) {
        setState(() {
          _isShortsLoading = false;
        });
      }
    }
  }
}

  void _calculateMostLikedCategories() {
    // Reset the counts
    _categoryLikesCount = {};

    // Count likes for restaurants by type
    for (final restaurant in _restaurants) {
      if (restaurant.favoritedBy.isNotEmpty) {
        final type = restaurant.type;
        _categoryLikesCount[type] =
            (_categoryLikesCount[type] ?? 0) + restaurant.favoritedBy.length;
      }
    }

    // Count likes for guides by specialization
    for (final guide in _guides) {
      if (guide.favoritedBy.isNotEmpty) {
        final specialization = guide.specialization;
        _categoryLikesCount[specialization] =
            (_categoryLikesCount[specialization] ?? 0) +
            guide.favoritedBy.length;
      }
    }

    // Count likes for stadiums by type
    for (final stadium in _stadiums) {
      if (stadium.favoritedBy.isNotEmpty) {
        final type = stadium.type;
        _categoryLikesCount[type] =
            (_categoryLikesCount[type] ?? 0) + stadium.favoritedBy.length;
      }
    }

    // Count likes for monuments by type
    for (final monument in _monuments) {
      if (monument.favoritedBy.isNotEmpty) {
        final type = monument.type;
        _categoryLikesCount[type] =
            (_categoryLikesCount[type] ?? 0) + monument.favoritedBy.length;
      }
    }

    // Count likes for malls by type
    for (final mall in _malls) {
      if (mall.favoritedBy.isNotEmpty) {
        final type = mall.type;
        _categoryLikesCount[type] =
            (_categoryLikesCount[type] ?? 0) + mall.favoritedBy.length;
      }
    }

    // Sort categories by like count and take top ones
    final sortedEntries =
        _categoryLikesCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Get top 4 categories or less if fewer exist
    _mostLikedCategories = sortedEntries.take(4).map((e) => e.key).toList();
  }
Future<void> _loadLocationsLikedByUser(String userId) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('locations')
        .where('favoritedBy', arrayContains: userId)
        .get();

    final locations = snapshot.docs.map((doc) => Location.fromFirestore(doc)).toList();
    print('Found ${locations.length} locations liked by user');

    setState(() {
      _likedLocations = locations;
    });
  } catch (e) {
    print('Error fetching liked locations: $e');
  }
}
  Future<void> _loadLikedItems() async {
    if (user == null) {
      print('User is null - cannot load liked items');
      return;
    }

    final userId = user!.uid;
    print('Attempting to load likes for user ID: $userId');

    setState(() {
      _isLoadingLikedItems = true;
      _likedRestaurants = [];
      _likedGuides = [];
      _likedStadiums = [];
      _likedMonuments = [];
      _likedMalls = [];
       _likedShorts = [];
    });

    try {
      await Future.wait([
        _loadRestaurantsLikedByUser(userId),
        _loadGuidesLikedByUser(userId),
        _loadStadiumsLikedByUser(userId),
        _loadMonumentsLikedByUser(userId),
        _loadMallsLikedByUser(userId),
          _loadShortsLikedByUser(userId), 
          _loadLocationsLikedByUser(userId), 
      ]);

      print('Successfully loaded liked items:');
      print('Restaurants: ${_likedRestaurants.length}');
      print('Guides: ${_likedGuides.length}');
      print('Stadiums: ${_likedStadiums.length}');
      print('Monuments: ${_likedMonuments.length}');
      print('Malls: ${_likedMalls.length}');
       print('Shorts: ${_likedShorts.length}'); 
    } catch (e) {
      print('Error loading liked items: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLikedItems = false;
        });
      }
    }
  }


Future<void> _loadShortsLikedByUser(String userId) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('shorts')
        .where('likedBy', arrayContains: userId)
        .get();

    final shorts = snapshot.docs.map((doc) => Short.fromFirestore(doc)).toList();
    print('Found ${shorts.length} shorts liked by user');

    setState(() {
      _likedShorts = shorts;
    });
  } catch (e) {
    print('Error fetching liked shorts: $e');
  }
}
  // Load restaurants where user is in favoritedBy array
  Future<void> _loadRestaurantsLikedByUser(String userId) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('restaurants')
              .where('favoritedBy', arrayContains: userId)
              .get();

      final restaurants =
          snapshot.docs.map((doc) => Restaurant.fromFirestore(doc)).toList();
      print('Found ${restaurants.length} restaurants liked by user');

      setState(() {
        _likedRestaurants = restaurants;
      });
    } catch (e) {
      print('Error fetching liked restaurants: $e');
    }
  }

  // Load guides where user is in favoritedBy array
  Future<void> _loadGuidesLikedByUser(String userId) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('guides')
              .where('favoritedBy', arrayContains: userId)
              .get();

      final guides =
          snapshot.docs.map((doc) => Guide.fromFirestore(doc)).toList();
      print('Found ${guides.length} guides liked by user');

      setState(() {
        _likedGuides = guides;
      });
    } catch (e) {
      print('Error fetching liked guides: $e');
    }
  }

  // Load stadiums where user is in favoritedBy array
  Future<void> _loadStadiumsLikedByUser(String userId) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('stadiums')
              .where('favoritedBy', arrayContains: userId)
              .get();

      final stadiums =
          snapshot.docs.map((doc) => Stadium.fromFirestore(doc)).toList();
      print('Found ${stadiums.length} stadiums liked by user');

      setState(() {
        _likedStadiums = stadiums;
      });
    } catch (e) {
      print('Error fetching liked stadiums: $e');
    }
  }

  Future<void> _loadMonuments() async {
    setState(() {
      isLoading = true;
    });

    try {
      final monuments = await _monumentService.getMonumentsForCity(widget.city);

      setState(() {
        _monuments = monuments;
        _filterMonumentsByType(); // Apply filter
        isLoading = false;
      });

      // Start animation after data is loaded
      _animationController.reset();
      _animationController.forward();
    } catch (e) {
      print('Error loading monuments: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterMonumentsByType() {
    if (_selectedMonumentType == 'All') {
      _filteredMonuments = List.from(_monuments);
    } else {
      _filteredMonuments =
          _monuments
              .where((monument) => monument.type == _selectedMonumentType)
              .toList();
    }
  }

  Future<void> _loadMallsLikedByUser(String userId) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('malls')
              .where('favoritedBy', arrayContains: userId)
              .get();

      final malls =
          snapshot.docs.map((doc) => Mall.fromFirestore(doc)).toList();
      print('Found ${malls.length} malls liked by user');

      setState(() {
        _likedMalls = malls;
      });
    } catch (e) {
      print('Error fetching liked malls: $e');
    }
  }

  // Load monuments where user is in favoritedBy array
  Future<void> _loadMonumentsLikedByUser(String userId) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('monuments')
              .where('favoritedBy', arrayContains: userId)
              .get();

      final monuments =
          snapshot.docs.map((doc) => Monument.fromFirestore(doc)).toList();
      print('Found ${monuments.length} monuments liked by user');

      setState(() {
        _likedMonuments = monuments;
      });
    } catch (e) {
      print('Error fetching liked monuments: $e');
    }
  }

  Future<void> _toggleLikeItem(String itemId, String type, String name) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to like items')),
      );
      return;
    }

    final userId = user!.uid;

    try {
      // 1. First determine which collection to access
      String collectionName;
      switch (type) {
        case 'restaurants':
          collectionName = 'restaurants';
          break;
        case 'guides':
          collectionName = 'guides';
          break;
        case 'stadiums':
          collectionName = 'stadiums';
          break;
        case 'malls':
          collectionName = 'malls';
          break;
            case 'monuments':  
        collectionName = 'monuments';
        break;
      case 'shorts': 
        collectionName = 'shorts';
        break;
        default:
          print('Unknown item type: $type');
          return;
      }

      // 2. Access the document to check if the user already liked it
      final itemRef = FirebaseFirestore.instance
          .collection(collectionName)
          .doc(itemId);
      final itemDoc = await itemRef.get();

      if (!itemDoc.exists) {
        print('Item not found: $type/$itemId');
        return;
      }

      final data = itemDoc.data() as Map<String, dynamic>;
    // Handle difference between shorts and other types
    List<dynamic> likedByArray;
    String arrayFieldName;
    
    if (type == 'shorts') {
      likedByArray = data['likedBy'] ?? [];
      arrayFieldName = 'likedBy';
    } else {
      likedByArray = data['favoritedBy'] ?? [];
      arrayFieldName = 'favoritedBy';
    }
    
    final bool isLiked = likedByArray.contains(userId);

    // 3. Update the likes collection on the user document
    final likeRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('likes')
        .doc('$type-$itemId');

    if (isLiked) {
      // Unlike: Remove user ID from array in item document
      await itemRef.update({
        arrayFieldName: FieldValue.arrayRemove([userId]),
      });

      // Also remove from user's likes collection
      if ((await likeRef.get()).exists) {
        await likeRef.delete();
      }

      // Update UI immediately
      setState(() {
        if (type == 'restaurants') {
          _likedRestaurants.removeWhere((item) => item.id == itemId);
        } else if (type == 'guides') {
          _likedGuides.removeWhere((item) => item.id == itemId);
        } else if (type == 'stadiums') {
          _likedStadiums.removeWhere((item) => item.id == itemId);
        } else if (type == 'monuments') {
          _likedMonuments.removeWhere((item) => item.id == itemId);
        } else if (type == 'malls') {
          _likedMalls.removeWhere((item) => item.id == itemId);
        } else if (type == 'shorts') {
          _likedShorts.removeWhere((item) => item.id == itemId);
        }
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Removed $name from favorites')));
    } else {
      // Like: Add user ID to array in item document
      await itemRef.update({
        arrayFieldName: FieldValue.arrayUnion([userId]),
      });

      // Also add to user's likes collection
      await likeRef.set({
        'itemId': itemId,
        'type': type,
        'name': name,
        'timestamp': FieldValue.serverTimestamp(),
        'cityId': widget.city.id,
      });

      // Reload liked items to update the UI
      await _loadLikedItems();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Added $name to favorites')));
    }
  } catch (e) {
    print('Error toggling like status: $e');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Error updating favorites: $e')));
  }
}
void _filterTransportByType() {
  if (_selectedTransportType == 'All') {
    _filteredTransportRoutes = List.from(_transportRoutes);
  } else {
    _filteredTransportRoutes = _transportRoutes.where((route) {
      // Convert enum value to string and compare with selected type
      String routeType = route.type.toString().split('.').last;
      return routeType.toLowerCase() == _selectedTransportType.toLowerCase();
    }).toList();
  }
}

IconData _getTransportTypeIcon(String type) {
  switch (type) {
    case 'Taxi':
      return Icons.local_taxi;
    case 'Bus':
      return Icons.directions_bus;
    case 'Tram':
      return Icons.tram;
    case 'Train':
      return Icons.train;
    case 'Ride-sharing':
      return Icons.car_rental;
    case 'All':
    default:
      return Icons.commute;
  }
}

  Future<void> _loadMalls() async {
    setState(() {
      isLoading = true;
    });

    try {
      final malls = await _mallService.getMallsForCity(widget.city);

      setState(() {
        _malls = malls;
        _filterMallsByCategory(); // Apply filter
        isLoading = false;
      });

      // Start animation after data is loaded
      _animationController.reset();
      _animationController.forward();
    } catch (e) {
      print('Error loading malls: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterMallsByCategory() {
    if (_selectedMallCategory == 'All') {
      _filteredMalls = List.from(_malls);
    } else {
      _filteredMalls =
          _malls.where((mall) => mall.type == _selectedMallCategory).toList();
    }
  }

  Future<bool> _isItemLiked(String itemId, String type) async {
    if (user == null) return false;

    try {
      final likeDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .collection('likes')
              .doc('$type-$itemId')
              .get();

      return likeDoc.exists;
    } catch (e) {
      print('Error checking like status: $e');
      return false;
    }
  }

  void _filterStadiumsByType() {
    if (_selectedStadiumType == 'All') {
      _filteredStadiums = List.from(_stadiums);
    } else {
      _filteredStadiums =
          _stadiums
              .where((stadium) => stadium.type == _selectedStadiumType)
              .toList();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _animationController.dispose();
     _categoriesScrollController.dispose(); // Add this line
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  bool _categoryMatchesSearch(String category) {
    if (_searchQuery.isEmpty) return true;
    return category.toLowerCase().contains(_searchQuery);
  }

  void _showFidelityPointsSystem() {
    String userReferralCode = user?.uid.substring(0, 8) ?? '';

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
                  Icon(Icons.card_giftcard, color: secondaryColor, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'Fidelity Points System',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
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
                  ListTile(
                    leading: Icon(Icons.add_circle, color: primaryColor),
                    title: const Text('How to earn points'),
                    subtitle: const Text(
                      'Start Booking, share the app or refer friends',
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
  child: ListTile(
    leading: Icon(Icons.redeem, color: primaryColor),
    title: const Text('Redeem points'),
    subtitle: const Text(
      'Ski, Karting, VIP Beaches and more',
    ),
    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
  ),
),
                  const Divider(height: 32),

                  // Referral section
                  ListTile(
                    leading: Icon(Icons.share, color: primaryColor),
                    title: const Text('Refer your friends'),
                    subtitle: const Text(
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
                          icon: Icon(Icons.copy, color: secondaryColor),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: userReferralCode),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Code copied to clipboard'),
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
                      backgroundColor: secondaryColor,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
          fidelityPoints = userDoc.data()!['fidelityPoints'] ?? 0;
        });
      }
    } catch (e) {
      print('Error loading user points: $e');
    }
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      isLoading = true;
    });

    try {
      final restaurants = await _restaurantService.getRestaurantsForCity(
        widget.city,
      );

      setState(() {
        _restaurants = restaurants;
        _filterRestaurantsByType(); // Apply filter
        isLoading = false;
      });

      // Start animation after data is loaded
      _animationController.reset();
      _animationController.forward();
    } catch (e) {
      print('Error loading restaurants: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadGuides() async {
    setState(() {
      isLoading = true;
    });

    try {
      final guides = await _guideService.getGuidesForCity(widget.city);

      setState(() {
        _guides = guides;
        _filterGuidesBySpecialization(); // Apply filter
        isLoading = false;
      });

      // Start animation after data is loaded
      _animationController.reset();
      _animationController.forward();
    } catch (e) {
      print('Error loading guides: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadStadiums() async {
    setState(() {
      isLoading = true;
    });

    try {
      final stadiums = await _stadiumService.getStadiumsForCity(widget.city);

      setState(() {
        _stadiums = stadiums;
        _filterStadiumsByType(); // Apply filter instead of direct assignment
        isLoading = false;
      });

      _animationController.reset();
      _animationController.forward();
    } catch (e) {
      print('Error loading stadiums: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterRestaurantsByType() {
    if (_selectedRestaurantType == 'All') {
      _filteredRestaurants = List.from(_restaurants);
    } else {
      _filteredRestaurants =
          _restaurants
              .where((restaurant) => restaurant.type == _selectedRestaurantType)
              .toList();
    }
  }

  void _filterGuidesBySpecialization() {
    if (_selectedGuideSpecialization == 'All') {
      _filteredGuides = List.from(_guides);
    } else {
      _filteredGuides =
          _guides
              .where(
                (guide) => guide.specialization == _selectedGuideSpecialization,
              )
              .toList();
    }
  }

  Future<void> _toggleFavorite() async {
    // Get current user
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to favorite cities'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final cityRef = FirebaseFirestore.instance
          .collection('cities')
          .doc(widget.city.id);

      // Check if city is already favorited
      bool isFavorited = widget.city.favoritedBy.contains(user.uid);

      if (isFavorited) {
        // Remove from favorites
        await cityRef.update({
          'favoritedBy': FieldValue.arrayRemove([user.uid]),
        });

        setState(() {
          widget.city.favoritedBy.remove(user.uid);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${widget.city.name} from favorites'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Add to favorites
        await cityRef.update({
          'favoritedBy': FieldValue.arrayUnion([user.uid]),
        });

        setState(() {
          widget.city.favoritedBy.add(user.uid);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${widget.city.name} to favorites'),
            backgroundColor: Colors.green[400],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating favorites: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openCityInMaps() async {
    try {
      final latitude = widget.city.location.latitude;
      final longitude = widget.city.location.longitude;

      final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open maps: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildStadiumImageItem(String imageSource) {
    if (imageSource.startsWith('data:image')) {
      try {
        String base64String = imageSource.split(',')[1];
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            print('Error rendering base64 stadium image: $error');
            return _buildImageErrorPlaceholder();
          },
        );
      } catch (e) {
        print('Error decoding base64 stadium image: $e');
        return _buildImageErrorPlaceholder();
      }
    } else if (RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(imageSource)) {
      try {
        return Image.memory(
          base64Decode(imageSource),
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildImageErrorPlaceholder();
          },
        );
      } catch (e) {
        print('Error decoding raw base64 stadium image: $e');
        return _buildImageErrorPlaceholder();
      }
    } else {
      // For regular URLs
      return CachedNetworkImage(
        imageUrl: imageSource,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder:
            (context, url) =>
                Center(child: CircularProgressIndicator(color: primaryColor)),
        errorWidget: (context, url, error) => _buildImageErrorPlaceholder(),
      );
    }
  }
  Widget _buildLocationItem(Location location) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocationDetailScreen(location: location),
        ),
      );
    },
    child: AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.5, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval(0.2, 0.8, curve: Curves.easeOutCubic),
            ),
          ),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(0.2, 0.8, curve: Curves.easeOut),
              ),
            ),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: location.imageUrls.isNotEmpty
                      ? SizedBox(
                          height: 120,
                          child: PageView.builder(
                            itemCount: location.imageUrls.length,
                            itemBuilder: (context, index) {
                              return _buildLocationImageItem(
                                location.imageUrls[index],
                              );
                            },
                          ),
                        )
                      : Container(
                          height: 120,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: Icon(
                            _getLocationTypeIcon(location.type),
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () async {
                          await _toggleLikeItem(
                            location.id,
                            'locations',
                            location.name,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            location.favoritedBy.contains(user?.uid)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 18,
                            color: location.favoritedBy.contains(user?.uid)
                                ? Colors.red
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          final latitude = location.location.latitude;
                          final longitude = location.location.longitude;

                          final url = Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
                          );

                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.directions,
                            size: 18,
                            color: secondaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          location.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star, size: 14, color: primaryColor),
                            const SizedBox(width: 2),
                            Text(
                              location.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location.type,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          location.address,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${location.pricePerNight.toStringAsFixed(0)} MAD/night',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: secondaryColor,
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
    ),
  );
}

Widget _buildLocationImageItem(String imageSource) {
  if (imageSource.startsWith('data:image')) {
    try {
      String base64String = imageSource.split(',')[1];
      return Image.memory(
        base64Decode(base64String),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          print('Error rendering base64 location image: $error');
          return _buildImageErrorPlaceholder();
        },
      );
    } catch (e) {
      print('Error decoding base64 location image: $e');
      return _buildImageErrorPlaceholder();
    }
  } else if (RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(imageSource)) {
    try {
      return Image.memory(
        base64Decode(imageSource),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageErrorPlaceholder();
        },
      );
    } catch (e) {
      print('Error decoding raw base64 location image: $e');
      return _buildImageErrorPlaceholder();
    }
  } else {
    return CachedNetworkImage(
      imageUrl: imageSource,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (context, url) => Center(
        child: CircularProgressIndicator(color: primaryColor),
      ),
      errorWidget: (context, url, error) => _buildImageErrorPlaceholder(),
    );
  }
}
  Widget _buildTransportationItem(TransportRoute route) {
  final String routeType = route.type.toString().split('.').last;
  final Color routeColor = _getTransportTypeColor(route.type);
  
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FareCalculatorScreen(
            city: widget.city,
            transportType: route.type,
          ),
        ),
      );
    },
    child: AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.5, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval(0.2, 0.8, curve: Curves.easeOutCubic),
            ),
          ),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(0.2, 0.8, curve: Curves.easeOut),
              ),
            ),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route map visualization
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                color: Colors.grey[200],
              ),
              child: CustomPaint(
                painter: RouteMapPainter(
                  startPoint: route.startLocation,
                  endPoint: route.endLocation,
                  routeColor: routeColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          route.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: routeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(_getTransportTypeIcon(routeType), size: 14, color: routeColor),
                            const SizedBox(width: 4),
                            Text(
                              routeType,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: routeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.green),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          route.startName,
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.red),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          route.endName,
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      route.schedule.isNotEmpty 
                          ? Row(
                              children: [
                                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 3),
                                Text(
                                  route.schedule,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            )
                          : const SizedBox(),
                      Text(
                        'From ${route.baseFare.toStringAsFixed(1)} MAD',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: secondaryColor,
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
    ),
  );
}

// Add this helper method to get transport colors
Color _getTransportTypeColor(TransportType type) {
  switch (type) {
    case TransportType.taxi:
      return Colors.amber;
    case TransportType.bus:
      return Colors.blue;
    case TransportType.tramway:
      return Colors.green;
    case TransportType.train:
      return Colors.red;
    default:
      return Colors.purple;
  }
}

  Widget _buildMonumentImageItem(String imageSource) {
    if (imageSource.startsWith('data:image')) {
      try {
        String base64String = imageSource.split(',')[1];
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            print('Error rendering base64 monument image: $error');
            return _buildImageErrorPlaceholder();
          },
        );
      } catch (e) {
        print('Error decoding base64 monument image: $e');
        return _buildImageErrorPlaceholder();
      }
    } else if (RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(imageSource)) {
      try {
        return Image.memory(
          base64Decode(imageSource),
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildImageErrorPlaceholder();
          },
        );
      } catch (e) {
        print('Error decoding raw base64 monument image: $e');
        return _buildImageErrorPlaceholder();
      }
    } else {
      // For regular URLs
      return CachedNetworkImage(
        imageUrl: imageSource,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder:
            (context, url) =>
                Center(child: CircularProgressIndicator(color: primaryColor)),
        errorWidget: (context, url, error) => _buildImageErrorPlaceholder(),
      );
    }
  }

  Widget _buildShortsGrid() {
    if (_isShortsLoading) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (_shorts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
           
            Icon(Icons.image_not_supported, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No shorts available for ${widget.city.name}',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UploadShortScreen(city: widget.city),
                  ),
                ).then((_) => _loadShorts());
              },
              icon: const Icon(Icons.add),
              label: const Text('Add new short'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _shorts.length > 8 ? 8 : _shorts.length, // Show max 8 shorts
      itemBuilder: (context, index) {
        final short = _shorts[index];
       // Build custom thumbnail instead of using ShortThumbnail widget
     return GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShortPlayerScreen(
          initialIndex: index,
          shorts: _shorts,
        ),
      ),
    ).then((_) {
      if (mounted) {
        _loadShorts();
      }
    });
  },
  child: Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Short thumbnail image (existing code)
          short.imageBase64.isNotEmpty
              ? Image.memory(
                  base64Decode(short.imageBase64),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
                )
              : Container(
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.image,
                    color: Colors.grey[600],
                  ),
                ),
          
          // Gradient overlay for better text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.7, 1.0],
              ),
            ),
          ),
          
          // User info at bottom
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                // User profile picture
                CircleAvatar(
                  radius: 12,
                  backgroundImage: short.userProfileUrl.isNotEmpty
                      ? (short.isProfileImageBase64
                          ? MemoryImage(base64Decode(short.userProfileUrl))
                          : NetworkImage(short.userProfileUrl)) as ImageProvider
                      : null,
                  child: short.userProfileUrl.isEmpty
                      ? const Icon(Icons.person, size: 12)
                      : null,
                ),
                const SizedBox(width: 4),
                // Username
                Expanded(
                  child: Text(
                    short.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                // Like count (existing code)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, color: Colors.red, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      '${short.likedBy.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
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
  ),
);
    },
  );
}
  Widget _buildPopularCategories() {
  if (_mostLikedCategories.isEmpty) {
    return Container();
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Popular Categories',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: secondaryColor,
          ),
        ),
      ),
      
      // Build a section for each category
      ..._mostLikedCategories.map((category) => _buildCategorySection(category)).toList(),
    ],
  );
}
Widget _buildCategorySection(String category) {
  // Initialize to expanded if not set yet
  _collapsedCategories.putIfAbsent(category, () => false);
  bool isCollapsed = _collapsedCategories[category]!;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Category header with title and show more button
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  _getCategoryIconForName(category),
                  size: 20,
                  color: primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: secondaryColor,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${_categoryLikesCount[category]}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            // Toggle button and "Show More" button
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    // Navigate to category view
                    setState(() {
                      if (_restaurantTypes.contains(category)) {
                        selectedCategory = 'Restau & café';
                        _selectedRestaurantType = category;
                        _loadRestaurants();
                      } else if (_guideSpecializations.contains(category)) {
                        selectedCategory = 'Guides';
                        _selectedGuideSpecialization = category;
                        _loadGuides();
                      } else if (_stadiumTypes.contains(category)) {
                        selectedCategory = 'Stadium';
                        _selectedStadiumType = category;
                        _loadStadiums();
                      } else if (_monumentTypes.contains(category)) {
                        selectedCategory = 'Monuments';
                        _selectedMonumentType = category;
                        _loadMonuments();
                      } else if (_mallCategories.contains(category)) {
                        selectedCategory = 'Malls';
                        _selectedMallCategory = category;
                        _loadMalls();
                      }
                    });
                  },
                  child: Text(
                    'Show More',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isCollapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _collapsedCategories[category] = !isCollapsed;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
      
      // Collapsible content - Horizontal scrollable list
         AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
        firstChild: const SizedBox.shrink(),
        secondChild: SizedBox(
          height: 180, // Increased height to prevent overflow
          child: _buildCategoryHorizontalList(category),
        ),
        crossFadeState: isCollapsed ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      ),
      // Divider after each category
      Divider(color: Colors.grey[300]),
    ],
  );
}

Widget _buildCategoryHorizontalList(String category) {
  // Get items for this category based on category type
  List<dynamic> items = _getItemsForCategory(category);
  
  if (items.isEmpty) {
    return Center(
      child: Text(
        'No items found for this category',
        style: TextStyle(color: Colors.grey[600]),
      ),
    );
  }
  
  return Container(
    height: 165,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: items.length > 10 ? 10 : items.length, // Limit items shown
      itemBuilder: (context, index) {
        return _buildCategoryItemCard(items[index], category);
      },
    ),
  );
}

List<dynamic> _getItemsForCategory(String category) {
  // Return the appropriate items based on category type
  if (_restaurantTypes.contains(category)) {
    return _restaurants.where((r) => r.type == category).toList();
  } else if (_guideSpecializations.contains(category)) {
    return _guides.where((g) => g.specialization == category).toList();
  } else if (_stadiumTypes.contains(category)) {
    return _stadiums.where((s) => s.type == category).toList();
  } else if (_monumentTypes.contains(category)) {
    return _monuments.where((m) => m.type == category).toList();
  } else if (_mallCategories.contains(category)) {
    return _malls.where((m) => m.type == category).toList();
  }
  return [];
}

Widget _buildCategoryItemCard(dynamic item, String categoryType) {
  // Create a card for an item based on its type
  String name = '';
  String imageUrl = '';
  String subtitle = '';
  double rating = 0;
  VoidCallback onTap;
  
  if (item is Restaurant) {
    name = item.name;
    imageUrl = item.imageUrls.isNotEmpty ? item.imageUrls.first : '';
    subtitle = item.cuisine;
    rating = item.rating;
    onTap = () => Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => RestaurantDetailScreen(restaurant: item))
    );
  } else if (item is Guide) {
    name = item.fullName;
    imageUrl = item.profileImageUrl.isNotEmpty ? item.profileImageUrl : 
              (item.imageUrls.isNotEmpty ? item.imageUrls.first : '');
    subtitle = item.specialization;
    rating = item.rating;
    onTap = () => Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => GuideDetailScreen(guide: item))
    );
  } else if (item is Stadium) {
    name = item.name;
    imageUrl = item.imageUrls.isNotEmpty ? item.imageUrls.first : '';
    subtitle = item.type;
    rating = item.rating;
    onTap = () => Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => StadiumDetailScreen(stadium: item))
    );
  } else if (item is Monument) {
    name = item.name;
    imageUrl = item.imageUrls.isNotEmpty ? item.imageUrls.first : '';
    subtitle = item.type;
    rating = item.rating;
    onTap = () => Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => MonumentDetailScreen(monument: item))
    );
  } else if (item is Mall) {
    name = item.name;
    imageUrl = item.imageUrls.isNotEmpty ? item.imageUrls.first : '';
    subtitle = item.type;
    rating = item.rating;
    onTap = () => Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => MallDetailScreen(mall: item))
    );
  } else {
    return Container(); // Empty container if unknown type
  }

  // Return a consistent card design
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 140,
       height: 160, 
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                     child: SizedBox(
              height: 90,
              width: double.infinity,
              child: imageUrl.isNotEmpty
                ? _buildImageBasedOnSource(imageUrl)
                : Container(
                    color: Colors.grey[200],
                    child: Icon(
                      _getCategoryIconForName(categoryType),
                      size: 30,
                      color: Colors.grey[400],
                    ),
                  ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, 
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, size: 12, color: primaryColor),
                    const SizedBox(width: 2),
                    Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
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
Widget _buildImageBasedOnSource(String imageSource) {
  if (imageSource.startsWith('data:image')) {
    try {
      String base64String = imageSource.split(',')[1];
      return Image.memory(
        base64Decode(base64String),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImageErrorPlaceholder(),
      );
    } catch (e) {
      return _buildImageErrorPlaceholder();
    }
  } else if (RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(imageSource)) {
    try {
      return Image.memory(
        base64Decode(imageSource),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImageErrorPlaceholder(),
      );
    } catch (e) {
      return _buildImageErrorPlaceholder();
    }
  } else {
    return CachedNetworkImage(
      imageUrl: imageSource,
      fit: BoxFit.cover,
      placeholder: (context, url) => Center(
        child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2)
      ),
      errorWidget: (context, url, error) => _buildImageErrorPlaceholder(),
    );
  }
}

  IconData _getCategoryIconForName(String category) {
    // Restaurant types
    if (_restaurantTypes.contains(category)) {
      return _getRestaurantTypeIcon(category);
    }
    // Guide specializations
    if (_guideSpecializations.contains(category)) {
      return _getGuideSpecializationIcon(category);
    }
    // Stadium types
    if (_stadiumTypes.contains(category)) {
      return _getStadiumTypeIcon(category);
    }
    // Monument types
    if (_monumentTypes.contains(category)) {
      return _getMonumentTypeIcon(category);
    }
    // Mall categories
    if (_mallCategories.contains(category)) {
      return _getMallCategoryIcon(category);
    }

    return Icons.category;
  }

  Widget _buildMonumentItem(Monument monument) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MonumentDetailScreen(monument: monument),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.5, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(0.2, 0.8, curve: Curves.easeOutCubic),
              ),
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(0.2, 0.8, curve: Curves.easeOut),
                ),
              ),
              child: child,
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child:
                        monument.imageUrls.isNotEmpty
                            ? SizedBox(
                              height: 120,
                              child: PageView.builder(
                                itemCount: monument.imageUrls.length,
                                itemBuilder: (context, index) {
                                  return _buildMonumentImageItem(
                                    monument.imageUrls[index],
                                  );
                                },
                              ),
                            )
                            : Container(
                              height: 120,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.account_balance,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                            ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      onTap: () async {
                        final latitude = monument.location.latitude;
                        final longitude = monument.location.longitude;

                        final url = Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
                        );

                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.directions,
                          size: 18,
                          color: secondaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            monument.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star, size: 14, color: primaryColor),
                              const SizedBox(width: 2),
                              Text(
                                monument.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      monument.type,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            monument.address,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          monument.entranceFee > 0
                              ? '${monument.entranceFee} MAD'
                              : 'Free',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: secondaryColor,
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
      ),
    );
  }
  Widget _buildLikedLocationsView(ScrollController scrollController) {
  return ListView.builder(
    controller: scrollController,
    padding: const EdgeInsets.all(12),
    itemCount: _likedLocations.length,
    itemBuilder: (context, index) {
      final location = _likedLocations[index];
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: location.imageUrls.isNotEmpty
                ? SizedBox(
                    width: 56,
                    height: 56,
                    child: _buildLocationImageItem(location.imageUrls.first),
                  )
                : Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey[200],
                    child: Icon(Icons.home, color: Colors.grey[400]),
                  ),
          ),
          title: Text(
            location.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(location.type, overflow: TextOverflow.ellipsis),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${location.pricePerNight.toStringAsFixed(0)} MAD',
                style: TextStyle(
                  color: secondaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red),
                onPressed: () async {
                  await _toggleLikeItem(location.id, 'locations', location.name);
                  Navigator.pop(context);
                  _showLikedItemsBottomSheet();
                },
                iconSize: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LocationDetailScreen(location: location),
              ),
            );
          },
        ),
      );
    },
  );
}
  Widget _buildLikedShortsView(ScrollController scrollController) {
  return Column(
    children: [
      // Header with count
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Liked Shorts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: secondaryColor,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_likedShorts.length}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Media slider for shorts
      Expanded(
        child: GridView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _likedShorts.length,
          itemBuilder: (context, index) {
            final short = _likedShorts[index];
            return GestureDetector(
              onTap: () {
                Navigator.pop(context); // Close bottom sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShortPlayerScreen(
                      initialIndex: 0,
                      shorts: _likedShorts,
                    ),
                  ),
                ).then((_) {
                  if (mounted) {
                    _loadShorts();
                    _loadLikedItems();
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Short thumbnail
                      short.imageBase64.isNotEmpty
                          ? Image.memory(
                              base64Decode(short.imageBase64),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.error),
                              ),
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.image,
                                color: Colors.grey[600],
                              ),
                            ),
                      
                     
                      
                      // Caption overlay
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                short.caption,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${short.likedBy.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Unlike button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () async {
      // Use the same _toggleLikeItem method that other items use
      await _toggleLikeItem(short.id, 'shorts', short.caption);
      
      // Force reload shorts data to update all UI elements
      if (mounted) {
        _loadShorts();
        
        // Refresh the liked items list
        await _loadLikedItems();
      }
    },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

  void _showLikedItemsBottomSheet() {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to view your liked items'),
        ),
      );
      return;
    }

    // Set loading state
    setState(() {
      _isLoadingLikedItems = true;
    });

    // Refresh liked items data before showing the bottom sheet
    _loadLikedItems().then((_) {
      // Show the bottom sheet after data is loaded
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.3,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Draggable handle
                    Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),

                    Expanded(
                      child: DefaultTabController(
                        length: 6,
                        child: Column(
                          children: [
                            TabBar(
                              tabs: const [
                                Tab(text: 'Restaurants'),
                                Tab(text: 'Guides'),
                                Tab(text: 'Locations'),
                                Tab(text: 'Stadiums'),
                                Tab(text: 'Monuments'),
                                Tab(text: 'Malls'),
                                Tab(text: 'Shorts'),
                              ],
                              labelColor: secondaryColor,
                              unselectedLabelColor: Colors.grey[600],
                              indicatorColor: primaryColor,
                              isScrollable: true,
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  // Restaurants tab
                                  _isLoadingLikedItems
                                      ? Center(
                                        child: CircularProgressIndicator(
                                          color: primaryColor,
                                        ),
                                      )
                                      : _likedRestaurants.isEmpty
                                      ? _buildEmptyLikedItemsView('restaurants')
                                      : _buildLikedRestaurantsView(
                                        scrollController,
                                      ),
                                      _isLoadingLikedItems
                                          ? Center(child: CircularProgressIndicator(color: primaryColor))
                                          : _likedLocations.isEmpty
                                              ? _buildEmptyLikedItemsView('locations')
                                              : _buildLikedLocationsView(scrollController),
                                  // Guides tab
                                  _isLoadingLikedItems
                                      ? Center(
                                        child: CircularProgressIndicator(
                                          color: primaryColor,
                                        ),
                                      )
                                      : _likedGuides.isEmpty
                                      ? _buildEmptyLikedItemsView('guides')
                                      : _buildLikedGuidesView(scrollController),

                                  // Stadiums tab
                                  _isLoadingLikedItems
                                      ? Center(
                                        child: CircularProgressIndicator(
                                          color: primaryColor,
                                        ),
                                      )
                                      : _likedStadiums.isEmpty
                                      ? _buildEmptyLikedItemsView('stadiums')
                                      : _buildLikedStadiumsView(
                                        scrollController,
                                      ),
                                  // Monuments tab
                                  _isLoadingLikedItems
                                      ? Center(
                                        child: CircularProgressIndicator(
                                          color: primaryColor,
                                        ),
                                      )
                                      : _likedMonuments.isEmpty
                                      ? _buildEmptyLikedItemsView('monuments')
                                      : _buildLikedMonumentsView(
                                        scrollController,
                                      ),
                                  //  malls
                                  _isLoadingLikedItems
                                      ? Center(
                                        child: CircularProgressIndicator(
                                          color: primaryColor,
                                        ),
                                      )
                                      : _likedMalls.isEmpty
                                      ? _buildEmptyLikedItemsView('malls')
                                      : _buildLikedMallsView(scrollController),
                              // Shorts tab - New
                                _isLoadingLikedItems
                                    ? Center(
                                        child: CircularProgressIndicator(
                                          color: primaryColor,
                                        ),
                                      )
                                    : _likedShorts.isEmpty
                                        ? _buildEmptyLikedItemsView('shorts')
                                        : _buildLikedShortsView(scrollController),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    });
  }

  Widget _buildEmptyLikedItemsView(String type) {
    String message;
    IconData icon;

    switch (type) {
      case 'restaurants':
        message = 'No liked restaurants yet';
        icon = Icons.restaurant;
        break;
      case 'guides':
        message = 'No liked guides yet';
        icon = Icons.tour;
        break;
      case 'stadiums':
        message = 'No liked stadiums yet';
        icon = Icons.stadium;
        break;
      case 'monuments':
        message = 'No liked monuments yet';
        icon = Icons.account_balance;
        break;
        case 'malls':
      message = 'No liked malls yet';
      icon = Icons.storefront;
      break;
    case 'shorts':
      message = 'No liked shorts yet';
      icon = Icons.video_library;
      break; 
      default:
        message = 'No liked items yet';
        icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                if (type == 'restaurants') {
                  selectedCategory = 'Restau & café';
                  _loadRestaurants();
                } else if (type == 'guides') {
                  selectedCategory = 'Guides';
                  _loadGuides();
                } else if (type == 'stadiums') {
                  selectedCategory = 'Stadium';
                  _loadStadiums();
                } else if (type == 'monuments') {
                  selectedCategory = 'Monuments';
                  _loadMonuments();
               } else if (type == 'malls') {
                selectedCategory = 'Malls';
                _loadMalls();
              } else if (type == 'shorts') {
                selectedCategory = 'Tendance';
                _loadShorts();
              }
              });
            },
            icon: const Icon(Icons.search),
            label: Text('Browse ${type.substring(0, type.length - 1)}s'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikedRestaurantsView(ScrollController scrollController) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _likedRestaurants.length,
      itemBuilder: (context, index) {
        final restaurant = _likedRestaurants[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  restaurant.imageUrls.isNotEmpty
                      ? SizedBox(
                        width: 56,
                        height: 56,
                        child: _buildRestaurantImageItem(
                          restaurant.imageUrls.first,
                        ),
                      )
                      : Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey[200],
                        child: Icon(Icons.restaurant, color: Colors.grey[400]),
                      ),
            ),
            title: Text(
              restaurant.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(restaurant.cuisine, overflow: TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  restaurant.rating.toString(),
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.star, size: 16, color: primaryColor),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () async {
                    await _toggleLikeItem(
                      restaurant.id,
                      'restaurants',
                      restaurant.name,
                    );
                    Navigator.pop(context);
                    _showLikedItemsBottomSheet();
                  },
                  iconSize: 22,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          RestaurantDetailScreen(restaurant: restaurant),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLikedGuidesView(ScrollController scrollController) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _likedGuides.length,
      itemBuilder: (context, index) {
        final guide = _likedGuides[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  guide.profileImageUrl.isNotEmpty
                      ? SizedBox(
                        width: 56,
                        height: 56,
                        child: _buildGuideImageItem(guide.profileImageUrl),
                      )
                      : guide.imageUrls.isNotEmpty
                      ? SizedBox(
                        width: 56,
                        height: 56,
                        child: _buildGuideImageItem(guide.imageUrls.first),
                      )
                      : Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey[200],
                        child: Icon(Icons.person, color: Colors.grey[400]),
                      ),
            ),
            title: Text(
              guide.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              guide.specialization,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  guide.rating.toStringAsFixed(1),
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.star, size: 16, color: primaryColor),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () async {
                    await _toggleLikeItem(guide.id, 'guides', guide.fullName);
                    Navigator.pop(context);
                    _showLikedItemsBottomSheet();
                  },
                  iconSize: 22,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GuideDetailScreen(guide: guide),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLikedStadiumsView(ScrollController scrollController) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _likedStadiums.length,
      itemBuilder: (context, index) {
        final stadium = _likedStadiums[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  stadium.imageUrls.isNotEmpty
                      ? SizedBox(
                        width: 56,
                        height: 56,
                        child: _buildStadiumImageItem(stadium.imageUrls.first),
                      )
                      : Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey[200],
                        child: Icon(Icons.stadium, color: Colors.grey[400]),
                      ),
            ),
            title: Text(
              stadium.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(stadium.type, overflow: TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stadium.rating.toStringAsFixed(1),
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.star, size: 16, color: primaryColor),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () async {
                    await _toggleLikeItem(stadium.id, 'stadiums', stadium.name);
                    Navigator.pop(context);
                    _showLikedItemsBottomSheet();
                  },
                  iconSize: 22,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StadiumDetailScreen(stadium: stadium),
                ),
              );
            },
          ),
        );
      },
    );
  }
  // Create a new method for unliking items directly from the liked items sheet

  // Add this debugging method to check database likes
  Future<void> _debugLikes() async {
    if (user == null) return;

    try {
      print('==== DEBUGGING LIKES ====');

      // Check the subcollection directly
      final likesSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .collection('likes')
              .get();

      print('Found ${likesSnapshot.docs.length} likes in subcollection');

      // Print each like for debugging
      likesSnapshot.docs.forEach((doc) {
        print('Like ID: ${doc.id}, Data: ${doc.data()}');
      });

      // Check if data matches expected structure
      print('Current like counts:');
      print('Restaurants: ${_likedRestaurants.length}');
      print('Guides: ${_likedGuides.length}');
      print('Stadiums: ${_likedStadiums.length}');
      print(
        'Total: ${_likedRestaurants.length + _likedGuides.length + _likedStadiums.length + _likedMonuments.length + _likedMalls.length}',
      );
    } catch (e) {
      print('Error debugging likes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.city.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
              constraints: const BoxConstraints(minWidth: 40),
            ),
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              constraints: const BoxConstraints(minWidth: 40),
            ),
          ],
        ),
        leadingWidth: 96,
        actions: [
          IconButton(
            icon: const Icon(Icons.map, color: Colors.white),
            onPressed: _openCityInMaps,
          ),
          IconButton(
            icon: Icon(
              widget.city.favoritedBy.contains(user?.uid)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color:
                  widget.city.favoritedBy.contains(user?.uid)
                      ? Colors.red
                      : Colors.white,
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.card_giftcard, color: Colors.white),
            onPressed: _showFidelityPointsSystem,
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: InkWell(
              onTap: _showLikedItemsBottomSheet,
              borderRadius: BorderRadius.circular(50),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.favorite, color: Colors.white, size: 24),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '${_likedRestaurants.length + _likedGuides.length + _likedStadiums.length + _likedMonuments.length + _likedMalls.length + _likedShorts.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
     
              
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // City Image Header with Fidelity Points
            Stack(
              children: [
                Container(
                  height: 180 + MediaQuery.of(context).padding.top,
                  width: double.infinity,
                  child:
                      widget.city.imageBase64 != null &&
                              widget.city.imageBase64!.isNotEmpty
                          ? Image.memory(
                            base64Decode(widget.city.imageBase64!),
                            fit: BoxFit.cover,
                          )
                          : CachedNetworkImage(
                            imageUrl: widget.city.imageUrl,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Container(
                                  color: Colors.grey[800],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  color: Colors.grey[800],
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                    color: Colors.white70,
                                  ),
                                ),
                          ),
                ),
                Container(
                  height: 180 + MediaQuery.of(context).padding.top,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.0),
                        Colors.black.withOpacity(0.5),
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: secondaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.monetization_on,
                                color: Color(0xFF065d67),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Fidelity Points',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(DateTime.now()),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: secondaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$fidelityPoints,00',
                            style: TextStyle(
                              color: secondaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.only(top: 16, bottom: 0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: SizedBox(
                height: 90, // Fixed height for the category section
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate width to show exactly 5 items
                    final itemWidth = constraints.maxWidth / 5;

                    return ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        SizedBox(width: 16), // Left padding
                        SizedBox(
                          width: itemWidth - 20, // Width for exactly one item
                          child: _buildModernCategoryButton(
                            'Tendance',
                            Icons.trending_up,
                            primaryColor,
                          ),
                        ),
                        SizedBox(width: 20), // Space between buttons
                        SizedBox(
                          width: itemWidth - 20,
                          child: _buildModernCategoryButton(
                            'Location',
                            Icons.home,
                            primaryColor,
                          ),
                        ),
                        SizedBox(width: 20),
                        SizedBox(
                          width: itemWidth - 20,
                          child: _buildModernCategoryButton(
                            'Restau & café',
                            Icons.restaurant_menu,
                            primaryColor,
                          ),
                        ),
                          SizedBox(width: 20),
                         _buildModernCategoryButton(
                          'Transportation',
                             Icons.directions_bus,
                              primaryColor,
                        ),
                        SizedBox(width: 20),
                        SizedBox(
                          width: itemWidth - 20,
                          child: _buildModernCategoryButton(
                            'Guides',
                            Icons.tour,
                            primaryColor,
                          ),
                        ),
                        SizedBox(width: 20),
                        SizedBox(
                          width: itemWidth - 20,
                          child: _buildModernCategoryButton(
                            'Stadium',
                            Icons.stadium,
                            primaryColor,
                          ),
                        ),
                        SizedBox(width: 20),
                        SizedBox(
                          width: itemWidth - 20,
                          child: _buildModernCategoryButton(
                            'Monuments',
                            Icons.account_balance,
                            primaryColor,
                          ),
                        ),
                        SizedBox(width: 20),
                        SizedBox(
                          width: itemWidth - 20,
                          child: _buildModernCategoryButton(
                            'Malls',
                            Icons.storefront,
                            primaryColor,
                          ),
                        ),
                        SizedBox(width: 20),
                        SizedBox(
                          width: itemWidth - 20,
                          child: _buildModernCategoryButton(
                            'Hawta',
                            Icons.place,
                            primaryColor,
                          ),
                        ),
                        SizedBox(width: 16), // Right padding
                      ],
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child:
                  isLoading
                      ? Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      )
                      : Container(
                        color: Colors.white,
                        child: SingleChildScrollView(
                          padding:
                              selectedCategory == 'Tendance'
                                  ? const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ) // Only horizontal padding for Tendance
                                  : const EdgeInsets.symmetric(
                                    // Existing padding for other categories
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 4.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _getCategoryIcon(selectedCategory),
                                          color: secondaryColor,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          selectedCategory,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: secondaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        selectedCategory == 'Tendance'
                                            ? '${_shorts.length} items'
                                            : selectedCategory ==
                                                'Restau & café'
                                            ? '${_filteredRestaurants.length} items'
                                            : selectedCategory == 'Guides'
                                            ? '${_filteredGuides.length} items'
                                            : selectedCategory == 'Stadium'
                                            ? '${_filteredStadiums.length} items'
                                            : selectedCategory == 'Monuments'
                                            ? '${_filteredMonuments.length} items'
                                            : selectedCategory == 'Malls'
                                            ? '${_filteredMalls.length} items'
                                            : '0 items',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),

                              const SizedBox(height: 8),
                              _buildCategoryContent(),
                            ],
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCategoryButton(
    String category,
    IconData icon,
    Color color,
  ) {
    final isSelected = selectedCategory == category;

    return InkWell(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });

        if (category == 'Restau & café') {
          _loadRestaurants();
        } else if (category == 'Guides') {
          _loadGuides();
        } else if (category == 'Stadium') {
          _loadStadiums();
        } else if (category == 'Monuments') {
          _loadMonuments();
        } else if (category == 'Malls') {
          // Add this condition
          _loadMalls();
          } else if (category == 'Transportation') {
        _loadTransportation();
        
        } else if (category == 'Tendance') {
          _loadShorts();
        } else if (category == 'Location') {
          _loadLocations();
        } else {
          _animationController.reset();
          _animationController.forward();
        }
      },
      child: SizedBox(
        height: 80, // Fixed height to prevent overflow
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(10), // Reduced padding
              decoration: BoxDecoration(
                color: isSelected ? secondaryColor : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                        : null,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : secondaryColor,
                size: 20, // Reduced size
              ),
            ),
            const SizedBox(height: 4), // Reduced spacing

            Text(
              category,
              style: TextStyle(
                fontSize: 11, // Smaller font
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? secondaryColor : Colors.black87,
              ),
              maxLines: 1, // Ensure single line
              overflow: TextOverflow.ellipsis, // Handle long text
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(top: 2), // Reduced margin
              width: isSelected ? 6 : 0, // Smaller indicator
              height: 6, // Smaller indicator
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernPlaceholderItems() {
    return Column(
      children: List.generate(
        4,
        (index) => AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.5, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    index * 0.2,
                    0.6 + index * 0.1,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      index * 0.2,
                      0.6 + index * 0.1,
                      curve: Curves.easeOut,
                    ),
                  ),
                ),
                child: child,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Icon(
                      _getCategoryIcon(selectedCategory),
                      size: 40,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${selectedCategory} Place ${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star, size: 16, color: primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  '${4.0 + index * 0.2}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '2.${index + 1} km from center',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(index + 1) * 100 + 300} DH',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: secondaryColor,
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
        ),
      ),
    );
  }

  Widget _buildCategoryContent() {
    if (selectedCategory == 'Tendance') {
      return Container(
        // No top padding or margin at all
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // THIS is where you need to add negative transform to pull content upward
            Transform.translate(
              offset: const Offset(0, -75), // Try -20 to remove the gap
              child: _buildShortsGrid(),
            ),
            // See all shorts button
            if (_shorts.length > 8)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ShortPlayerScreen(
                                initialIndex: 0, // This is correct
                                shorts: _shorts, // This is correct
                                // No other parameters needed
                              ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.video_library),
                    label: Text('See All ${_shorts.length} Shorts'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: secondaryColor,
                      side: BorderSide(color: secondaryColor),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Divider(color: Colors.grey[300]),
            ),

            // Popular categories section
            _buildPopularCategories(),

           
          ],
        ),
      );
    }
    if (selectedCategory == 'Location') {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _locationTypes.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final type = _locationTypes[index];
              final isSelected = _selectedLocationType == type;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedLocationType = type;
                    _filterLocationsByType();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? secondaryColor : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? secondaryColor : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getLocationTypeIcon(type),
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        type,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      const SizedBox(height: 16),
      Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 1,
        color: Colors.grey[200],
      ),
      _filteredLocations.isEmpty && !isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _selectedLocationType == 'All'
                        ? 'No accommodations found in ${widget.city.name}'
                        : 'No $_selectedLocationType accommodations found',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
            )
          : Column(
              children: _filteredLocations.map((location) => _buildLocationItem(location)).toList(),
            ),
    ],
  );
}
    if (selectedCategory == 'Restau & café') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _restaurantTypes.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final type = _restaurantTypes[index];
                  final isSelected = _selectedRestaurantType == type;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedRestaurantType = type;
                        _filterRestaurantsByType();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? secondaryColor : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isSelected ? secondaryColor : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getRestaurantTypeIcon(type),
                            size: 16,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            type,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color:
                                  isSelected ? Colors.white : Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 1,
            color: Colors.grey[200],
          ),
          _filteredRestaurants.isEmpty && !isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedRestaurantType == 'All'
                          ? 'No restaurants found in ${widget.city.name}'
                          : 'No $_selectedRestaurantType establishments found',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                
                  ],
                ),
              )
              : Column(
                children:
                    _filteredRestaurants
                        .map((restaurant) => _buildRestaurantItem(restaurant))
                        .toList(),
              ),
        ],
      );
       } else if (selectedCategory == 'Transportation') {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _transportTypes.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final type = _transportTypes[index];
              final isSelected = _selectedTransportType == type;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedTransportType = type;
                    _filterTransportByType();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? secondaryColor : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? secondaryColor : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTransportTypeIcon(type),
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        type,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      const SizedBox(height: 16),
      Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 1,
        color: Colors.grey[200],
      ),
      _filteredTransportRoutes.isEmpty && !isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_bus, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _selectedTransportType == 'All'
                        ? 'No transportation options found in ${widget.city.name}'
                        : 'No $_selectedTransportType options found',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                 
                ],
              ),
            )
          : Column(
              children: _filteredTransportRoutes.map((route) => _buildTransportationItem(route)).toList(),
            ),
    ],
  );
}else if (selectedCategory == 'Guides') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _guideSpecializations.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final specialization = _guideSpecializations[index];
                  final isSelected =
                      _selectedGuideSpecialization == specialization;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedGuideSpecialization = specialization;
                        _filterGuidesBySpecialization();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? secondaryColor : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isSelected ? secondaryColor : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getGuideSpecializationIcon(specialization),
                            size: 16,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            specialization,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color:
                                  isSelected ? Colors.white : Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 1,
            color: Colors.grey[200],
          ),
          _filteredGuides.isEmpty && !isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.tour, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      _selectedGuideSpecialization == 'All'
                          ? 'No guides found in ${widget.city.name}'
                          : 'No $_selectedGuideSpecialization guides found',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    
                  ],
                ),
              )
              : Column(
                children:
                    _filteredGuides
                        .map((guide) => _buildGuideItem(guide))
                        .toList(),
              ),
        ],
      );
    } else if (selectedCategory == 'Stadium') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _stadiumTypes.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final type = _stadiumTypes[index];
                  final isSelected = _selectedStadiumType == type;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedStadiumType = type;
                        _filterStadiumsByType();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? secondaryColor : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isSelected ? secondaryColor : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStadiumTypeIcon(type),
                            size: 16,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            type,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color:
                                  isSelected ? Colors.white : Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 1,
            color: Colors.grey[200],
          ),
          _filteredStadiums.isEmpty && !isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.stadium, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      _selectedStadiumType == 'All'
                          ? 'No stadiums found in ${widget.city.name}'
                          : 'No $_selectedStadiumType stadiums found',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                   
                  ],
                ),
              )
              : Column(
                children:
                    _filteredStadiums.asMap().entries.map((entry) {
                      final index = entry.key;
                      final stadium = entry.value;
                      return AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.5, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: _animationController,
                                curve: Interval(
                                  (index / _filteredStadiums.length).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                  1.0,
                                  curve: Curves.easeOut,
                                ),
                              ),
                            ),
                            child: _buildStadiumItem(stadium),
                          );
                        },
                      );
                    }).toList(),
              ),
        ],
      );
    } else if (selectedCategory == 'Monuments') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _monumentTypes.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final type = _monumentTypes[index];
                  final isSelected = _selectedMonumentType == type;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedMonumentType = type;
                        _filterMonumentsByType();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? secondaryColor : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isSelected ? secondaryColor : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getMonumentTypeIcon(type),
                            size: 16,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            type,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color:
                                  isSelected ? Colors.white : Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 1,
            color: Colors.grey[200],
          ),
          _filteredMonuments.isEmpty && !isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedMonumentType == 'All'
                          ? 'No monuments found in ${widget.city.name}'
                          : 'No $_selectedMonumentType monuments found',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                   
                  ],
                ),
              )
              : Column(
                children:
                    _filteredMonuments
                        .map((monument) => _buildMonumentItem(monument))
                        .toList(),
              ),
        ],
      );
    } else if (selectedCategory == 'Malls') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _mallCategories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = _mallCategories[index];
                  final isSelected = _selectedMallCategory == category;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedMallCategory = category;
                        _filterMallsByCategory();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? secondaryColor : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isSelected ? secondaryColor : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getMallCategoryIcon(category),
                            size: 16,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            category,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color:
                                  isSelected ? Colors.white : Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 1,
            color: Colors.grey[200],
          ),
          _filteredMalls.isEmpty && !isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.storefront, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      _selectedMallCategory == 'All'
                          ? 'No malls found in ${widget.city.name}'
                          : 'No $_selectedMallCategory malls found',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    
                  ],
                ),
              )
              : Column(
                children:
                    _filteredMalls.map((mall) => _buildMallItem(mall)).toList(),
              ),
        ],
      );
    } else {
      return _buildModernPlaceholderItems();
    }
  }

  Widget _buildRestaurantItem(Restaurant restaurant) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => RestaurantDetailScreen(restaurant: restaurant),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.5, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(0.2, 0.8, curve: Curves.easeOutCubic),
              ),
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(0.2, 0.8, curve: Curves.easeOut),
                ),
              ),
              child: child,
            ),
          );
        },
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child:
                            restaurant.imageUrls.isNotEmpty
                                ? SizedBox(
                                  height: 120,
                                  child: PageView.builder(
                                    itemCount: restaurant.imageUrls.length,
                                    itemBuilder: (context, index) {
                                      return _buildRestaurantImageItem(
                                        restaurant.imageUrls[index],
                                      );
                                    },
                                  ),
                                )
                                : Container(
                                  height: 120,
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.restaurant_menu,
                                        size: 36,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "No images available",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: InkWell(
                          onTap: () async {
                            final latitude = restaurant.location.latitude;
                            final longitude = restaurant.location.longitude;

                            final url = Uri.parse(
                              'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
                            );

                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.directions,
                              size: 18,
                              color: secondaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                restaurant.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: primaryColor,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${restaurant.rating}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          restaurant.cuisine,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                restaurant.address,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: Icon(
                                Icons.menu_book,
                                color: secondaryColor,
                                size: 18,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => MenuDetailScreen(
                                          restaurant: restaurant,
                                        ),
                                  ),
                                );
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              iconSize: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                height: 1,
                color: Colors.grey[200],
                margin: const EdgeInsets.symmetric(horizontal: 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantImageItem(String imageSource) {
    if (imageSource.startsWith('data:image')) {
      String base64String = imageSource.split(',')[1];
      try {
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildImageErrorPlaceholder();
          },
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return _buildImageErrorPlaceholder();
      }
    } else if (RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(imageSource)) {
      try {
        return Image.memory(
          base64Decode(imageSource),
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildImageErrorPlaceholder();
          },
        );
      } catch (e) {
        print('Error decoding raw base64 image: $e');
        return _buildImageErrorPlaceholder();
      }
    } else {
      return CachedNetworkImage(
        imageUrl: imageSource,
        fit: BoxFit.cover,
        width: double.infinity,
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 4),
            Text(
              "Image unavailable",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem(Guide guide) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GuideDetailScreen(guide: guide),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.5, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(0.2, 0.8, curve: Curves.easeOutCubic),
              ),
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(0.2, 0.8, curve: Curves.easeOut),
                ),
              ),
              child: child,
            ),
          );
        },
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 120,
                              width: double.infinity,
                              child:
                                  guide.imageUrls.isNotEmpty
                                      ? PageView.builder(
                                        itemCount: guide.imageUrls.length,
                                        itemBuilder: (context, index) {
                                          return _buildGuideImageItem(
                                            guide.imageUrls[index],
                                          );
                                        },
                                      )
                                      : Container(
                                        color: Colors.grey[200],
                                        child: Icon(
                                          Icons.image,
                                          size: 40,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              color: secondaryColor.withOpacity(0.8),
                              child: Text(
                                guide.fullName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child:
                                guide.profileImageUrl.isNotEmpty
                                    ? _buildGuideImageItem(
                                      guide.profileImageUrl,
                                    )
                                    : guide.imageUrls.isNotEmpty
                                    ? _buildGuideImageItem(
                                      guide.imageUrls.first,
                                    )
                                    : Container(
                                      color: Colors.grey[300],
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: InkWell(
                          onTap: () async {
                            final url = Uri.parse('tel:${guide.phoneNumber}');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
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
                              Icons.call,
                              size: 18,
                              color: secondaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                guide.specialization,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    guide.rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.school,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                guide.educationLevel,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "${guide.hourlyRate.toStringAsFixed(0)} MAD/hr",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: secondaryColor,
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                height: 1,
                color: Colors.grey[200],
                margin: const EdgeInsets.symmetric(horizontal: 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideImageItem(String imageSource) {
    if (imageSource.startsWith('data:image')) {
      String base64String = imageSource.split(',')[1];
      try {
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildImageErrorPlaceholder();
          },
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return _buildImageErrorPlaceholder();
      }
    } else if (RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(imageSource)) {
      try {
        return Image.memory(
          base64Decode(imageSource),
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildImageErrorPlaceholder();
          },
        );
      } catch (e) {
        print('Error decoding raw base64 image: $e');
        return _buildImageErrorPlaceholder();
      }
    } else {
      return CachedNetworkImage(
        imageUrl: imageSource,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder:
            (context, url) =>
                Center(child: CircularProgressIndicator(color: primaryColor)),
        errorWidget: (context, url, error) => _buildImageErrorPlaceholder(),
      );
    }
  }

  Widget _buildLikedMonumentsView(ScrollController scrollController) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _likedMonuments.length,
      itemBuilder: (context, index) {
        final monument = _likedMonuments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  monument.imageUrls.isNotEmpty
                      ? SizedBox(
                        width: 56,
                        height: 56,
                        child: _buildMonumentImageItem(
                          monument.imageUrls.first,
                        ),
                      )
                      : Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.account_balance,
                          color: Colors.grey[400],
                        ),
                      ),
            ),
            title: Text(
              monument.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(monument.type, overflow: TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  monument.rating.toStringAsFixed(1),
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.star, size: 16, color: primaryColor),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () async {
                    await _toggleLikeItem(
                      monument.id,
                      'monuments',
                      monument.name,
                    );
                    Navigator.pop(context);
                    _showLikedItemsBottomSheet();
                  },
                  iconSize: 22,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => MonumentDetailScreen(monument: monument),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMallImageItem(String imageSource) {
    if (imageSource.startsWith('data:image')) {
      try {
        String base64String = imageSource.split(',')[1];
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            print('Error rendering base64 mall image: $error');
            return _buildImageErrorPlaceholder();
          },
        );
      } catch (e) {
        print('Error decoding base64 mall image: $e');
        return _buildImageErrorPlaceholder();
      }
    } else if (RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(imageSource)) {
      try {
        return Image.memory(
          base64Decode(imageSource),
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildImageErrorPlaceholder();
          },
        );
      } catch (e) {
        print('Error decoding raw base64 mall image: $e');
        return _buildImageErrorPlaceholder();
      }
    } else {
      // For regular URLs
      return CachedNetworkImage(
        imageUrl: imageSource,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder:
            (context, url) =>
                Center(child: CircularProgressIndicator(color: primaryColor)),
        errorWidget: (context, url, error) => _buildImageErrorPlaceholder(),
      );
    }
  }

  Widget _buildMallItem(Mall mall) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MallDetailScreen(mall: mall)),
        );
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.5, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(0.2, 0.8, curve: Curves.easeOutCubic),
              ),
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(0.2, 0.8, curve: Curves.easeOut),
                ),
              ),
              child: child,
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child:
                        mall.imageUrls.isNotEmpty
                            ? SizedBox(
                              height: 120,
                              child: PageView.builder(
                                itemCount: mall.imageUrls.length,
                                itemBuilder: (context, index) {
                                  return _buildMallImageItem(
                                    mall.imageUrls[index],
                                  );
                                },
                              ),
                            )
                            : Container(
                              height: 120,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.storefront,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                            ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      onTap: () async {
                        final latitude = mall.location.latitude;
                        final longitude = mall.location.longitude;

                        final url = Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
                        );

                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.directions,
                          size: 18,
                          color: secondaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            mall.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star, size: 14, color: primaryColor),
                              const SizedBox(width: 2),
                              Text(
                                mall.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mall.type,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            mall.address,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${mall.stores.length} stores',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: secondaryColor,
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
      ),
    );
  }

  Widget _buildLikedMallsView(ScrollController scrollController) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _likedMalls.length,
      itemBuilder: (context, index) {
        final mall = _likedMalls[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  mall.imageUrls.isNotEmpty
                      ? SizedBox(
                        width: 56,
                        height: 56,
                        child: _buildMallImageItem(mall.imageUrls.first),
                      )
                      : Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey[200],
                        child: Icon(Icons.storefront, color: Colors.grey[400]),
                      ),
            ),
            title: Text(
              mall.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(mall.type, overflow: TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mall.rating.toStringAsFixed(1),
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.star, size: 16, color: primaryColor),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () async {
                    await _toggleLikeItem(mall.id, 'malls', mall.name);
                    Navigator.pop(context);
                    _showLikedItemsBottomSheet();
                  },
                  iconSize: 22,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MallDetailScreen(mall: mall),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStadiumItem(Stadium stadium) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StadiumDetailScreen(stadium: stadium),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.5, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(0.2, 0.8, curve: Curves.easeOutCubic),
              ),
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(0.2, 0.8, curve: Curves.easeOut),
                ),
              ),
              child: child,
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child:
                        stadium.imageUrls.isNotEmpty
                            ? SizedBox(
                              height: 120,
                              child: PageView.builder(
                                itemCount: stadium.imageUrls.length,
                                itemBuilder: (context, index) {
                                  return _buildStadiumImageItem(
                                    stadium.imageUrls[index],
                                  );
                                },
                              ),
                            )
                            : Container(
                              height: 120,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.stadium,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                            ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      onTap: () async {
                        final latitude = stadium.location.latitude;
                        final longitude = stadium.location.longitude;

                        final url = Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
                        );

                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.directions,
                          size: 18,
                          color: secondaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            stadium.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star, size: 14, color: primaryColor),
                              const SizedBox(width: 2),
                              Text(
                                stadium.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stadium.address,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${stadium.capacity} seats',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          stadium.type,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: secondaryColor,
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
      ),
    );
  }
IconData _getLocationTypeIcon(String type) {
  switch (type) {
    case 'Hotel':
      return Icons.hotel;
    case 'Apartment':
      return Icons.apartment;
    case 'Hostel':
      return Icons.house;
    case 'Villa':
      return Icons.villa;
    case 'Riad':
      return Icons.holiday_village;
    default:
      return Icons.home;
  }
}
  IconData _getStadiumTypeIcon(String type) {
    switch (type) {
      case 'Soccer':
        return Icons.sports_soccer;
      case 'Basketball':
        return Icons.sports_basketball;
      case 'Tennis':
        return Icons.sports_tennis;
      case 'Olympic':
        return Icons.emoji_events;
      case 'Multi-sport':
        return Icons.sports;
      default:
        return Icons.stadium;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Tendance':
        return Icons.trending_up;
      case 'Location':
        return Icons.home;
      case 'Restau & café':
        return Icons.restaurant_menu;
      case 'Guides':
        return Icons.tour;
      case 'Hawta':
        return Icons.place;
      case 'Stadium':
        return Icons.stadium;
      case 'Monuments':
        return Icons.account_balance;
      case 'Malls':
        return Icons.storefront;
      default:
        return Icons.category;
    }
  }

  IconData _getRestaurantTypeIcon(String type) {
    switch (type) {
      case 'Restaurant':
        return Icons.restaurant;
      case 'Café':
        return Icons.coffee;
      case 'Fast Food':
        return Icons.fastfood;
      case 'Bakery':
        return Icons.bakery_dining;
      case 'Bar':
        return Icons.local_bar;
      default:
        return Icons.food_bank;
    }
  }

  IconData _getMonumentTypeIcon(String type) {
    switch (type) {
      case 'Historical':
        return Icons.history_edu;
      case 'Religious':
        return Icons.church;
      case 'Cultural':
        return Icons.theater_comedy;
      case 'Museum':
        return Icons.museum;
      case 'Natural':
        return Icons.landscape;
      case 'Archaeological':
        return Icons.architecture;
      case 'Modern':
        return Icons.domain;
      default:
        return Icons.account_balance;
    }
  }

  IconData _getGuideSpecializationIcon(String specialization) {
    switch (specialization) {
      case 'Historical Sites':
        return Icons.history_edu;
      case 'Cultural Tours':
        return Icons.theater_comedy;
      case 'Adventure Tourism':
        return Icons.terrain;
      case 'Culinary Experiences':
        return Icons.restaurant;
      case 'Art & Museums':
        return Icons.museum;
      case 'Nature & Wildlife':
        return Icons.park;
      case 'Religious Sites':
        return Icons.church;
      default:
        return Icons.tour;
    }
  }

  IconData _getMallCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'shopping mall':
        return Icons.shopping_bag;
      case 'outlet mall':
        return Icons.store;
      case 'strip mall':
        return Icons.storefront;
      case 'lifestyle center':
        return Icons.living;
      case 'open-air mall':
        return Icons.terrain;
      default:
        return Icons.shopping_cart;
    }
  }

  Color _getCategoryColor(String category) {
    return secondaryColor;
  }
  Widget _buildShortsSidebarSection() {
 return Container(
    color: Colors.white, // Add white background
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.play_circle_filled, size: 18, color: secondaryColor),
                const SizedBox(width: 8),
                Text(
                  'SHORTS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: secondaryColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UploadShortScreen(city: widget.city),
                  ),
                ).then((_) => _loadShorts());
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.add, color: Colors.white, size: 14),
                    SizedBox(width: 2),
                    Text(
                      'Add',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Horizontal scrollable shorts thumbnails
      Container(
        height: 100,
        padding: const EdgeInsets.only(left: 16),
        child: _isShortsLoading
            ? Center(child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2))
            : _shorts.isEmpty
                ? Center(
                    child: Text(
                      'No shorts available',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _shorts.length,
                    itemBuilder: (context, index) {
                      final short = _shorts[index];
                      return GestureDetector(
                     onTap: () {
  Navigator.pop(context); // Close drawer
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ShortPlayerScreen(
        initialIndex: index,
        shorts: _shorts,
      ),
    ),
  ).then((_) {
    // Always reload from server when returning
    if (mounted) {
      _loadShorts();
    }
  });
},
                        child: Container(
                          width: 70,
                          margin: const EdgeInsets.only(right: 8, bottom: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Thumbnail - Using imageBase64 instead of thumbnailUrl
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: short.imageBase64.isNotEmpty
                                    ? Image.memory(
                                        base64Decode(short.imageBase64),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.error),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.grey[300],
                                        child: Icon(
                                          Icons.play_circle_outline,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                              ),
                              
                             
                              
                              // Like count at bottom
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${short.likedBy.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      Divider(color: Colors.grey[300]),
    ],
      ),
  );
}

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Header with wider image and reduced height
          Container(
            height: 140 + MediaQuery.of(context).padding.top,
            width: double.infinity, // Explicitly set to full width
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 8,
            ),
            decoration: BoxDecoration(
              color: secondaryColor,
              image:
                  widget.city.imageBase64 != null &&
                          widget.city.imageBase64!.isNotEmpty
                      ? DecorationImage(
                        image: MemoryImage(
                          base64Decode(widget.city.imageBase64!),
                        ),
                        fit:
                            BoxFit
                                .cover, // Ensures image covers the entire area
                        colorFilter: ColorFilter.mode(
                          secondaryColor.withOpacity(0.8),
                          BlendMode.darken,
                        ),
                      )
                      : DecorationImage(
                        image: NetworkImage(widget.city.imageUrl),
                        fit:
                            BoxFit
                                .cover, // Ensures image covers the entire area
                        colorFilter: ColorFilter.mode(
                          secondaryColor.withOpacity(0.8),
                          BlendMode.darken,
                        ),
                      ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add padding at the top for status bar
                SizedBox(
                  height: MediaQuery.of(context).padding.top - 8,
                ), // Reduced padding

                Text(
                  widget.city.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2), // Reduced spacing
                Text(
                  'Explore ${widget.city.name}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Spacer(),

                // Fidelity points section
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 10,
                  ), // Reduced padding
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.monetization_on,

                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Fidelity Points',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            '$fidelityPoints pts',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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

          Container(
            color: Colors.grey[100],
           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // REDUCED padding
          height: 50,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Categories in ${widget.city.name}...',
                prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey[600]),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                 isDense: true,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: primaryColor),
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                           icon: const Icon(Icons.clear, size: 16), // SMALLER icon
                        padding: EdgeInsets.zero, // Remove padding
                        constraints: const BoxConstraints(),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                        : null,
              ),
               style: const TextStyle(fontSize: 13),
            ),
          ),

               _buildShortsSidebarSection(),
          Container(
  color: Colors.white, // Add white background
  child: ListTile(
            
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.favorite, color: Colors.red, size: 16),
            ),
            title: const Text(
              'Liked Items',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'View all your favorites',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
               '${_likedRestaurants.length + _likedGuides.length + _likedStadiums.length + _likedMonuments.length + _likedMalls.length + _likedShorts.length}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
              _showLikedItemsBottomSheet();
            },
          ),
),

          Container(
  color: Colors.white, // Add white background to the divider section
  child: Divider(color: Colors.grey[300]),
),

          // Category header
         Container(
  color: Colors.white, // Add white background
  child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Icon(Icons.category, size: 18, color: secondaryColor),

                const SizedBox(width: 8),

                Text(
                  'CATEGORIES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: secondaryColor,
                    letterSpacing: 1.2,
                  ),
                ),
                const Expanded(child: SizedBox()),
                Icon(Icons.filter_list, size: 18, color: Colors.grey[600]),
              ],
            ),
          ),
),
          // Divider for visual separation
        Container(
  color: Colors.white, // Add white background to the divider section
  child: Divider(color: Colors.grey[300]),
),

          // Categories list with improved display
          Expanded(
            child: Container(
    color: Colors.white, // Add white background to the entire list
    child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (_categoryMatchesSearch('All Categories'))
                  _buildDrawerCategory(
                    'All Categories',
                    Icons.category,
                    selectedCategory == 'Tendance',
                  ),

                if (_categoryMatchesSearch('Tendance'))
                  _buildDrawerCategory(
                    'Tendance',
                    Icons.trending_up,
                    selectedCategory == 'Tendance',
                  ),

                if (_categoryMatchesSearch('Location'))
                  _buildDrawerCategory(
                    'Location',
                    Icons.home,
                    selectedCategory == 'Location',
                  ),

                // Grouped food-related categories
                if (_categoryMatchesSearch('Restau & café') ||
                    _restaurantTypes.any(
                      (type) => type.toLowerCase().contains(_searchQuery),
                    ))
                  Container(
                    color: Colors.grey[50],
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: _buildDrawerCategoryWithFilters(
                      'Restau & café',
                      Icons.restaurant_menu,
                      selectedCategory == 'Restau & café',
                      _restaurantTypes
                          .where(
                            (type) =>
                                _searchQuery.isEmpty
                                    ? true
                                    : type.toLowerCase().contains(_searchQuery),
                          )
                          .toList(),
                      _selectedRestaurantType,
                      (value) {
                        setState(() {
                          _selectedRestaurantType = value;
                          _filterRestaurantsByType();
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
if (_categoryMatchesSearch('Transportation') ||
    _transportTypes.any(
      (type) => type.toLowerCase().contains(_searchQuery),
    ))
  Container(
    color: Colors.grey[50],
    margin: const EdgeInsets.symmetric(vertical: 4),
    child: _buildDrawerCategoryWithFilters(
      'Transportation',
      Icons.directions_bus,
      selectedCategory == 'Transportation',
      _transportTypes
          .where(
            (type) =>
                _searchQuery.isEmpty
                    ? true
                    : type.toLowerCase().contains(_searchQuery),
          )
          .toList(),
      _selectedTransportType,
      (value) {
        setState(() {
          _selectedTransportType = value;
          _filterTransportByType();
        });
        Navigator.pop(context);
      },
    ),
  ),
                // Grouped tourism-related categories
                if (_categoryMatchesSearch('Guides') ||
                    _guideSpecializations.any(
                      (spec) => spec.toLowerCase().contains(_searchQuery),
                    ))
                  Container(
                    color: Colors.grey[50],
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: _buildDrawerCategoryWithFilters(
                      'Guides',
                      Icons.tour,
                      selectedCategory == 'Guides',
                      _guideSpecializations
                          .where(
                            (spec) =>
                                _searchQuery.isEmpty
                                    ? true
                                    : spec.toLowerCase().contains(_searchQuery),
                          )
                          .toList(),
                      _selectedGuideSpecialization,
                      (value) {
                        setState(() {
                          _selectedGuideSpecialization = value;
                          _filterGuidesBySpecialization();
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),

                if (_categoryMatchesSearch('Hawta'))
                  _buildDrawerCategory(
                    'Hawta',
                    Icons.place,
                    selectedCategory == 'Hawta',
                  ),

                if (_categoryMatchesSearch('Stadium') ||
                    _stadiumTypes.any(
                      (type) => type.toLowerCase().contains(_searchQuery),
                    ))
                  Container(
                    color: Colors.grey[50],
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: _buildDrawerCategoryWithFilters(
                      'Stadium',
                      Icons.stadium,
                      selectedCategory == 'Stadium',
                      _stadiumTypes
                          .where(
                            (type) =>
                                _searchQuery.isEmpty
                                    ? true
                                    : type.toLowerCase().contains(_searchQuery),
                          )
                          .toList(),
                      _selectedStadiumType,
                      (value) {
                        setState(() {
                          _selectedStadiumType = value;
                          _filterStadiumsByType();
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),

                if (_categoryMatchesSearch('Monuments'))
                  _buildDrawerCategory(
                    'Monuments',
                    Icons.account_balance,
                    selectedCategory == 'Monuments',
                  ),

                if (_categoryMatchesSearch('Malls'))
                  _buildDrawerCategory(
                    'Malls',
                    Icons.storefront,
                    selectedCategory == 'Malls',
                  ),

                // Empty state when no results
                if (_searchQuery.isNotEmpty &&
                    !_categoryMatchesSearch('All Categories') &&
                    !_categoryMatchesSearch('Tendance') &&
                    !_categoryMatchesSearch('Location') &&
                    !_categoryMatchesSearch('Restau & café') &&
                    !_categoryMatchesSearch('Guides') &&
                    !_categoryMatchesSearch('Hawta') &&
                    !_categoryMatchesSearch('Stadium') &&
                    !_categoryMatchesSearch('Monuments') &&
                    !_categoryMatchesSearch('Malls') &&
                    !_restaurantTypes.any(
                      (type) => type.toLowerCase().contains(_searchQuery),
                    ) &&
                    !_guideSpecializations.any(
                      (spec) => spec.toLowerCase().contains(_searchQuery),
                    ))
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No categories found for "${_searchController.text}"',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // Add "Liked Items" button
                const SizedBox(height: 16),
                // Always show the "Open in maps" button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: _openCityInMaps,
                    icon: const Icon(Icons.map, size: 18),
                    label: Text('Open ${widget.city.name} in Maps'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
           ), 
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerCategory(String title, IconData icon, bool isSelected) {
    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.2) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected ? primaryColor : Colors.grey[700],
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 15,
        ),
      ),
      trailing:
          isSelected
              ? Icon(Icons.check_circle, color: primaryColor, size: 16)
              : null,
      selected: isSelected,
      selectedTileColor: primaryColor.withOpacity(0.1),
      onTap: () {
        setState(() {
          selectedCategory = title == 'All Categories' ? 'Tendance' : title;
        });
        Navigator.pop(context);

        if (title == 'Restau & café') {
          _loadRestaurants();
        } else if (title == 'Guides') {
          _loadGuides();
        } else if (title == 'Stadium') {
          _loadStadiums();
        } else if (title == 'Monuments') {
          _loadMonuments();
        } else if (title == 'Malls') {
          
          _loadMalls();
          } else if (title == 'Location') { 
       _loadLocations();
  
        }else if (title == 'Transportation') {
    _loadTransportation();
  } else {
          _animationController.reset();
          _animationController.forward();
        }
      },
    );
  }

  Widget _buildDrawerCategoryWithFilters(
    String title,
    IconData icon,
    bool isSelected,
    List<String> filters,
    String selectedFilter,
    Function(String) onFilterSelected,
  ) {
    return ExpansionTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.2) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected ? primaryColor : Colors.grey[700],
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 15,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              selectedFilter,
              style: TextStyle(
                fontSize: 10,
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            isSelected ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: Colors.grey[600],
            size: 18,
          ),
        ],
      ),
      initiallyExpanded: isSelected,
      childrenPadding: const EdgeInsets.only(left: 24.0),
      children: [
        ...filters.map((filter) {
          final isFilterSelected = selectedFilter == filter;
          return ListTile(
            dense: true,
            visualDensity: const VisualDensity(horizontal: -4, vertical: -2),
            leading: Icon(
              isFilterSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              size: 18,
              color: isFilterSelected ? primaryColor : Colors.grey[600],
            ),
            title: Text(
              filter,
              style: TextStyle(
                fontSize: 13,
                color: isFilterSelected ? primaryColor : Colors.black87,
                fontWeight:
                    isFilterSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            onTap: () {
              setState(() {
                selectedCategory = title;
              });
              onFilterSelected(filter);
            },
          );
        }).toList(),
      ],
    );
  }
}
