import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/monument/monument_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter_application_1/monument/monument_service.dart';

class MonumentDetailScreen extends StatefulWidget {
  final Monument monument;

  const MonumentDetailScreen({Key? key, required this.monument})
    : super(key: key);

  @override
  State<MonumentDetailScreen> createState() => _MonumentDetailScreenState();
}

class _MonumentDetailScreenState extends State<MonumentDetailScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  final Color primaryColor = const Color(0xFFFDCB00);
  final Color secondaryColor = const Color(0xFF065d67);
  bool _isFavorite = false;
  final MonumentService _monumentService = MonumentService();

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
    if (user != null && widget.monument != null) {
      setState(() {
        _isFavorite = widget.monument.favoritedBy.contains(user.uid);
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to favorite monuments')),
      );
      return;
    }

    try {
      await _monumentService.toggleFavorite(
        widget.monument.id,
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
      final latitude = widget.monument.location.latitude;
      final longitude = widget.monument.location.longitude;

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
                _buildMonumentInfoCard(),
                _buildDescriptionSection(),
                _buildFeaturesSection(),
                _buildMapSection(),
                const SizedBox(height: 20),
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
                  widget.monument.imageUrls.isEmpty
                      ? 1
                      : widget.monument.imageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              physics: const BouncingScrollPhysics(),
              pageSnapping: true,
              itemBuilder: (context, index) {
                if (widget.monument.imageUrls.isEmpty) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.account_balance,
                        size: 80,
                        color: Colors.white70,
                      ),
                    ),
                  );
                }

                return widget.monument.imageUrls[index].startsWith('data:image')
                    ? Builder(
                      builder: (context) {
                        try {
                          final parts = widget.monument.imageUrls[index].split(
                            ',',
                          );
                          if (parts.length < 2) {
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
                      imageUrl: widget.monument.imageUrls[index],
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
            if (widget.monument.imageUrls.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.monument.imageUrls.length,
                    (index) => Container(
                      width:
                          _currentImageIndex == index
                              ? 12
                              : 8,
                      height: _currentImageIndex == index ? 12 : 8,
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
                          color: Colors.black.withOpacity(0.2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.monument.imageUrls.length > 1)
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
                              widget.monument.imageUrls.length - 1,
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
                              widget.monument.imageUrls.length - 1) {
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
            widget.monument.name,
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

  Widget _buildMonumentInfoCard() {
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
                      widget.monument.type,
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
                        widget.monument.rating.toStringAsFixed(1),
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
            _buildInfoRow(Icons.location_on, widget.monument.address),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.date_range,
              'Built in: ${widget.monument.yearBuilt > 0 ? widget.monument.yearBuilt.toString() : "Unknown"}',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.access_time,
              'Hours: ${widget.monument.openingHours}',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.monetization_on,
              'Fee: ${widget.monument.entranceFee > 0 ? "${widget.monument.entranceFee} MAD" : "Free"}',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.verified_user,
              'Status: ${widget.monument.isOpen ? "Open to public" : "Closed to public"}',
              iconColor: widget.monument.isOpen ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? iconColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor ?? Colors.grey[600]),
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
                'About this monument',
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
            widget.monument.description.isEmpty
                ? 'No description available for this monument.'
                : widget.monument.description,
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

  Widget _buildFeaturesSection() {
    // Check if we have any features to display
    if (!widget.monument.hasVirtualTour && 
        !widget.monument.isAccessible && 
        !widget.monument.hasGuidedTours) {
      return const SizedBox.shrink();
    }

    List<String> features = [];
    if (widget.monument.hasVirtualTour) features.add('Virtual Tour');
    if (widget.monument.isAccessible) features.add('Wheelchair Accessible');
    if (widget.monument.hasGuidedTours) features.add('Guided Tours');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: secondaryColor),
              const SizedBox(width: 8),
              Text(
                'Features',
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
            children: features.map((feature) {
              return Chip(
                backgroundColor: secondaryColor.withOpacity(0.1),
                side: BorderSide(color: secondaryColor.withOpacity(0.2)),
                avatar: Icon(
                  _getFeatureIcon(feature),
                  size: 16,
                  color: secondaryColor,
                ),
                label: Text(
                  feature,
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
                  widget.monument.address,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 16),
                // Map placeholder instead of Google Maps widget
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map, 
                        size: 48, 
                        color: Colors.grey[400]
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Map preview not available',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Click below to view in Google Maps',
                        style: TextStyle(
                          color: Colors.grey[500], 
                          fontSize: 12
                        ),
                      ),
                    ],
                  ),
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
                    minimumSize: const Size(double.infinity, 0),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Lat: ${widget.monument.location.latitude.toStringAsFixed(6)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Lng: ${widget.monument.location.longitude.toStringAsFixed(6)}',
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

  IconData _getFeatureIcon(String feature) {
    switch (feature.toLowerCase()) {
      case 'virtual tour':
        return Icons.view_in_ar;
      case 'wheelchair accessible':
        return Icons.accessible;
      case 'guided tours':
        return Icons.tour;
      default:
        return Icons.check_circle_outline;
    }
  }
}