import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_application_1/mall/mall_model.dart';
import 'package:flutter_application_1/mall/mall_service.dart';
import 'package:flutter_application_1/mall/store_detail_screen.dart';

class MallDetailScreen extends StatefulWidget {
  final Mall mall;

  const MallDetailScreen({Key? key, required this.mall}) : super(key: key);

  @override
  State<MallDetailScreen> createState() => _MallDetailScreenState();
}

class _MallDetailScreenState extends State<MallDetailScreen> {
  final PageController _pageController = PageController();
  final Color primaryColor = const Color(0xFFFDCB00);
  final Color secondaryColor = const Color(0xFF065d67);
  final Color backgroundColor = const Color(0xFFF9F9F9);
  final Color cardColor = Colors.white;
  final Color textPrimaryColor = const Color(0xFF212121);
  final Color textSecondaryColor = const Color(0xFF757575);
  bool _isFavorite = false;
  final MallService _mallService = MallService();
  int _currentImageIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _mapKey = GlobalKey();

  // Add this field at the top of the class
  List<Map<String, dynamic>> _storeData = [];
  bool _loadingStores = true;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _loadStoresFromFirestore(); // Add this line
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _checkFavoriteStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && widget.mall != null) {
      setState(() {
        _isFavorite = widget.mall.favoritedBy.contains(user.uid);
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to favorite malls')),
      );
      return;
    }

    try {
      await _mallService.toggleFavorite(widget.mall.id, user.uid, _isFavorite);

      setState(() {
        _isFavorite = !_isFavorite;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite ? 'Added to favorites' : 'Removed from favorites',
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating favorite status'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openInMaps() async {
    try {
      final latitude = widget.mall.location.latitude;
      final longitude = widget.mall.location.longitude;

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

  Future<void> _shareMall() async {
    try {
      // Create share text
      final String shareText =
          "Check out ${widget.mall.name} on our app!\n\n"
          "${widget.mall.description}\n\n"
          "🏠 ${widget.mall.address}\n"
          "⭐ ${widget.mall.rating} stars\n"
          "🛍️ ${widget.mall.storeCount} stores\n";

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: shareText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mall details copied to clipboard!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Error sharing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not share mall information'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _scrollToMapSection() {
    final RenderObject? renderObject =
        _mapKey.currentContext?.findRenderObject();
    if (renderObject != null) {
      _scrollController.position.ensureVisible(
        renderObject,
        alignment: 0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _openInMaps();
    }
  }

  // Add this method to fetch stores from Firestore
  Future<void> _loadStoresFromFirestore() async {
    setState(() {
      _loadingStores = true;
    });

    try {
      // Query stores collection for stores with matching mallId
      final storesSnapshot =
          await FirebaseFirestore.instance
              .collection('stores')
              .where('mallId', isEqualTo: widget.mall.id)
              .get();

      // Convert to list of maps with all store data
      final stores =
          storesSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'] ?? 'Unnamed Store',
              'imageUrl': data['imageUrl'] ?? '',
              'category': data['category'] ?? 'General',
              'floor': data['floor'] ?? '1',
              // Add other fields you need
            };
          }).toList();

      setState(() {
        _storeData = stores;
        _loadingStores = false;
      });
    } catch (e) {
      print('Error loading stores: $e');
      setState(() {
        _loadingStores = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Main content
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Image carousel header
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                stretch: true,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image PageView
                      PageView.builder(
                        controller: _pageController,
                        itemCount:
                            widget.mall.imageUrls.isEmpty
                                ? 1
                                : widget.mall.imageUrls.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        physics: const BouncingScrollPhysics(),
                        pageSnapping: true,
                        itemBuilder: (context, index) {
                          if (widget.mall.imageUrls.isEmpty) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.storefront,
                                  size: 80,
                                  color: Colors.white70,
                                ),
                              ),
                            );
                          }
                          return _buildImageWidget(
                            widget.mall.imageUrls[index],
                          );
                        },
                      ),

                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                              Colors.black.withOpacity(0.5),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),

                      // Page indicators
                      if (widget.mall.imageUrls.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              widget.mall.imageUrls.length,
                              (index) => Container(
                                width: _currentImageIndex == index ? 12 : 8,
                                height: _currentImageIndex == index ? 12 : 8,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      _currentImageIndex == index
                                          ? primaryColor
                                          : Colors.white.withOpacity(0.7),
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Navigation arrows
                      if (widget.mall.imageUrls.length > 1)
                        Positioned.fill(
                          child: Row(
                            children: [
                              // Left arrow
                              Container(
                                width: 40,
                                alignment: Alignment.centerLeft,
                                child: GestureDetector(
                                  onTap: () {
                                    if (_currentImageIndex > 0) {
                                      _pageController.animateToPage(
                                        _currentImageIndex - 1,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                      );
                                    } else {
                                      // Loop to last image
                                      _pageController.animateToPage(
                                        widget.mall.imageUrls.length - 1,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_ios,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),

                              // Expanded middle area
                              Expanded(child: Container()),

                              // Right arrow
                              Container(
                                width: 40,
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () {
                                    if (_currentImageIndex <
                                        widget.mall.imageUrls.length - 1) {
                                      _pageController.animateToPage(
                                        _currentImageIndex + 1,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                      );
                                    } else {
                                      // Loop to first image
                                      _pageController.animateToPage(
                                        0,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // Modern back button with contrast
                leading: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    customBorder: const CircleBorder(),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                actions: [
                  // Share button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _shareMall,
                      customBorder: const CircleBorder(),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.share,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  // Favorite button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _toggleFavorite,
                      customBorder: const CircleBorder(),
                      child: Container(
                        margin: const EdgeInsets.only(
                          right: 16,
                          top: 8,
                          bottom: 8,
                        ),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.red : Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Main content
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mall name and rating header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.mall.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 18,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.mall.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Quick actions card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildActionButton(
                              icon: Icons.directions,
                              label: 'Directions',
                              onTap: _openInMaps,
                            ),
                            _buildActionButton(
                              icon: Icons.access_time,
                              label: 'Hours',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Opening hours: ${widget.mall.openingHours}',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                            _buildActionButton(
                              icon:
                                  widget.mall.isOpen
                                      ? Icons.check_circle
                                      : Icons.cancel,
                              label: widget.mall.isOpen ? 'Open' : 'Closed',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      widget.mall.isOpen
                                          ? 'This mall is currently open to visitors'
                                          : 'This mall is currently closed to visitors',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                            _buildActionButton(
                              icon: Icons.store,
                              label: 'Stores',
                              onTap: () {
                                // Navigate to the stores detail screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => StoreDetailScreen(
                                          mall: widget.mall,
                                        ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Mall info section
                      _buildSectionCard(
                        title: 'Basic Info',
                        icon: Icons.info_outline,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(Icons.category, widget.mall.type),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.shopping_bag,
                              'Stores: ${widget.mall.storeCount} retail outlets',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.access_time,
                              'Hours: ${widget.mall.openingHours}',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.local_parking,
                              'Parking: ${widget.mall.hasParking ? "Available" : "Not available"}',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.verified_user,
                              'Status: ${widget.mall.isOpen ? "Open now" : "Closed now"}',
                              iconColor:
                                  widget.mall.isOpen
                                      ? Colors.green
                                      : Colors.red,
                            ),
                          ],
                        ),
                      ),

                      // Description section
                      _buildSectionCard(
                        title: 'About',
                        icon: Icons.info_outline,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.mall.description.isEmpty
                                  ? 'No description available for this mall.'
                                  : widget.mall.description,
                              style: TextStyle(
                                fontSize: 15,
                                color: textPrimaryColor.withOpacity(0.8),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Additional info in pills
                            Row(
                              children: [
                                // Address pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _scrollToMapSection,
                                      borderRadius: BorderRadius.circular(30),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            color: secondaryColor,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            "View on Map",
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: secondaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Status pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        widget.mall.isOpen
                                            ? Icons.access_time
                                            : Icons.timer_off,
                                        color:
                                            widget.mall.isOpen
                                                ? Colors.green[700]
                                                : Colors.red[700],
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        widget.mall.isOpen
                                            ? "Open Now"
                                            : "Closed",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color:
                                              widget.mall.isOpen
                                                  ? Colors.green[700]
                                                  : Colors.red[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Features section
                      _buildSectionCard(
                        title: 'Amenities',
                        icon: Icons.star_outline,
                        content: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _buildAmenityChips(),
                        ),
                      ),

                      // Stores section card
                      _buildSectionCard(
                        title: 'Featured Stores',
                        icon: Icons.storefront,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Display up to 4 stores in a grid
                            if (_loadingStores)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (_storeData.isNotEmpty)
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 1.1,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                    ),
                                itemCount:
                                    _storeData.length > 4
                                        ? 4
                                        : _storeData.length,
                                itemBuilder: (context, index) {
                                  final store = _storeData[index];
                                  return _buildStoreGridItemFromData(store);
                                },
                              )
                            else
                              Text(
                                'No stores found for this mall',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),

                            const SizedBox(height: 16),

                            // View All Stores button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => StoreDetailScreen(
                                            mall: widget.mall,
                                          ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.storefront),
                                label: const Text('View All Stores'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Location section - NOW AFTER STORES
                      _buildSectionCard(
                        key: _mapKey,
                        title: 'Location',
                        icon: Icons.location_on_outlined,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Address text
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: primaryColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.mall.address,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: textPrimaryColor.withOpacity(0.8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Map placeholder with rounded corners
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                height: 180,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.map_outlined,
                                            size: 50,
                                            color: primaryColor.withOpacity(
                                              0.7,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            widget.mall.address,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: textPrimaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                0.05,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              "Map preview unavailable",
                                              style: TextStyle(
                                                color: textSecondaryColor,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Directions button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _openInMaps,
                                icon: const Icon(Icons.directions),
                                label: const Text('Get Directions'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.black87,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Lat: ${widget.mall.location.latitude.toStringAsFixed(6)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Lng: ${widget.mall.location.longitude.toStringAsFixed(6)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Bottom padding
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primaryColor, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget content,
    Widget? trailing,
    Key? key,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: secondaryColor, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),
          Padding(padding: const EdgeInsets.all(16), child: content),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? iconColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor ?? secondaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: textPrimaryColor.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAmenityChips() {
    List<Widget> features = [];

    if (widget.mall.hasWifi) {
      features.add(_buildFeatureChip('Free WiFi', Icons.wifi));
    }

    if (widget.mall.hasParking) {
      features.add(_buildFeatureChip('Parking Available', Icons.local_parking));
    }

    if (widget.mall.hasFoodCourt) {
      features.add(_buildFeatureChip('Food Court', Icons.restaurant));
    }

    if (widget.mall.hasChildrenArea) {
      features.add(_buildFeatureChip('Children Area', Icons.child_care));
    }

    return features;
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: secondaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: secondaryColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: secondaryColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String imageSource) {
    // Check for empty image URL
    if (imageSource.isEmpty) {
      return _buildImageErrorWidget();
    }

    // Handle base64 encoded images (both data:image URLs and plain base64 strings)
    if (imageSource.startsWith('data:image') ||
        RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(imageSource)) {
      try {
        Uint8List imageBytes;

        if (imageSource.startsWith('data:image')) {
          // Extract base64 data from data URL
          final parts = imageSource.split(',');
          if (parts.length < 2) {
            print('Invalid data URL format: $imageSource');
            return _buildImageErrorWidget();
          }
          imageBytes = base64Decode(parts[1]);
        } else {
          // Regular base64 string
          imageBytes = base64Decode(imageSource);
        }

        return Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            return Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: child,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('Error displaying base64 image: $error');
            return _buildImageErrorWidget();
          },
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return _buildImageErrorWidget();
      }
    } else {
      // Network image
      return CachedNetworkImage(
        imageUrl: imageSource,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        imageBuilder:
            (context, imageProvider) => Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 0.5,
                ),
                image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
              ),
            ),
        placeholder:
            (context, url) => Container(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),
        errorWidget: (context, url, error) {
          print('Error loading network image: $error for URL: $url');
          return _buildImageErrorWidget();
        },
      );
    }
  }

  Widget _buildImageErrorWidget() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront, size: 60, color: Colors.white70),
            const SizedBox(height: 8),
            Text(
              "Image unavailable",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreGridItem(String storeName) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoreDetailScreen(mall: widget.mall),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Store image - use actual store images from database
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                // Use a FutureBuilder to get and display the store image
                child: FutureBuilder<String>(
                  future: _getStoreImageUrl(storeName),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData &&
                        snapshot.data!.isNotEmpty) {
                      // Use the existing image widget builder
                      return _buildImageWidget(snapshot.data!);
                    } else {
                      // Fallback to colored container with icon
                      return Container(
                        color:
                            Colors
                                .primaries[storeName.hashCode %
                                    Colors.primaries.length]
                                .shade200,
                        child: Center(
                          child: Icon(
                            _getStoreIcon(storeName),
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),

            // Store name in a proper footer (unchanged)
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                storeName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to get appropriate icon based on store name
  IconData _getStoreIcon(String storeName) {
    final name = storeName.toLowerCase();

    if (name.contains('fashion') ||
        name.contains('cloth') ||
        name.contains('wear')) {
      return Icons.shopping_bag;
    } else if (name.contains('food') ||
        name.contains('cafe') ||
        name.contains('restaurant')) {
      return Icons.restaurant;
    } else if (name.contains('tech') ||
        name.contains('phone') ||
        name.contains('electronic')) {
      return Icons.devices;
    } else if (name.contains('book') || name.contains('library')) {
      return Icons.menu_book;
    } else if (name.contains('sport') || name.contains('fitness')) {
      return Icons.sports_basketball;
    } else if (name.contains('beauty') || name.contains('salon')) {
      return Icons.spa;
    } else if (name.contains('toy') || name.contains('game')) {
      return Icons.toys;
    } else if (name.contains('health') || name.contains('pharmacy')) {
      return Icons.medical_services;
    } else {
      return Icons.store;
    }
  }

  // Add this helper method to fetch store image URLs
  Future<String> _getStoreImageUrl(String storeName) async {
    try {
      // Access Firestore to get the store data
      final storeDoc =
          await FirebaseFirestore.instance
              .collection('stores')
              .where('mallId', isEqualTo: widget.mall.id)
              .where('name', isEqualTo: storeName)
              .limit(1)
              .get();

      if (storeDoc.docs.isNotEmpty) {
        final storeData = storeDoc.docs.first.data();
        return storeData['imageUrl'] ?? '';
      }
    } catch (e) {
      print('Error fetching store image: $e');
    }
    return '';
  }

  Widget _buildStoreGridItemFromData(Map<String, dynamic> store) {
    final storeName = store['name'] ?? 'Unnamed Store';
    final storeImageUrl = store['imageUrl'] ?? '';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoreDetailScreen(mall: widget.mall),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Store image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: _buildImageWidget(storeImageUrl),
              ),
            ),

            // Store name in a proper footer
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                storeName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
