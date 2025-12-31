import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/restaurant/restaurant_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_application_1/restaurant/menu_item_model.dart';
import 'package:flutter_application_1/restaurant/menu_service.dart';
import 'package:flutter_application_1/restaurant/add_menu_item_screen.dart';
import 'package:flutter_application_1/restaurant/menu_detail_screen.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({Key? key, required this.restaurant})
    : super(key: key);

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen>
    with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  GoogleMapController? _mapController;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  bool _mapReady = false;
  bool _showMenu = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _mapKey = GlobalKey();
  final GlobalKey _mapContentKey = GlobalKey(); // New key for the inner content

  // Theme colors
  final Color primaryColor = const Color(0xFFFDCB00);
  final Color secondaryColor = const Color(0xFF065d67);
  final Color backgroundColor = const Color(0xFFF9F9F9);
  final Color cardColor = Colors.white;
  final Color textPrimaryColor = const Color(0xFF212121);
  final Color textSecondaryColor = const Color(0xFF757575);

  @override
  void dispose() {
    _pageController.dispose();
    _mapController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to favorite restaurants'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final restaurantRef = FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurant.id);

      bool isFavorited = widget.restaurant.favoritedBy.contains(user.uid);

      if (isFavorited) {
        await restaurantRef.update({
          'favoritedBy': FieldValue.arrayRemove([user.uid]),
        });

        setState(() {
          widget.restaurant.favoritedBy.remove(user.uid);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${widget.restaurant.name} from favorites'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        await restaurantRef.update({
          'favoritedBy': FieldValue.arrayUnion([user.uid]),
        });

        setState(() {
          widget.restaurant.favoritedBy.add(user.uid);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${widget.restaurant.name} to favorites'),
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

  Future<void> _shareRestaurant() async {
    try {
      // Create share text
      final String shareText =
          "Check out ${widget.restaurant.name} on our app!\n\n"
          "${widget.restaurant.description}\n\n"
          "🏠 ${widget.restaurant.address}\n"
          "⭐ ${widget.restaurant.rating} stars\n"
          "🍽️ ${widget.restaurant.cuisine}\n";

      // If you have a dynamic link or referral system, add it here
      // "Download our app: https://your-app-link.com";

      // Share using system share sheet
      // This requires adding the share_plus package to your pubspec.yaml
      // await Share.share(shareText, subject: 'Check out ${widget.restaurant.name}!');

      // Temporary alternative until you add the share_plus package
      await Clipboard.setData(ClipboardData(text: shareText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restaurant details copied to clipboard!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Error sharing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not share restaurant information'),
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
                      widget.restaurant.imageUrls.isNotEmpty
                          ? Stack(
                            fit: StackFit.expand,
                            children: [
                              // Image PageView
                              PageView.builder(
                                controller: _pageController,
                                itemCount:
                                    widget.restaurant.imageUrls.isEmpty
                                        ? 1
                                        : widget.restaurant.imageUrls.length,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentImageIndex = index;
                                  });
                                },
                                physics: const BouncingScrollPhysics(),
                                pageSnapping: true,
                                itemBuilder: (context, index) {
                                  if (widget.restaurant.imageUrls.isEmpty) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(
                                          Icons.restaurant,
                                          size: 80,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    );
                                  }
                                  return _buildImageWidget(
                                    widget.restaurant.imageUrls[index],
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
                              if (widget.restaurant.imageUrls.length > 1)
                                Positioned(
                                  bottom: 16,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      widget.restaurant.imageUrls.length,
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
                              if (widget.restaurant.imageUrls.length > 1)
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
                                                        .restaurant
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
                                                        .restaurant
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
                                Icons.restaurant,
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
                      onTap: _shareRestaurant,
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
                          widget.restaurant.favoritedBy.contains(user?.uid)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              widget.restaurant.favoritedBy.contains(user?.uid)
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
                            if (widget.restaurant.phoneNumber.isNotEmpty)
                              _buildGlovoActionButton(
                                icon: Icons.call,
                                label: 'Call',
                                onTap: () async {
                                  final Uri url = Uri.parse(
                                    'tel:${widget.restaurant.phoneNumber}',
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
                                if (widget.restaurant.website.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'No website available for this restaurant',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }

                                // Ensure URL has proper scheme
                                String websiteUrl = widget.restaurant.website;
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
                              icon: Icons.menu_book,
                              label: 'Full Menu',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => MenuDetailScreen(
                                          restaurant: widget.restaurant,
                                        ),
                                  ),
                                );
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
                              widget.restaurant.description,
                              style: TextStyle(
                                fontSize: 15,
                                color: textPrimaryColor.withOpacity(0.8),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Additional info in Glovo style
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
                                      onTap: () {
                                        // Scroll to map section or directly open maps
                                        _scrollToMapSection();
                                      },
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

                                // Open hours pill
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
                                        Icons.access_time,
                                        color: Colors.green[700],
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Open Now",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.green[700],
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

                      // Menu section - Glovo style
                      _buildGlovoSectionCard(
                        title: 'Popular Menu',
                        icon: Icons.restaurant_menu,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Add Menu Item button
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => AddMenuItemScreen(
                                          restaurant: widget.restaurant,
                                        ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.add_circle,
                                color: Color(0xFF065d67),
                              ),
                              tooltip: 'Add Menu Item',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 12),
                            // View All button
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => MenuDetailScreen(
                                          restaurant: widget.restaurant,
                                        ),
                                  ),
                                );
                              },
                              child: Text(
                                'View All',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size(50, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        content: _buildGlovoMenuPreview(),
                      ),

                      // Location section - Glovo style
                      _buildGlovoSectionCard(
                        key:
                            _mapKey, // Keep this key for scrolling to the section
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
                                    widget.restaurant.address,
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
                                key: _mapContentKey, // Use the new key here
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
                                  foregroundColor: Colors.white,
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
                onPressed: () => _showTableBookingDialog(context),
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
                  'Book a Table',
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

  Widget _buildGlovoMenuPreview() {
    return FutureBuilder<List<MenuItem>>(
      future: getSafeMenuItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: CircularProgressIndicator(color: primaryColor),
            ),
          );
        }

        final allMenuItems = snapshot.data ?? [];

        // Filter only bestseller items
        final bestsellerItems =
            allMenuItems.where((item) => item.isBestseller).toList();

        // If no bestsellers, show a message suggesting to check full menu
        if (bestsellerItems.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.star_border, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No bestseller items available',
                    style: TextStyle(color: textSecondaryColor),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => MenuDetailScreen(
                                restaurant: widget.restaurant,
                              ),
                        ),
                      );
                    },
                    child: const Text('View Full Menu'),
                  ),
                ],
              ),
            ),
          );
        }

        // Show limited number of bestseller items in a Glovo-style grid
        final displayItems = bestsellerItems.take(4).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menu items grid
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: displayItems.length,
              itemBuilder: (context, index) {
                final item = displayItems[index];
                return _buildGlovoMenuItem(item);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildGlovoMenuItem(MenuItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            // Navigate to menu details or add to cart
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item image
              Expanded(
                child: Stack(
                  children: [
                    // Image with rounded top corners
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child:
                            item.imageUrl.isNotEmpty
                                ? _buildImageWidget(item.imageUrl)
                                : Container(
                                  color: primaryColor.withOpacity(0.1),
                                  child: Center(
                                    child: Icon(
                                      getRandomFoodIcon(item.name.hashCode),
                                      size: 40,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                      ),
                    ),

                    // Bestseller badge
                    if (item.isBestseller)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Bestseller',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Price tag
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomRight: Radius.circular(0),
                          ),
                        ),
                        child: Text(
                          '${item.price.toStringAsFixed(2)} MAD',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Item details
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item name
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Item description
                    Text(
                      item.description,
                      style: TextStyle(color: textSecondaryColor, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  IconData getRandomFoodIcon(int index) {
    final icons = [
      Icons.fastfood,
      Icons.local_pizza,
      Icons.restaurant,
      Icons.kebab_dining,
      Icons.coffee,
      Icons.icecream,
      Icons.lunch_dining,
      Icons.bakery_dining,
    ];
    return icons[index % icons.length];
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
            Icon(Icons.restaurant, size: 60, color: Colors.white70),
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
                  widget.restaurant.address,
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
      if (widget.restaurant.location.latitude != 0 &&
          widget.restaurant.location.longitude != 0) {
        final url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${widget.restaurant.latLng.latitude},${widget.restaurant.latLng.longitude}',
        );
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
          return;
        }
      }

      final addressUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.restaurant.address)}',
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

  Future<List<MenuItem>> getSafeMenuItems() async {
    try {
      print('Loading menu for restaurant ID: ${widget.restaurant.id}');
      final MenuService _menuService = MenuService();
      List<MenuItem> menuItems = [];

      try {
        menuItems = await _menuService.getMenuForRestaurant(
          widget.restaurant.id,
        );
        print('Loaded ${menuItems.length} items from Firestore');

        if (menuItems.isNotEmpty) {
          return menuItems;
        }
      } catch (e) {
        print('Error loading from Firestore: $e');
      }

      if (widget.restaurant.menuItems.isNotEmpty) {
        print('Creating mock items from restaurant.menuItems');
        int index = 0;

        final categories = [
          'Starters',
          'Main Course',
          'Desserts',
          'Beverages',
          'Specials',
        ];

        return widget.restaurant.menuItems.map((itemName) {
          final category = categories[index % categories.length];

          final mockItem = MenuItem(
            id: 'mock-${index++}',
            name: itemName,
            price: 50.0 + (index * 10),
            description: 'Delicious $itemName prepared with fresh ingredients',
            imageUrl: '',
            category: category,
            restaurantId: widget.restaurant.id,
            restaurantName: widget.restaurant.name,
            cityId: widget.restaurant.cityId,
          );

          return mockItem;
        }).toList();
      }

      return [];
    } catch (e) {
      print('Error in getSafeMenuItems: $e');
      return [];
    }
  }

  void _scrollToMapSection() {
    // You can either scroll to map section
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
      // Or directly open maps if scrolling isn't working
      _openDirections();
    }
  }

  void _showTableBookingDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 19, minute: 0);
    int numberOfGuests = 2;
    final TextEditingController notesController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
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
                        'Book a Table',
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
              
              // Restaurant info preview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: widget.restaurant.imageUrls.isNotEmpty
                        ? _buildRestaurantImage(widget.restaurant.imageUrls[0], 60, 60)
                        : Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: Icon(Icons.restaurant, color: Colors.grey[400]),
                          ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.restaurant.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.restaurant.cuisine,
                            style: TextStyle(
                              color: textSecondaryColor,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.star, size: 16, color: primaryColor),
                              const SizedBox(width: 4),
                              Text(
                                widget.restaurant.rating.toString(),
                                style: TextStyle(
                                  color: textSecondaryColor,
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
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date selector
                      Text(
                        'Select Date',
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
                            lastDate: DateTime.now().add(const Duration(days: 30)),
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
                          if (picked != null && picked != selectedDate) {
                            setState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: secondaryColor),
                              const SizedBox(width: 12),
                              Text(
                                _formatDate(selectedDate),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Spacer(),
                              Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Time selector
                      Text(
                        'Select Time',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Time slots grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 2.0,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: 12, // Show 12 time slots
                        itemBuilder: (context, index) {
                          // Generate time slots from 12:00 PM to 11:30 PM
                          final hour = 12 + (index ~/ 2);
                          final minute = (index % 2) * 30;
                          final timeSlot = TimeOfDay(hour: hour % 24, minute: minute);
                          final isSelected = timeSlot.hour == selectedTime.hour && 
                                            timeSlot.minute == selectedTime.minute;
                          
                          return InkWell(
                            onTap: () {
                              setState(() {
                                selectedTime = timeSlot;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? primaryColor : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? primaryColor : Colors.grey[300]!,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  _formatTimeOfDay(timeSlot),
                                  style: TextStyle(
                                    color: isSelected ? Colors.black87 : Colors.grey[800],
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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
                      
                      // Guest counter with +/- buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: numberOfGuests > 1
                                ? () => setState(() => numberOfGuests--)
                                : null,
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: numberOfGuests > 1 
                                    ? secondaryColor 
                                    : Colors.grey[300]!,
                                ),
                              ),
                              child: Icon(
                                Icons.remove,
                                size: 18,
                                color: numberOfGuests > 1 
                                  ? secondaryColor 
                                  : Colors.grey[300],
                              ),
                            ),
                          ),
                          Container(
                            width: 80,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
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
                            onPressed: numberOfGuests < 20
                                ? () => setState(() => numberOfGuests++)
                                : null,
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: numberOfGuests < 20 
                                    ? secondaryColor 
                                    : Colors.grey[300]!,
                                ),
                              ),
                              child: Icon(
                                Icons.add,
                                size: 18,
                                color: numberOfGuests < 20 
                                  ? secondaryColor 
                                  : Colors.grey[300],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      Text(
                        'Special requests or allergies (optional)',
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
                          hintText: 'Example: Window seat, birthday celebration, allergies...',
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
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );

                      try {
                        // Get current user
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          Navigator.pop(context); // Close loading dialog
                          Navigator.pop(context); // Close booking dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please sign in to book a table'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        // Format date and time for Firestore
                        final bookingDateTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );

                        // Get notes
                        final notes = notesController.text.trim();

                        // Create booking data
                        final bookingData = {
                          'userId': user.uid,
                          'userName': user.displayName ?? 'Guest',
                          'userEmail': user.email ?? '',
                          'restaurantId': widget.restaurant.id,
                          'restaurantName': widget.restaurant.name,
                          'date': Timestamp.fromDate(bookingDateTime),
                          'guests': numberOfGuests,
                          'notes': notes,
                          'status': 'pending', // pending, confirmed, completed, cancelled
                          'createdAt': Timestamp.now(),
                          'cityId': widget.restaurant.cityId,
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
                              'Table booked for ${_formatDate(selectedDate)} at ${_formatTimeOfDay(selectedTime)}',
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      } catch (e) {
                        // Handle error
                        Navigator.pop(context); // Close loading dialog
                        Navigator.pop(context); // Close booking dialog
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Booking failed: ${e.toString()}'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        print('Error booking table: $e');
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

  Widget _buildRestaurantImage(String imageUrl, double width, double height) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final parts = imageUrl.split(',');
        if (parts.length > 1) {
          final base64Str = parts[1];
          return Image.memory(
            base64Decode(base64Str),
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading base64 image: $error');
              return Container(
                width: width,
                height: height,
                color: Colors.grey[300],
                child: Icon(Icons.broken_image, color: Colors.grey[400]),
              );
            },
          );
        }
      } catch (e) {
        print('Error decoding base64 image: $e');
      }
    }
    
    // Regular URL image
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: primaryColor,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: Icon(Icons.broken_image, color: Colors.grey[400]),
      ),
    );
  }

  // Helper methods for date and time formatting
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} (${_getDayName(date.weekday)})';
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
