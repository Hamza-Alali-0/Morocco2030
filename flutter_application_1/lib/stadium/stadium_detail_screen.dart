import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/stadium/stadium_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter_application_1/stadium/stadium_service.dart';

import 'package:flutter_application_1/stadium/stadium_booking_screen.dart';

class StadiumDetailScreen extends StatefulWidget {
  final Stadium stadium;

  const StadiumDetailScreen({Key? key, required this.stadium})
    : super(key: key);

  @override
  State<StadiumDetailScreen> createState() => _StadiumDetailScreenState();
}

class _StadiumDetailScreenState extends State<StadiumDetailScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  final Color primaryColor = const Color(0xFFFDCB00);
  final Color secondaryColor = const Color(0xFF065d67);
  bool _isFavorite = false;
  final StadiumService _stadiumService = StadiumService();

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _checkFavoriteStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && widget.stadium != null) {
      setState(() {
        _isFavorite = widget.stadium.favoritedBy.contains(user.uid);
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to favorite stadiums')),
      );
      return;
    }

    try {
      await _stadiumService.toggleFavorite(
        widget.stadium.id,
        user.uid,
        _isFavorite,
      );

      setState(() {
        _isFavorite = !_isFavorite;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite ? 'Added to favorites' : 'Removed from favorites',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating favorite status')),
      );
    }
  }

  Future<void> _openInMaps() async {
    try {
      final latitude = widget.stadium.location.latitude;
      final longitude = widget.stadium.location.longitude;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStadiumInfoCard(),
                _buildDescriptionSection(),
                _buildAmenitiesSection(),
                _buildMapSection(),
                const SizedBox(
                  height: 20,
                ), // Just add some padding at the bottom
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount:
                  widget.stadium.imageUrls.isEmpty
                      ? 1
                      : widget.stadium.imageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              physics:
                  const BouncingScrollPhysics(), // Add this line for better physics
              pageSnapping: true, // Ensure pages snap into place
              itemBuilder: (context, index) {
                if (widget.stadium.imageUrls.isEmpty) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.stadium,
                        size: 80,
                        color: Colors.white70,
                      ),
                    ),
                  );
                }

                return widget.stadium.imageUrls[index].startsWith('data:image')
                    ? Builder(
                      builder: (context) {
                        try {
                          // Safe base64 splitting and decoding with error handling
                          final parts = widget.stadium.imageUrls[index].split(
                            ',',
                          );
                          if (parts.length < 2) {
                            // Invalid format, show error placeholder
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.broken_image,
                                size: 80,
                                color: Colors.white70,
                              ),
                            );
                          }

                          final base64Str = parts[1];
                          return Image.memory(
                            base64Decode(base64Str),
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 80,
                                    color: Colors.white70,
                                  ),
                                ),
                          );
                        } catch (e) {
                          print('Error decoding base64 image: $e');
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.broken_image,
                              size: 80,
                              color: Colors.white70,
                            ),
                          );
                        }
                      },
                    )
                    : CachedNetworkImage(
                      imageUrl: widget.stadium.imageUrls[index],
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Center(
                            child: CircularProgressIndicator(
                              color: primaryColor,
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.broken_image,
                              size: 80,
                              color: Colors.white70,
                            ),
                          ),
                    );
              },
            ),
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
            if (widget.stadium.imageUrls.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.stadium.imageUrls.length,
                    (index) => Container(
                      width:
                          _currentImageIndex == index
                              ? 12
                              : 8, // Make current indicator larger
                      height: _currentImageIndex == index ? 12 : 8,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                      ), // Increase spacing
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _currentImageIndex == index
                                ? primaryColor
                                : Colors.white.withOpacity(
                                  0.7,
                                ), // More opaque for better visibility
                        border: Border.all(
                          color: Colors.black.withOpacity(0.2),
                        ), // Add border for contrast
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.stadium.imageUrls.length > 1)
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
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            // Loop to last image when at the beginning
                            _pageController.animateToPage(
                              widget.stadium.imageUrls.length - 1,
                              duration: const Duration(milliseconds: 300),
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

                    // Expanded middle area to keep arrows on the sides
                    Expanded(child: Container()),

                    // Right arrow
                    Container(
                      width: 40,
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          if (_currentImageIndex <
                              widget.stadium.imageUrls.length - 1) {
                            _pageController.animateToPage(
                              _currentImageIndex + 1,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            // Loop to first image when at the end
                            _pageController.animateToPage(
                              0,
                              duration: const Duration(milliseconds: 300),
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
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            widget.stadium.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              shadows: [
                Shadow(
                  color: Colors.white,
                  offset: Offset(1, 1),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black26,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.white,
            ),
          ),
          onPressed: _toggleFavorite,
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share, color: Colors.white),
          ),
          onPressed: () {
            // Share functionality would go here
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Share functionality not implemented'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStadiumInfoCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.category, color: secondaryColor),
                    const SizedBox(width: 8),
                    Text(
                      widget.stadium.type,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.stadium.rating}',
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
            const Divider(height: 24),
            _buildInfoRow(Icons.location_on, widget.stadium.address),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.people, '${widget.stadium.capacity} capacity'),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.update,
              'Last updated: ${DateFormat('MMM d, yyyy').format(widget.stadium.lastUpdated)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 15, color: Colors.grey[800]),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: secondaryColor),
              const SizedBox(width: 8),
              Text(
                'About this stadium',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: secondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.stadium.description.isEmpty
                ? 'No description available for this stadium.'
                : widget.stadium.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection() {
    if (widget.stadium.amenities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_activity, color: secondaryColor),
              const SizedBox(width: 8),
              Text(
                'Amenities',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: secondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                widget.stadium.amenities.map((amenity) {
                  return Chip(
                    backgroundColor: secondaryColor.withOpacity(0.1),
                    side: BorderSide(color: secondaryColor.withOpacity(0.2)),
                    avatar: Icon(
                      _getAmenityIcon(amenity),
                      size: 16,
                      color: secondaryColor,
                    ),
                    label: Text(
                      amenity,
                      style: TextStyle(fontSize: 12, color: secondaryColor),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: secondaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: secondaryColor, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: secondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.stadium.address,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _openInMaps,
                  icon: const Icon(Icons.directions),
                  label: const Text('Get Directions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                // Add Book a Seat button
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                StadiumBookingScreen(stadium: widget.stadium),
                      ),
                    );
                  },
                  icon: const Icon(Icons.event_seat),
                  label: const Text('Book a seat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(
                      double.infinity,
                      0,
                    ), // Make button full width
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Lat: ${widget.stadium.location.latitude.toStringAsFixed(6)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Lng: ${widget.stadium.location.longitude.toStringAsFixed(6)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'parking':
        return Icons.local_parking;
      case 'food court':
        return Icons.restaurant;
      case 'wifi':
        return Icons.wifi;
      case 'locker rooms':
        return Icons.meeting_room;
      case 'vip boxes':
        return Icons.star;
      case 'disabled access':
        return Icons.accessible;
      case 'first aid':
        return Icons.local_hospital;
      case 'gift shop':
        return Icons.shopping_bag;
      case 'tour':
        return Icons.tour;
      default:
        return Icons.check_circle_outline;
    }
  }
}
