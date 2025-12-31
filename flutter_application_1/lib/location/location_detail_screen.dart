import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_application_1/location/location_model.dart';
import 'package:flutter_application_1/location/location_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';

class LocationDetailScreen extends StatefulWidget {
  final Location location;

  const LocationDetailScreen({Key? key, required this.location})
    : super(key: key);

  @override
  State<LocationDetailScreen> createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends State<LocationDetailScreen> {
  final user = FirebaseAuth.instance.currentUser;
  GoogleMapController? _mapController;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  bool _mapReady = false;
  final ScrollController _scrollController = ScrollController();
  bool _showBookingButton = true;
  final LocationService _locationService = LocationService();

  // Theme colors
  final Color primaryColor = const Color(0xFFFDCB00);
  final Color secondaryColor = const Color(0xFF065d67);
  final Color backgroundColor = const Color(0xFFF9F9F9);
  final Color cardColor = Colors.white;
  final Color textPrimaryColor = const Color(0xFF212121);
  final Color textSecondaryColor = const Color(0xFF757575);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _mapController?.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Hide/show booking button based on scroll position
    if (_scrollController.position.pixels > 200 && _showBookingButton) {
      setState(() {
        _showBookingButton = false;
      });
    } else if (_scrollController.position.pixels <= 200 &&
        !_showBookingButton) {
      setState(() {
        _showBookingButton = true;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to favorite locations'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      bool isFavorited = widget.location.favoritedBy.contains(user.uid);
      await _locationService.toggleFavorite(
        widget.location.id,
        user.uid,
        isFavorited,
      );

      setState(() {
        if (isFavorited) {
          widget.location.favoritedBy.remove(user.uid);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed ${widget.location.name} from favorites'),
              backgroundColor: Colors.red[400],
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          widget.location.favoritedBy.add(user.uid);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${widget.location.name} to favorites'),
              backgroundColor: Colors.green[400],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
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

  Future<void> _shareLocation() async {
    try {
      // Create share text
      final String shareText =
          "Check out ${widget.location.name} on our app!\n\n"
          "${widget.location.description}\n\n"
          "🏠 ${widget.location.address}\n"
          "⭐ ${widget.location.rating} stars\n"
          "🏨 ${widget.location.type}\n"
          "💰 ${widget.location.pricePerNight} DH/night\n";

      // Temporary alternative until you add the share_plus package
      await Clipboard.setData(ClipboardData(text: shareText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location details copied to clipboard!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Error sharing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not share location information'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
              // Header with Image Carousel - Glovo-style
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
                  background:
                      widget.location.imageUrls.isNotEmpty
                          ? Stack(
                            fit: StackFit.expand,
                            children: [
                              // Image PageView
                              PageView.builder(
                                controller: _pageController,
                                itemCount:
                                    widget.location.imageUrls.isEmpty
                                        ? 1
                                        : widget.location.imageUrls.length,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentImageIndex = index;
                                  });
                                },
                                physics: const BouncingScrollPhysics(),
                                pageSnapping: true,
                                itemBuilder: (context, index) {
                                  if (widget.location.imageUrls.isEmpty) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(
                                          Icons.hotel,
                                          size: 80,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    );
                                  }
                                  return _buildImageWidget(
                                    widget.location.imageUrls[index],
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
                                      Colors.black.withOpacity(0.7),
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                ),
                              ),

                              // Page indicators
                              if (widget.location.imageUrls.length > 1)
                                Positioned(
                                  bottom: 16,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      widget.location.imageUrls.length,
                                      (index) => Container(
                                        width:
                                            _currentImageIndex == index
                                                ? 12
                                                : 8,
                                        height:
                                            _currentImageIndex == index
                                                ? 12
                                                : 8,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:
                                              _currentImageIndex == index
                                                  ? primaryColor
                                                  : Colors.white.withOpacity(
                                                    0.7,
                                                  ),
                                          border: Border.all(
                                            color: Colors.black.withOpacity(
                                              0.2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              // Navigation arrows
                              if (widget.location.imageUrls.length > 1)
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
                                              // Loop to last image when at the beginning
                                              _pageController.animateToPage(
                                                widget
                                                        .location
                                                        .imageUrls
                                                        .length -
                                                    1,
                                                duration: const Duration(
                                                  milliseconds: 300,
                                                ),
                                                curve: Curves.easeInOut,
                                              );
                                            }
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                              left: 8,
                                            ),
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
                                                widget
                                                        .location
                                                        .imageUrls
                                                        .length -
                                                    1) {
                                              _pageController.animateToPage(
                                                _currentImageIndex + 1,
                                                duration: const Duration(
                                                  milliseconds: 300,
                                                ),
                                                curve: Curves.easeInOut,
                                              );
                                            } else {
                                              // Loop to first image when at the end
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
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                            ),
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
                          )
                          : Container(
                            color: Colors.grey[300],
                            child: Center(
                              child: Icon(
                                Icons.hotel,
                                size: 80,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                ),
                // Back button with better contrast
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
                // Actions with better contrast
                actions: [
                  // Share button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _shareLocation,
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
                          widget.location.favoritedBy.contains(user?.uid)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              widget.location.favoritedBy.contains(user?.uid)
                                  ? Colors.red
                                  : Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Main content - Glovo-style cards
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with title and price
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.location.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.location.address,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.star, size: 16, color: primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.location.rating}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '(${widget.location.reviewCount} reviews)',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: secondaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    widget.location.type,
                                    style: TextStyle(
                                      color: secondaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '${widget.location.pricePerNight.toStringAsFixed(0)} DH',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: secondaryColor,
                                  ),
                                ),
                                Text(
                                  ' / night',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Quick Actions - Glovo style
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
                            _buildGlovoActionButton(
                              icon: Icons.directions,
                              label: 'Directions',
                              onTap: () async {
                                await _openDirections();
                              },
                            ),
                            if (widget.location.phoneNumber.isNotEmpty)
                              _buildGlovoActionButton(
                                icon: Icons.call,
                                label: 'Call',
                                onTap: () async {
                                  final Uri url = Uri.parse(
                                    'tel:${widget.location.phoneNumber}',
                                  );
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url);
                                  }
                                },
                              ),
                            _buildGlovoActionButton(
                              icon: Icons.language,
                              label: 'Website',
                              onTap: () async {
                                if (widget.location.website.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'No website available for this location',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }

                                // Ensure URL has proper scheme
                                String websiteUrl = widget.location.website;
                                if (!websiteUrl.startsWith('http://') &&
                                    !websiteUrl.startsWith('https://')) {
                                  websiteUrl = 'https://$websiteUrl';
                                }

                                try {
                                  final Uri url = Uri.parse(websiteUrl);
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(
                                      url,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } else {
                                    throw 'Could not launch website';
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Could not open website: $e',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            _buildGlovoActionButton(
                              icon: Icons.photo_library,
                              label: 'All Photos',
                              onTap: () {
                                _showAllPhotos(context);
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Description card
                      _buildGlovoSectionCard(
                        title: 'About',
                        icon: Icons.info_outline,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.location.description,
                              style: TextStyle(
                                fontSize: 15,
                                color: textPrimaryColor.withOpacity(0.8),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Accommodations stats
                            Row(
                              children: [
                                _buildFeatureChip(
                                  Icons.hotel,
                                  '${widget.location.numberOfRooms} Rooms',
                                ),
                                const SizedBox(width: 8),
                                _buildFeatureChip(
                                  Icons.king_bed,
                                  'Sleeps ${widget.location.numberOfRooms * 2}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Amenities section
                      _buildGlovoSectionCard(
                        title: 'Amenities',
                        icon: Icons.hotel_class_outlined,
                        content: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              widget.location.amenities.map((amenity) {
                                return _buildAmenityChip(amenity);
                              }).toList(),
                        ),
                      ),

                      // Features section
                      if (widget.location.features.isNotEmpty)
                        _buildGlovoSectionCard(
                          title: 'Features',
                          icon: Icons.star_border_outlined,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                widget.location.features.map((feature) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: primaryColor,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            feature,
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: textPrimaryColor
                                                  .withOpacity(0.8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),

                      // Location section - Glovo style
                      _buildGlovoSectionCard(
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
                                    widget.location.address,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: textPrimaryColor.withOpacity(0.8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Map with rounded corners
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                height: 180,
                                width: double.infinity,
                                child: _buildMapWidget(),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Directions button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await _openDirections();
                                },
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
                          ],
                        ),
                      ),

                      // Bottom padding to account for CTA button
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Glovo-style floating CTA button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => _showBookingDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Book Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlovoActionButton({
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

  Widget _buildGlovoSectionCard({
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

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: secondaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityChip(String amenity) {
    IconData iconData;

    // Map amenity strings to appropriate icons
    if (amenity.toLowerCase().contains('wifi')) {
      iconData = Icons.wifi;
    } else if (amenity.toLowerCase().contains('pool')) {
      iconData = Icons.pool;
    } else if (amenity.toLowerCase().contains('breakfast')) {
      iconData = Icons.coffee;
    } else if (amenity.toLowerCase().contains('parking')) {
      iconData = Icons.local_parking;
    } else if (amenity.toLowerCase().contains('tv')) {
      iconData = Icons.tv;
    } else if (amenity.toLowerCase().contains('air')) {
      iconData = Icons.ac_unit;
    } else if (amenity.toLowerCase().contains('kitchen')) {
      iconData = Icons.kitchen;
    } else if (amenity.toLowerCase().contains('washer')) {
      iconData = Icons.local_laundry_service;
    } else {
      iconData = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 16, color: secondaryColor),
          const SizedBox(width: 6),
          Text(amenity, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String imageSource) {
    if (imageSource.startsWith('data:image') ||
        RegExp(
          r'^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)?$',
        ).hasMatch(imageSource)) {
      String base64String = imageSource;
      if (imageSource.contains(',')) {
        base64String = imageSource.split(',')[1];
      }

      try {
        return Image.memory(
          base64Decode(base64String),
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
            return _buildImageErrorWidget();
          },
        );
      } catch (e) {
        return _buildImageErrorWidget();
      }
    } else {
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
        errorWidget: (context, url, error) => _buildImageErrorWidget(),
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
            Icon(Icons.hotel, size: 60, color: Colors.white70),
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

  Widget _buildMapWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 50,
                  color: primaryColor.withOpacity(0.7),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.location.address,
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
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Map preview unavailable",
                    style: TextStyle(color: textSecondaryColor, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDirections() async {
    try {
      if (widget.location.location.latitude != 0 &&
          widget.location.location.longitude != 0) {
        final url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${widget.location.location.latitude},${widget.location.location.longitude}',
        );
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
          return;
        }
      }

      final addressUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.location.address)}',
      );
      if (await canLaunchUrl(addressUrl)) {
        await launchUrl(addressUrl);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not open map directions")),
          );
        }
      }
    } catch (e) {
      print("Error opening directions: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Error opening maps")));
      }
    }
  }

  void _showAllPhotos(BuildContext context) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder:
          (context) => Dialog.fullscreen(
            child: Stack(
              children: [
                // Photos gallery
                PageView.builder(
                  controller: PageController(initialPage: _currentImageIndex),
                  itemCount: widget.location.imageUrls.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        color: Colors.black,
                        child: Center(
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 3.0,
                            child: _buildImageWidget(
                              widget.location.imageUrls[index],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Close button
                Positioned(
                  top: 40,
                  left: 16,
                  child: IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, color: Colors.white),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // Image counter indicator
                Positioned(
                  top: 40,
                  right: 16,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1}/${widget.location.imageUrls.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showBookingDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    DateTime selectedEndDate = DateTime.now().add(const Duration(days: 2));
    int numberOfGuests = 2;
    final TextEditingController notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Container(
                  height: MediaQuery.of(context).size.height * 0.85,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with close button
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Expanded(
                              child: Text(
                                'Book Your Stay',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 48), // Balance the header
                          ],
                        ),
                      ),

                      // Location info preview
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.grey[100]),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildLocationImage(
                                widget.location.imageUrls.isNotEmpty
                                    ? widget.location.imageUrls[0]
                                    : '',
                                width: 60,
                                height: 60,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.location.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.location.pricePerNight.toStringAsFixed(0)} DH/night · ${widget.location.type}',
                                    style: TextStyle(
                                      color: secondaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.location.address,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Check-in Date selector
                              Text(
                                'Check-in Date',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: secondaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Date picker
                              InkWell(
                                onTap: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: secondaryColor,
                                            onPrimary: Colors.white,
                                            surface: Colors.white,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null &&
                                      picked != selectedDate) {
                                    setState(() {
                                      selectedDate = picked;
                                      // Ensure checkout is at least one day after checkin
                                      if (selectedEndDate.isBefore(
                                        selectedDate.add(
                                          const Duration(days: 1),
                                        ),
                                      )) {
                                        selectedEndDate = selectedDate.add(
                                          const Duration(days: 1),
                                        );
                                      }
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        color: secondaryColor,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        DateFormat(
                                          'EEE, MMM d, yyyy',
                                        ).format(selectedDate),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.grey[600],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Check-out Date selector
                              Text(
                                'Check-out Date',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: secondaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Check-out date picker
                              InkWell(
                                onTap: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedEndDate,
                                    firstDate: selectedDate.add(
                                      const Duration(days: 1),
                                    ),
                                    lastDate: selectedDate.add(
                                      const Duration(days: 30),
                                    ),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: secondaryColor,
                                            onPrimary: Colors.white,
                                            surface: Colors.white,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null &&
                                      picked != selectedEndDate) {
                                    setState(() {
                                      selectedEndDate = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        color: secondaryColor,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        DateFormat(
                                          'EEE, MMM d, yyyy',
                                        ).format(selectedEndDate),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.grey[600],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Number of guests
                              Text(
                                'Number of Guests',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: secondaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Guests counter with +/- buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed:
                                        numberOfGuests > 1
                                            ? () =>
                                                setState(() => numberOfGuests--)
                                            : null,
                                    icon: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              numberOfGuests > 1
                                                  ? secondaryColor
                                                  : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.remove,
                                        size: 18,
                                        color:
                                            numberOfGuests > 1
                                                ? secondaryColor
                                                : Colors.grey[300],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 80,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    child: Text(
                                      numberOfGuests.toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed:
                                        numberOfGuests < 10
                                            ? () =>
                                                setState(() => numberOfGuests++)
                                            : null,
                                    icon: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              numberOfGuests < 10
                                                  ? secondaryColor
                                                  : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        size: 18,
                                        color:
                                            numberOfGuests < 10
                                                ? secondaryColor
                                                : Colors.grey[300],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),
                              Text(
                                'Special requests (optional)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: secondaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: notesController,
                                decoration: InputDecoration(
                                  hintText:
                                      'Example: Late check-in, special accommodations...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                maxLines: 3,
                              ),

                              const SizedBox(height: 24),

                              // Price summary
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Price Summary',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Calculate days difference
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${widget.location.pricePerNight} MAD × ${selectedEndDate.difference(selectedDate).inDays} nights',
                                        ),
                                        Text(
                                          '${(widget.location.pricePerNight * selectedEndDate.difference(selectedDate).inDays).toStringAsFixed(2)} MAD',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: const [
                                        Text('Cleaning fee'),
                                        Text(
                                          '150.00 MAD',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: const [
                                        Text('Service fee'),
                                        Text(
                                          '100.00 MAD',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Divider(),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Total',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${(widget.location.pricePerNight * selectedEndDate.difference(selectedDate).inDays + 150 + 100).toStringAsFixed(2)} MAD',
                                          style: TextStyle(
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

                      // Book button
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              // Show loading indicator
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder:
                                    (context) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                              );

                              try {
                                // Get current user
                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) {
                                  Navigator.pop(
                                    context,
                                  ); // Close loading dialog
                                  Navigator.pop(
                                    context,
                                  ); // Close booking dialog
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please sign in to book'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                // Create booking data
                                final bookingData = {
                                  'userId': user.uid,
                                  'userName': user.displayName ?? 'Guest',
                                  'userEmail': user.email ?? '',
                                  'locationId': widget.location.id,
                                  'locationName': widget.location.name,
                                  'locationImage':
                                      widget.location.imageUrls.isNotEmpty
                                          ? widget.location.imageUrls[0]
                                          : '',
                                  'profileImageUrl':
                                      widget
                                          .location
                                          .profileImageUrl, // Added to match other bookings
                                  'locationType': widget.location.type,
                                  'date': Timestamp.fromDate(selectedDate),
                                  'checkoutDate': Timestamp.fromDate(
                                    selectedEndDate,
                                  ),
                                  'guests': numberOfGuests,
                                  'price': widget.location.pricePerNight,
                                  'totalPrice':
                                      widget.location.pricePerNight *
                                          selectedEndDate
                                              .difference(selectedDate)
                                              .inDays +
                                      150 +
                                      100,
                                  'notes': notesController.text.trim(),
                                  'status': 'pending',
                                  'createdAt': Timestamp.now(),
                                  'cityId': widget.location.cityId,
                                  'cityName': widget.location.cityName,
                                  'address': widget.location.address,
                                  'type':
                                      'location', // To distinguish from other booking types
                                };

                                // Save to Firestore
                                await FirebaseFirestore.instance
                                    .collection('bookings')
                                    .add(bookingData);

                                // Close dialogs and show success message
                                Navigator.pop(context); // Close loading dialog
                                Navigator.pop(context); // Close booking dialog

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Booking confirmed for ${widget.location.name}!',
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              } catch (e) {
                                print('Error creating location booking: $e');
                                Navigator.pop(context); // Close loading dialog

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Booking failed: $e'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'BOOK NOW',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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

  Widget _buildLocationImage(
    String imageSource, {
    required double width,
    required double height,
  }) {
    if (imageSource.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: Icon(Icons.hotel, color: Colors.grey[600]),
      );
    }

    if (imageSource.startsWith('data:image') ||
        RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(imageSource)) {
      try {
        String base64String =
            imageSource.startsWith('data:image')
                ? imageSource.split(',')[1]
                : imageSource;
        return Image.memory(
          base64Decode(base64String),
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) => Container(
                width: width,
                height: height,
                color: Colors.grey[300],
                child: Icon(Icons.hotel, color: Colors.grey[600]),
              ),
        );
      } catch (e) {
        print('Error decoding base64 location image: $e');
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: Icon(Icons.hotel, color: Colors.grey[600]),
        );
      }
    }

    return CachedNetworkImage(
      imageUrl: imageSource,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder:
          (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
      errorWidget:
          (context, url, error) => Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: Icon(Icons.hotel, color: Colors.grey[600]),
          ),
    );
  }
}
