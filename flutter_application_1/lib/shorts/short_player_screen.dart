import 'package:flutter/material.dart';
import 'package:flutter_application_1/shorts/short_model.dart';
import 'package:flutter_application_1/shorts/shorts_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class ShortPlayerScreen extends StatefulWidget {
  final List<Short> shorts;
  final int initialIndex;

  const ShortPlayerScreen({
    Key? key,
    required this.shorts,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<ShortPlayerScreen> createState() => _ShortPlayerScreenState();
}

class _ShortPlayerScreenState extends State<ShortPlayerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  final ShortsService _shortsService = ShortsService();
  final FirebaseAuth _auth = FirebaseAuth.instance; // Define _auth here
  int _currentIndex = 0;
  Map<int, AnimationController> _animationControllers = {};
  Map<int, bool> _isLiked = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    // Remove all animations
    // _initAnimationController(_currentIndex);

    // Check if current short is liked
    _checkLikeStatus(_currentIndex);
  }

  // We'll keep this method but it won't do anything now
  void _initAnimationController(int index) {
    // No animations anymore
  }

  void _onPageChanged(int index) {
    // No animation to stop or start

    // Check like status
    _checkLikeStatus(index);

    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _checkLikeStatus(int index) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final short = widget.shorts[index];
    final isLiked = short.likedBy.contains(user.uid);

    setState(() {
      _isLiked[index] = isLiked;
    });
  }

  Future<void> _toggleLike(int index) async {
    if (_auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to like shorts')),
      );
      return;
    }

    final short = widget.shorts[index];
    final currentLikeState = _isLiked[index] ?? false;
    final userId = _auth.currentUser!.uid;

    // Store the original likedBy list before any changes
    final originalLikedBy = List<String>.from(short.likedBy);

    try {
      // Immediately update UI
      setState(() {
        // Toggle like state
        _isLiked[index] = !currentLikeState;

        if (!currentLikeState) {
          // Add user to likedBy if not already there
          if (!short.likedBy.contains(userId)) {
            short.likedBy.add(userId);
          }
        } else {
          // Remove user from likedBy
          short.likedBy.remove(userId);
        }
      });

      // Update in background with better error handling
      final success = await _shortsService.toggleLike(short.id);

      if (!success) {
        // If server update failed, revert UI
        _revertLikeState(index, currentLikeState, originalLikedBy);
        _showErrorMessage("Unable to update like");
      }
    } catch (error) {
      print("Like error: $error");

      // Revert UI if there was an exception
      _revertLikeState(index, currentLikeState, originalLikedBy);

      // Show error to user
      _showErrorMessage("Permission denied: You cannot like/unlike this short");
    }
  }

  // Helper to revert like state
  void _revertLikeState(
    int index,
    bool originalState,
    List<String> originalLikedBy,
  ) {
    setState(() {
      _isLiked[index] = originalState;
      widget.shorts[index].likedBy.clear();
      widget.shorts[index].likedBy.addAll(originalLikedBy);
    });
  }

  // Helper to show error messages
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Clean up any remaining controllers
    _animationControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Add this to pass back the updated shorts data when user goes back
      onWillPop: () async {
        // Pass updated shorts back to previous screen
        Navigator.pop(context, widget.shorts);
        return false; // We handle the pop ourselves
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          onPageChanged: _onPageChanged,
          itemCount: widget.shorts.length,
          itemBuilder: (context, index) {
            final short = widget.shorts[index];

            return Stack(
              fit: StackFit.expand,
              children: [
                // Image without animation
                GestureDetector(
                  onTap: () {
                    // Nothing to pause/play anymore
                  },
                  child: FutureBuilder<Uint8List>(
                    // Decode base64 outside the build method
                    future: compute(_decodeBase64Image, short.imageBase64),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        );
                      } else if (snapshot.hasError || !snapshot.hasData) {
                        return Container(
                          color: Colors.black,
                          child: const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 50,
                          ),
                        );
                      } else {
                        return Image.memory(
                          snapshot.data!,
                          fit:
                              BoxFit
                                  .contain, // Use contain to show full image without cropping
                          frameBuilder: (
                            context,
                            child,
                            frame,
                            wasSynchronouslyLoaded,
                          ) {
                            return child;
                          },
                          cacheWidth:
                              1080, // Add width constraint for memory efficiency
                        );
                      }
                    },
                  ),
                ),

                // Gradient overlay for better text visibility
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                      stops: const [0.0, 0.2, 0.8, 1.0],
                    ),
                  ),
                ),

                // User info at bottom
                Positioned(
                  bottom: 60,
                  left: 16,
                  right: 60,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username and profile pic
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey[800],
                            backgroundImage: short.userProfileUrl.isNotEmpty
                                ? (short.isProfileImageBase64
                                    ? MemoryImage(
                                        base64Decode(short.userProfileUrl))
                                    : NetworkImage(short.userProfileUrl)) as ImageProvider
                                : null,
                            child: short.userProfileUrl.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            short.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Caption
                      Text(
                        short.caption,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // City
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            short.cityName,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions sidebar
                Positioned(
                  right: 16,
                  bottom: 100,
                  child: Column(
                    children: [
                      // Like button
                      IconButton(
                        onPressed: () => _toggleLike(index),
                        icon: Icon(
                          _isLiked[index] == true
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color:
                              _isLiked[index] == true ? Colors.red : Colors.white,
                          size: 28,
                        ),
                      ),
                      Text(
                        // Show immediately updated count based on likedBy array length
                        '${short.likedBy.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 20),

                      // Comment button (placeholder)
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Comments not implemented'),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.comment,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const Text('0', style: TextStyle(color: Colors.white)),
                      const SizedBox(height: 20),

                      // Share button
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Share functionality not implemented',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.share,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),

                // Back button and counter at top
                Positioned(
                  top: 40,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${index + 1}/${widget.shorts.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Helper function for base64 decoding
  static Uint8List _decodeBase64Image(String base64String) {
    return base64Decode(base64String);
  }
}
