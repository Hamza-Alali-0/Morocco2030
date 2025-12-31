import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/shorts/short_model.dart';
import 'package:flutter_application_1/shorts/short_player_screen.dart';
import 'dart:convert';

class ShortThumbnail extends StatefulWidget {
  final Short short;
  final List<Short> allShorts;
  final int index;

  const ShortThumbnail({
    Key? key,
    required this.short,
    required this.allShorts,
    required this.index,
  }) : super(key: key);

  @override
  State<ShortThumbnail> createState() => _ShortThumbnailState();
}

class _ShortThumbnailState extends State<ShortThumbnail>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _scaleAnimation = _getAnimationForType(widget.short.animationType);

    // No auto-animation - images will display properly
    // Animation will only happen on interaction
  }

  Animation<double> _getAnimationForType(String type) {
    switch (type) {
      case 'zoom':
        return Tween<double>(begin: 1.0, end: 1.1).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
      case 'pulse':
        return TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 1.05),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.05, end: 1.0),
            weight: 1,
          ),
        ]).animate(_animationController);
      case 'pan':
        return Tween<double>(
          begin: 1.0,
          end: 1.0,
        ).animate(_animationController);
      default:
        return Tween<double>(
          begin: 1.0,
          end: 1.05,
        ).animate(_animationController);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ShortPlayerScreen(
                    shorts: widget.allShorts,
                    initialIndex: widget.index,
                  ),
            ),
          );
        },
        onTapDown: (_) => _animationController.forward(),
        onTapCancel: () => _animationController.reverse(),
        onTapUp: (_) => _animationController.reverse(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Animated Thumbnail - Avec une transformation réelle
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    // Add debug print and ensure proper error handling
                    child:
                        widget.short.imageBase64.isNotEmpty
                            ? Image.memory(
                              base64Decode(widget.short.imageBase64),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print('Image error: $error');
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 40,
                                  ),
                                );
                              },
                            )
                            : Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 40,
                              ),
                            ),
                  );
                },
              ),
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
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
                  CircleAvatar(
                    radius: 12,
                    backgroundImage:
                        widget.short.userProfileUrl.isNotEmpty
                            ? (widget.short.isProfileImageBase64
                                    ? MemoryImage(
                                      base64Decode(widget.short.userProfileUrl),
                                    )
                                    : NetworkImage(widget.short.userProfileUrl))
                                as ImageProvider
                            : null,
                    child:
                        widget.short.userProfileUrl.isEmpty
                            ? const Icon(Icons.person, size: 12)
                            : null,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.short.userName,
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
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.white, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        '${widget.short.likesCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
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

  IconData _getAnimationIcon(String type) {
    switch (type) {
      case 'zoom':
        return Icons.zoom_in;
      case 'pulse':
        return Icons.favorite;
      case 'pan':
        return Icons.swipe;
      default:
        return Icons.play_arrow;
    }
  }

  String _getAnimationName(String type) {
    switch (type) {
      case 'zoom':
        return 'Zoom';
      case 'pulse':
        return 'Pulse';
      case 'pan':
        return 'Pan';
      default:
        return 'Animated';
    }
  }
}
