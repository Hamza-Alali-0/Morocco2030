import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/guide/guide_model.dart';
import 'package:flutter_application_1/guide/guide_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class GuideDetailScreen extends StatefulWidget {
  final Guide guide;

  const GuideDetailScreen({Key? key, required this.guide}) : super(key: key);

  @override
  State<GuideDetailScreen> createState() => _GuideDetailScreenState();
}

class _GuideDetailScreenState extends State<GuideDetailScreen>
    with SingleTickerProviderStateMixin {
  final GuideService _guideService = GuideService();
  final ScrollController _scrollController = ScrollController();
  final user = FirebaseAuth.instance.currentUser;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Theme colors - updated for a more modern palette
  final Color primaryColor = const Color(0xFFFDCB00);
  final Color secondaryColor = const Color(0xFF065d67);
  final Color accentColor = const Color(0xFF19B5FE);
  final Color backgroundColor = const Color(0xFFF9FAFB);
  final Color cardColor = Colors.white;
  final Color textPrimaryColor = const Color(0xFF212121);
  final Color textSecondaryColor = const Color(0xFF78909C);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    if (user == null) {
      _showSnackbar('Please sign in to favorite guides');
      return;
    }

    try {
      bool isFavorited = widget.guide.favoritedBy.contains(user!.uid);
      await _guideService.toggleFavorite(
        widget.guide.id,
        user!.uid,
        isFavorited,
      );

      setState(() {
        if (isFavorited) {
          widget.guide.favoritedBy.remove(user!.uid);
          _showSnackbar('Removed from favorites', isSuccess: false);
        } else {
          widget.guide.favoritedBy.add(user!.uid);
          _showSnackbar('Added to favorites', isSuccess: true);
        }
      });
    } catch (e) {
      _showSnackbar('Error updating favorites', isSuccess: false);
    }
  }

  void _showSnackbar(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green[400] : Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _contactGuide() async {
    try {
      final Uri url = Uri.parse('tel:${widget.guide.phoneNumber}');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (e) {
      _showSnackbar('Could not launch phone app', isSuccess: false);
    }
  }

  Future<void> _emailGuide() async {
    try {
      final Uri url = Uri.parse('mailto:${widget.guide.email}');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (e) {
      _showSnackbar('Could not launch email app', isSuccess: false);
    }
  }

  void _openImageGallery(int initialIndex) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => GalleryScreen(
              imageUrls: widget.guide.imageUrls,
              initialIndex: initialIndex,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = const Offset(0.0, 1.0);
          var end = Offset.zero;
          var curve = Curves.ease;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  ImageProvider _getImageProvider(String imageSource) {
    if (imageSource.startsWith('data:image') ||
        RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(imageSource)) {
      String base64String =
          imageSource.startsWith('data:image')
              ? imageSource.split(',')[1]
              : imageSource;
      try {
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        return const AssetImage('assets/images/placeholder.png');
      }
    } else {
      return CachedNetworkImageProvider(imageSource);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildModernAppBar(),
                SliverToBoxAdapter(child: _buildContent()),
              ],
            ),
            _buildBookingBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    String headerImage =
        widget.guide.profileImageUrl.isNotEmpty
            ? widget.guide.profileImageUrl
            : widget.guide.imageUrls.isNotEmpty
            ? widget.guide.imageUrls.first
            : '';

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Header image
            headerImage.isNotEmpty
                ? _buildHeaderImage(headerImage)
                : Container(color: secondaryColor),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                ),
              ),
            ),

            // Guide info overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.guide.fullName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10,
                                      color: Colors.black45,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      widget.guide.specialization,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          widget.guide.rating.toString(),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
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
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: _buildBackButton(),
      actions: [_buildFavoriteButton()],
    );
  }

  Widget _buildHeaderImage(String imageUrl) {
    return Hero(
      tag: 'guide_header_${widget.guide.id}',
      child:
          imageUrl.startsWith('data:image') ||
                  RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(imageUrl)
              ? _buildBase64Image(imageUrl)
              : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Container(
                      color: secondaryColor,
                      child: Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      ),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      color: secondaryColor,
                      child: const Icon(
                        Icons.error_outline,
                        size: 50,
                        color: Colors.white54,
                      ),
                    ),
              ),
    );
  }

  Widget _buildBase64Image(String base64String) {
    try {
      String data =
          base64String.startsWith('data:image')
              ? base64String.split(',')[1]
              : base64String;
      return Image.memory(
        base64Decode(data),
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => Container(
              color: secondaryColor,
              child: const Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.white54,
              ),
            ),
      );
    } catch (e) {
      return Container(
        color: secondaryColor,
        child: const Icon(Icons.error_outline, size: 50, color: Colors.white54),
      );
    }
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    bool isFavorited = widget.guide.favoritedBy.contains(user?.uid);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                isFavorited ? Icons.favorite : Icons.favorite_border,
                color: isFavorited ? Colors.red : Colors.white,
              ),
              onPressed: _toggleFavorite,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return AnimationLimiter(
      child: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 600),
            childAnimationBuilder:
                (widget) => SlideAnimation(
                  horizontalOffset: 50.0,
                  child: FadeInAnimation(child: widget),
                ),
            children: [
              _buildQuickInfoCard(),
              if (widget.guide.imageUrls.isNotEmpty) _buildGallerySection(),
              _buildAboutSection(),
              _buildLanguagesSection(),
              _buildProgramSection(),
              _buildRateSection(),
              _buildContactSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                _buildInfoItem(
                  Icons.work_outlined,
                  "${widget.guide.yearsOfExperience} years",
                  "Experience",
                ),
                _buildDivider(),
                _buildInfoItem(
                  Icons.school_outlined,
                  widget.guide.educationLevel,
                  "Education",
                ),
                _buildDivider(),
                _buildInfoItem(
                  Icons.language,
                  "${widget.guide.languages.length}",
                  "Languages",
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildContactButton(
                    icon: Icons.call,
                    label: 'Call',
                    onTap: _contactGuide,
                    isPrimary: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildContactButton(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    onTap: _emailGuide,
                    isPrimary: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: secondaryColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textPrimaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: textSecondaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 40, width: 1, color: Colors.grey.shade300);
  }

  Widget _buildGallerySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              'Gallery',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimaryColor,
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              scrollDirection: Axis.horizontal,
              itemCount: widget.guide.imageUrls.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: GestureDetector(
                    onTap: () => _openImageGallery(index),
                    child: Container(
                      width: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: _buildGalleryImage(
                          widget.guide.imageUrls[index],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryImage(String imageSource) {
    if (imageSource.startsWith('data:image') ||
        RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(imageSource)) {
      String base64String =
          imageSource.startsWith('data:image')
              ? imageSource.split(',')[1]
              : imageSource;
      try {
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          height: double.infinity,
          width: double.infinity,
        );
      } catch (e) {
        return _buildImageErrorPlaceholder();
      }
    } else {
      return CachedNetworkImage(
        imageUrl: imageSource,
        fit: BoxFit.cover,
        height: double.infinity,
        width: double.infinity,
        placeholder:
            (context, url) =>
                Center(child: CircularProgressIndicator(color: primaryColor)),
        errorWidget: (context, url, error) => _buildImageErrorPlaceholder(),
      );
    }
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: secondaryColor, size: 24),
                const SizedBox(width: 10),
                Text(
                  'About',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              widget.guide.description,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: textPrimaryColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguagesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.translate, color: secondaryColor, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Languages',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children:
                  widget.guide.languages.map((language) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        language,
                        style: TextStyle(
                          color: secondaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tour_outlined, color: secondaryColor, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Guide Program',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.guide.activities.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check, color: primaryColor, size: 14),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.guide.activities[index],
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: textPrimaryColor.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.monetization_on_outlined,
                  color: secondaryColor,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'Rate',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.payments_outlined,
                      color: Colors.black87,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hourly Rate',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.guide.hourlyRate.toStringAsFixed(2)} MAD/hr',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: textSecondaryColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Prices may vary based on group size, duration, and specific requirements.',
                      style: TextStyle(fontSize: 14, color: textSecondaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.contact_phone_outlined,
                  color: secondaryColor,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'Contact',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildContactTile(
              Icons.phone_outlined,
              'Phone',
              widget.guide.phoneNumber,
              _contactGuide,
            ),
            Divider(color: Colors.grey.shade200, thickness: 1, height: 30),
            _buildContactTile(
              Icons.email_outlined,
              'Email',
              widget.guide.email,
              _emailGuide,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: secondaryColor, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 14, color: textSecondaryColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: secondaryColor, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? primaryColor : Colors.grey.shade100,
        foregroundColor: isPrimary ? Colors.black87 : secondaryColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side:
              isPrimary
                  ? BorderSide.none
                  : BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () => _showGuideBookingDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'BOOK THIS GUIDE',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageErrorPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey[400],
          size: 24,
        ),
      ),
    );
  }

  void _showGuideBookingDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    int numberOfPeople = 2;
    int durationHours = 3;
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
                                'Book Tour Guide',
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

                      // Guide info preview
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.grey[100]),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildGuideDialogImage(
                                widget.guide.profileImageUrl.isNotEmpty
                                    ? widget.guide.profileImageUrl
                                    : widget.guide.imageUrls.isNotEmpty
                                    ? widget.guide.imageUrls[0]
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
                                    widget.guide.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.guide.languages.join(", "),
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 16,
                                        color: primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.guide.rating.toString(),
                                        style: TextStyle(
                                          color: Colors.grey[700],
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
                                    lastDate: DateTime.now().add(
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
                                      picked != selectedDate) {
                                    setState(() {
                                      selectedDate = picked;
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
                                        _formatDate(selectedDate),
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

                              // Time selector
                              Text(
                                'Select Start Time',
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
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 4,
                                      childAspectRatio: 2.0,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                    ),
                                itemCount:
                                    8, // Show 8 time slots (morning to afternoon)
                                itemBuilder: (context, index) {
                                  // Generate time slots from 9:00 AM to 4:00 PM
                                  final hour = 9 + index;
                                  final timeSlot = TimeOfDay(
                                    hour: hour,
                                    minute: 0,
                                  );
                                  final isSelected =
                                      timeSlot.hour == selectedTime.hour &&
                                      timeSlot.minute == selectedTime.minute;

                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        selectedTime = timeSlot;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? primaryColor
                                                : Colors.transparent,
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? primaryColor
                                                  : Colors.grey[300]!,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _formatTimeOfDay(timeSlot),
                                          style: TextStyle(
                                            color:
                                                isSelected
                                                    ? Colors.black87
                                                    : Colors.grey[800],
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 24),

                              // Duration selector
                              Text(
                                'Tour Duration',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: secondaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Duration slider
                              Column(
                                children: [
                                  Slider(
                                    value: durationHours.toDouble(),
                                    min: 1,
                                    max: 8,
                                    divisions: 7,
                                    activeColor: primaryColor,
                                    inactiveColor: Colors.grey[300],
                                    label:
                                        '$durationHours hour${durationHours > 1 ? 's' : ''}',
                                    onChanged: (value) {
                                      setState(() {
                                        durationHours = value.toInt();
                                      });
                                    },
                                  ),
                                  Text(
                                    '$durationHours hour${durationHours > 1 ? 's' : ''} tour',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: secondaryColor,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Number of people
                              Text(
                                'Number of People',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: secondaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // People counter with +/- buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed:
                                        numberOfPeople > 1
                                            ? () =>
                                                setState(() => numberOfPeople--)
                                            : null,
                                    icon: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              numberOfPeople > 1
                                                  ? secondaryColor
                                                  : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.remove,
                                        size: 18,
                                        color:
                                            numberOfPeople > 1
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
                                      numberOfPeople.toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed:
                                        numberOfPeople < 20
                                            ? () =>
                                                setState(() => numberOfPeople++)
                                            : null,
                                    icon: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              numberOfPeople < 20
                                                  ? secondaryColor
                                                  : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        size: 18,
                                        color:
                                            numberOfPeople < 20
                                                ? secondaryColor
                                                : Colors.grey[300],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),
                              Text(
                                'Special requests or interests (optional)',
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
                                      'Example: Specific attractions, accessibility needs, languages...',
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

                      // Total price calculator
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border(
                            top: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estimated Total:',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                Text(
                                  '${(widget.guide.hourlyRate * durationHours).toStringAsFixed(2)} MAD',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: secondaryColor,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${widget.guide.hourlyRate.toStringAsFixed(0)} MAD x $durationHours hrs',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
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
                                      content: Text(
                                        'Please sign in to book a guide',
                                      ),
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

                                // Calculate end time
                                final endDateTime = bookingDateTime.add(
                                  Duration(hours: durationHours),
                                );

                                // Get notes
                                final notes = notesController.text.trim();

                                // Create booking data
                                final bookingData = {
                                  'userId': user.uid,
                                  'userName': user.displayName ?? 'Guest',
                                  'userEmail': user.email ?? '',
                                  'guideId': widget.guide.id,
                                  'guideName': widget.guide.fullName,
                                  'guideProfileImage':
                                      widget
                                          .guide
                                          .profileImageUrl, // Add this line
                                  'date': Timestamp.fromDate(bookingDateTime),
                                  'endTime': Timestamp.fromDate(endDateTime),
                                  'duration': durationHours,
                                  'people': numberOfPeople,
                                  'totalPrice':
                                      widget.guide.hourlyRate * durationHours,
                                  'notes': notes,
                                  'status':
                                      'pending', // pending, confirmed, completed, cancelled
                                  'createdAt': Timestamp.now(),
                                  'cityId': widget.guide.cityId,
                                  'type':
                                      'guide', // To distinguish from restaurant bookings
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
                                      'Guide booked for ${_formatDate(selectedDate)} at ${_formatTimeOfDay(selectedTime)}',
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
                                    content: Text(
                                      'Booking failed: ${e.toString()}',
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                print('Error booking guide: $e');
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
                              'BOOK GUIDE',
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

  Widget _buildGuideDialogImage(
    String imageSource, {
    required double width,
    required double height,
  }) {
    if (imageSource.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.person, color: Colors.grey),
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
                child: const Icon(Icons.person, color: Colors.grey),
              ),
        );
      } catch (e) {
        print('Error decoding base64 guide image: $e');
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.person, color: Colors.grey),
        );
      }
    } else {
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
              child: const Icon(Icons.person, color: Colors.grey),
            ),
      );
    }
  }

  // Helper methods for date and time formatting
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} (${_getDayName(date.weekday)})';
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

class GalleryScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const GalleryScreen({
    Key? key,
    required this.imageUrls,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  ImageProvider _getImageProvider(String imageSource) {
    if (imageSource.startsWith('data:image') ||
        RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(imageSource)) {
      String base64String =
          imageSource.startsWith('data:image')
              ? imageSource.split(',')[1]
              : imageSource;
      try {
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        return const AssetImage('assets/images/placeholder.png');
      }
    } else {
      return CachedNetworkImageProvider(imageSource);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1}/${widget.imageUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            pageController: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: _getImageProvider(widget.imageUrls[index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                heroAttributes: PhotoViewHeroAttributes(
                  tag: "gallery_${widget.imageUrls[index]}",
                ),
              );
            },
            loadingBuilder:
                (context, event) => Center(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      value:
                          event == null
                              ? 0
                              : event.cumulativeBytesLoaded /
                                  (event.expectedTotalBytes ?? 100),
                    ),
                  ),
                ),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ],
      ),
    );
  }
}
