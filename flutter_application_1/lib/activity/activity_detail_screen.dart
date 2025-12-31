import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/activity/activity_model.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class ActivityDetailScreen extends StatefulWidget {
  final Activity activity;

  const ActivityDetailScreen({Key? key, required this.activity})
    : super(key: key);

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final user = FirebaseAuth.instance.currentUser;
  GoogleMapController? _mapController;
  int _currentImageIndex = 0;
  bool _mapReady = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _mapKey = GlobalKey();
  final GlobalKey _mapContentKey = GlobalKey();

  // Theme colors
  final Color primaryColor = const Color(0xFFFDCB00);
  final Color secondaryColor = const Color(0xFF065d67);
  final Color backgroundColor = const Color(0xFFF9F9F9);
  final Color cardColor = Colors.white;
  final Color textPrimaryColor = const Color(0xFF212121);
  final Color textSecondaryColor = const Color(0xFF757575);

  // Booking variables
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _peopleCount = 1;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _requestsController = TextEditingController();

  // Add a form key to your state class:
  final _bookingFormKey = GlobalKey<FormState>();

  // Add this to your state class:
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _requestsController.dispose();
    _mapController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      _isLoading = true;
    });
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to favorite activities'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final activityRef = FirebaseFirestore.instance
          .collection('activities')
          .doc(widget.activity.id);

      // Check if activity is already favorited
      bool isFavorited = widget.activity.favoritedBy.contains(user.uid);

      if (isFavorited) {
        // Remove from favorites
        await activityRef.update({
          'favoritedBy': FieldValue.arrayRemove([user.uid]),
        });

        setState(() {
          widget.activity.favoritedBy.remove(user.uid);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${widget.activity.name} from favorites'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Add to favorites
        await activityRef.update({
          'favoritedBy': FieldValue.arrayUnion([user.uid]),
        });

        setState(() {
          widget.activity.favoritedBy.add(user.uid);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${widget.activity.name} to favorites'),
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _shareActivity() async {
    try {
      // Create share text
      final String shareText =
          "Check out ${widget.activity.name} on our app!\n\n"
          "${widget.activity.description}\n\n"
          "🏠 ${widget.activity.address}\n"
          "⭐ ${widget.activity.rating} stars\n"
          "💰 ${widget.activity.price} MAD\n"
          "🎫 ${widget.activity.pointsRequired} points required\n";

      await Share.share(shareText);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openDirections() async {
    try {
      if (widget.activity.location.latitude != 0 &&
          widget.activity.location.longitude != 0) {
        final url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${widget.activity.location.latitude},${widget.activity.location.longitude}',
        );
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
          return;
        }
      }

      final addressUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.activity.address)}',
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
      _openDirections();
    }
  }

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
      color: Colors.grey[300],
      child: Icon(Icons.hiking, size: 50, color: Colors.grey[500]),
    );
  }

  // Add memoization for heavy computations
  Widget _buildMapWidget() {
    // Only rebuild the map if lat/lng has changed
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 50, color: Colors.grey[700]),
            SizedBox(height: 10),
            Text(
              "Map view temporarily unavailable",
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRedeemButton() {
    return FutureBuilder<bool>(
      future: _isActivityAlreadyRedeemed(),
      builder: (context, snapshot) {
        final bool isRedeemed = snapshot.data ?? false;
        final bool isLoading = snapshot.connectionState == ConnectionState.waiting;
        
        if (isRedeemed) {
          // Show "Already Redeemed" button
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Already Redeemed',
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          );
        }
        
        // Show regular redeem button if not redeemed
        return ElevatedButton(
          onPressed: isLoading ? null : () async {
            // First check if user is logged in
            if (user == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please sign in to redeem activities'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            // Check if user has enough points
            int userPoints = 0;
            setState(() {
              _isLoading = true;
            });

            try {
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .get();

              if (userDoc.exists) {
                userPoints = userDoc.data()?['fidelityPoints'] ?? 0;
              }

              setState(() {
                _isLoading = false;
              });

              // Compare points
              if (userPoints < widget.activity.pointsRequired) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Insufficient points! You need ${widget.activity.pointsRequired} points but have $userPoints',
                    ),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                  ),
                );
                return;
              }
              
              // If we have enough points, show confirmation dialog
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Redeem ${widget.activity.name}'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Would you like to redeem this activity for ${widget.activity.pointsRequired} points?',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.stars, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.activity.pointsRequired} points will be deducted from your balance of $userPoints points',
                            ),
                          ],
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Close the confirmation dialog
                          Navigator.of(context).pop();

                          // Update user's points in Firestore
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(user!.uid)
                              .update({
                                'fidelityPoints': FieldValue.increment(
                                  -widget.activity.pointsRequired,
                                ),
                              })
                              .then((_) {
                                // Log the redemption in a separate collection
                                FirebaseFirestore.instance
                                    .collection('redemptions')
                                    .add({
                                      'userId': user!.uid,
                                      'activityId': widget.activity.id,
                                      'activityName': widget.activity.name,
                                      'pointsUsed': widget.activity.pointsRequired,
                                      'timestamp': FieldValue.serverTimestamp(),
                                    });

                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Activity redeemed successfully!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                // Show the redemption success dialog with GIF
                                _showRedemptionSuccess();
                              })
                              .catchError((error) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error redeeming activity: $error',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              });
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: primaryColor,
                        ),
                        child: const Text('Redeem Now'),
                      ),
                    ],
                  );
                },
              );
            } catch (e) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error checking points: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isLoading 
                  ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : const Icon(Icons.redeem),
              const SizedBox(width: 8),
              Text(
                isLoading 
                    ? 'Checking...' 
                    : 'Redeem for ${widget.activity.pointsRequired} Points',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: primaryColor),
                    const SizedBox(width: 12),
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
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16), child: content),
        ],
      ),
    );
  }

  Widget _buildGlovoActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primaryColor),
            ),
            const SizedBox(height: 8),
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
      ),
    );
  }

  Widget _buildInclusionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green[600], size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: textPrimaryColor.withOpacity(0.8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExclusionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cancel, color: Colors.red[400], size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: textPrimaryColor.withOpacity(0.8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header with Image Carousel
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
                      widget.activity.imageUrls.isNotEmpty
                          ? Stack(
                            fit: StackFit.expand,
                            children: [
                              // Full-screen image carousel
                              FlutterCarousel.builder(
                                options: CarouselOptions(
                                  height: 240,
                                  viewportFraction: 1.0,
                                  autoPlay: true,
                                  autoPlayInterval: const Duration(seconds: 4),
                                  onPageChanged: (index, reason) {
                                    setState(() {
                                      _currentImageIndex = index;
                                    });
                                  },
                                  padEnds: false,
                                  enlargeCenterPage: false,
                                  disableCenter: true,
                                ),
                                itemCount: widget.activity.imageUrls.length,
                                itemBuilder: (context, index, realIndex) {
                                  return _buildImageWidget(
                                    widget.activity.imageUrls[index],
                                  );
                                },
                              ),

                              // Glovo-style gradient overlay
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.3),
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                              ),

                              // Activity info container at bottom
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Activity name
                                      Text(
                                        widget.activity.name,
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              offset: Offset(0, 1),
                                              blurRadius: 3.0,
                                              color: Color.fromARGB(
                                                150,
                                                0,
                                                0,
                                                0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Activity type and provider
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: primaryColor,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              widget.activity.type,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.star,
                                            color: Colors.amber[400],
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${widget.activity.rating}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (widget
                                              .activity
                                              .provider
                                              .isNotEmpty) ...[
                                            const SizedBox(width: 12),
                                            Icon(
                                              Icons.business,
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              widget.activity.provider,
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.9,
                                                ),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                          : Container(
                            color: Colors.grey[800],
                            child: Center(
                              child: Icon(
                                Icons.hiking,
                                size: 70,
                                color: Colors.white.withOpacity(0.5),
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
                      onTap: _shareActivity,
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
                          widget.activity.favoritedBy.contains(user?.uid)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              widget.activity.favoritedBy.contains(user?.uid)
                                  ? Colors.red
                                  : Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Main content - cards
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Actions
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
                            if (widget.activity.contactPhone.isNotEmpty)
                              _buildGlovoActionButton(
                                icon: Icons.call,
                                label: 'Call',
                                onTap: () async {
                                  final Uri url = Uri.parse(
                                    'tel:${widget.activity.contactPhone}',
                                  );
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url);
                                  } else {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Could not open phone: $url',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            if (widget.activity.website.isNotEmpty)
                              _buildGlovoActionButton(
                                icon: Icons.language,
                                label: 'Website',
                                onTap: () async {
                                  try {
                                    Uri url = Uri.parse(
                                      widget.activity.website,
                                    );
                                    if (url.scheme.isEmpty) {
                                      url = Uri.parse(
                                        'https://${widget.activity.website}',
                                      );
                                    }
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(
                                        url,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    } else {
                                      throw 'Could not launch $url';
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Could not open website: $e',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                              ),
                            _buildGlovoActionButton(
                              icon: Icons.bookmarks,
                              label: 'Book Now',
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => _buildBookingSheet(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Point redemption card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.card_giftcard,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Redeem with Points',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Regular price: ${widget.activity.price.toStringAsFixed(2)} MAD',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '${widget.activity.pointsRequired} pts',
                                    style: TextStyle(
                                      color: secondaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildRedeemButton(),
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
                              widget.activity.description,
                              style: TextStyle(
                                fontSize: 15,
                                color: textPrimaryColor.withOpacity(0.8),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Duration and capacity info
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.timer,
                                        size: 16,
                                        color: secondaryColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        widget.activity.duration,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: secondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (widget.activity.capacity > 0)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.people,
                                          size: 16,
                                          color: secondaryColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Up to ${widget.activity.capacity} people',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: secondaryColor,
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

                      // Inclusions & Exclusions
                      if (widget.activity.inclusions.isNotEmpty ||
                          widget.activity.exclusions.isNotEmpty)
                        _buildGlovoSectionCard(
                          title: 'What\'s Included',
                          icon: Icons.check_circle_outline,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.activity.inclusions.isNotEmpty) ...[
                                const Text(
                                  'Included:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...widget.activity.inclusions
                                    .map((item) => _buildInclusionItem(item))
                                    .toList(),
                                const SizedBox(height: 16),
                              ],
                              if (widget.activity.exclusions.isNotEmpty) ...[
                                const Text(
                                  'Not Included:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...widget.activity.exclusions
                                    .map((item) => _buildExclusionItem(item))
                                    .toList(),
                              ],
                            ],
                          ),
                        ),

                      // Location section
                      _buildGlovoSectionCard(
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
                                    widget.activity.address,
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
                                key: _mapContentKey,
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
                                onPressed: _openDirections,
                                icon: const Icon(Icons.directions),
                                label: const Text('Get Directions'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: secondaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Provider information if available
                      if (widget.activity.provider.isNotEmpty)
                        _buildGlovoSectionCard(
                          title: 'Provider',
                          icon: Icons.business,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.activity.provider,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (widget.activity.contactPhone.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.phone,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.activity.contactPhone,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (widget.activity.contactEmail.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.email,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.activity.contactEmail,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (widget.activity.website.isNotEmpty)
                                InkWell(
                                  onTap: () async {
                                    try {
                                      Uri url = Uri.parse(
                                        widget.activity.website,
                                      );
                                      if (url.scheme.isEmpty) {
                                        url = Uri.parse(
                                          'https://${widget.activity.website}',
                                        );
                                      }
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(
                                          url,
                                          mode: LaunchMode.externalApplication,
                                        );
                                      } else {
                                        throw 'Could not launch $url';
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Could not open website: $e',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.language,
                                        size: 16,
                                        color: secondaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.activity.website,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: secondaryColor,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                      // Bottom padding
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Book ${widget.activity.name}',
                        style: const TextStyle(
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

              const Divider(),

              // Booking form
              Expanded(
                child: Form(
                  key: _bookingFormKey,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Date picker
                      Text(
                        'Select Date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.calendar_today,
                            color: primaryColor,
                          ),
                          title: Text(
                            _selectedDate == null
                                ? 'Select a date'
                                : DateFormat(
                                  'EEE, MMM d, yyyy',
                                ).format(_selectedDate!),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(
                                const Duration(days: 1),
                              ),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 90),
                              ),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                _selectedDate = pickedDate;
                              });
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Time picker
                      Text(
                        'Select Time',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: Icon(Icons.access_time, color: primaryColor),
                          title: Text(
                            _selectedTime == null
                                ? 'Select a time'
                                : _selectedTime!.format(context),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () async {
                            final TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (pickedTime != null) {
                              setState(() {
                                _selectedTime = pickedTime;
                              });
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Number of people
                      Text(
                        'Number of People',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.people, color: primaryColor),
                            const SizedBox(width: 16),
                            const Text('People'),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                Icons.remove_circle_outline,
                                color: primaryColor,
                              ),
                              onPressed: () {
                                if (_peopleCount > 1) {
                                  setState(() {
                                    _peopleCount--;
                                  });
                                }
                              },
                            ),
                            Text(
                              '$_peopleCount',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.add_circle_outline,
                                color: primaryColor,
                              ),
                              onPressed: () {
                                if (_peopleCount <
                                    (widget.activity.capacity > 0
                                        ? widget.activity.capacity
                                        : 10)) {
                                  setState(() {
                                    _peopleCount++;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Contact information
                      Text(
                        'Contact Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          // Simple email validation
                          const String emailPattern =
                              r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$';
                          final RegExp regex = RegExp(emailPattern);
                          if (!regex.hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Special requests
                      Text(
                        'Special Requests (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _requestsController,
                        decoration: InputDecoration(
                          labelText: 'Any special requirements?',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),

                      const SizedBox(height: 30),

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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Activity Price'),
                                Text(
                                  '${widget.activity.price.toStringAsFixed(2)} MAD',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Points Required',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: secondaryColor,
                                  ),
                                ),
                                Text(
                                  '${widget.activity.pointsRequired} pts',
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

                      const SizedBox(height: 20),

                      // Book Now button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading 
                            ? null 
                            : () {
                                if (_bookingFormKey.currentState!.validate() &&
                                    _selectedDate != null &&
                                    _selectedTime != null) {
                                  _submitBooking();
                                } else if (_selectedDate == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please select a date'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } else if (_selectedTime == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please select a time'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Book Now',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
      },
    );
  }

  Future<void> _submitBooking() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time'), backgroundColor: Colors.red)
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to book'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Create booking DateTime by combining date and time
      final bookingDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Create booking data
      final bookingData = {
        'userId': user.uid,
        'userName': _nameController.text.isNotEmpty ? _nameController.text : user.displayName ?? 'Guest',
        'userEmail': _emailController.text.isNotEmpty ? _emailController.text : user.email ?? '',
        'userPhone': _phoneController.text,
        'activityId': widget.activity.id,
        'activityName': widget.activity.name,
        'activityImage': widget.activity.imageUrls.isNotEmpty ? widget.activity.imageUrls[0] : '',
        'date': Timestamp.fromDate(bookingDateTime),
        'participants': _peopleCount,
        'notes': _requestsController.text,
        'status': 'pending', // pending, confirmed, completed, cancelled
        'createdAt': FieldValue.serverTimestamp(),
        'cityId': widget.activity.cityId,
        'cityName': widget.activity.cityName,
        'price': widget.activity.price,
        'type': 'activity', // To distinguish from other booking types
      };

      // Save to Firestore
      await FirebaseFirestore.instance.collection('bookings').add(bookingData);

      // Close loading and booking dialog
      setState(() {
        _isLoading = false;
      });
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking confirmed for ${widget.activity.name}!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error creating booking: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRedemptionSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // GIF or Image
                Image.network(
                  'https://i.imgur.com/0RldnAP.gif', // Replace with your GIF URL
                  height: 150,
                  width: 150,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                        color: primaryColor,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.done_all,
                        size: 70,
                        color: secondaryColor,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Activity Redeemed!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: secondaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'You used ${widget.activity.pointsRequired} points to redeem ${widget.activity.name}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.confirmation_number, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Booking #${DateTime.now().millisecondsSinceEpoch.toString().substring(7, 13)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Great!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _isActivityAlreadyRedeemed() async {
    if (user == null) return false;
    
    try {
      // Check if there's a record in the redemptions collection for this user and activity
      final QuerySnapshot redemptionSnapshot = await FirebaseFirestore.instance
          .collection('redemptions')
          .where('userId', isEqualTo: user!.uid)
          .where('activityId', isEqualTo: widget.activity.id)
          .limit(1)
          .get();
          
      // Also check if there's a booking record for this activity
      final QuerySnapshot bookingSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user!.uid)
          .where('activityId', isEqualTo: widget.activity.id)
          .where('type', isEqualTo: 'activity')
          .limit(1)
          .get();
          
      // If either exists, the activity has been redeemed
      return redemptionSnapshot.docs.isNotEmpty || bookingSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking redemption status: $e');
      return false;
    }
  }
}
