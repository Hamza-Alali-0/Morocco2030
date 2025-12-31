import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/authentification/login_page.dart';
import 'package:flutter_application_1/home_page.dart';
import 'package:flutter_application_1/onboarding/onboarding_screen.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({Key? key}) : super(key: key);

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;
  late Animation<double> _scale;
  
  final Color primaryColor = const Color(0xFFFDCB00); // Yellow
  final Color secondaryColor = const Color(0xFF065d67); // Teal

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _rotation = Tween<double>(begin: 0, end: 1.0).animate(  // Changed from 0.5 to 1.0 for full 360° rotation
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _controller.forward().then((_) => _navigateToNextScreen());
  }

  Future<void> _navigateToNextScreen() async {
    // Check onboarding status
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboardingComplete') ?? false;

    if (!mounted) return;

    if (!onboardingComplete) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen())
      );
    } else {
      // Check authentication status
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MyHomePage())
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage())
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    // Calculate a responsive size that maintains aspect ratio
    final double logoSize = screenSize.width * 0.5; // 50% of screen width
    
    return Scaffold(
      backgroundColor: primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated logo
            RotationTransition(
              turns: _rotation,
              child: ScaleTransition(
                scale: _scale,
                child: Image.asset(
                  'assets/images/logomaroc2030.png',
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Animated text
            FadeTransition(
              opacity: _controller,
              child: Text(
                'Morocco 2030',
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}