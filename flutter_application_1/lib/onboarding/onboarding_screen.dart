import 'package:flutter/material.dart';
import 'package:flutter_application_1/authentification/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _buttonAnimation;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': "Welcome to Morocco 2030",
      'description':
          "Your essential companion for the FIFA World Cup 2030. Discover everything Morocco has to offer during this global celebration.",
      'image': 'assets/images/morocco_bg5.jpeg',
      'color': const Color(0xFFFDCB00),
    },
    {
      'title': "Travel & Accommodation",
      'description':
          "Find the perfect place to stay, amazing restaurants, and easy transportation options throughout your journey.",
      'image': 'assets/images/morocco_bg2.jpeg',
      'color': const Color(0xFF065d67),
    },
    {
      'title': "World Cup Experience",
      'description':
          "Access match schedules, locate stadiums and fan zones, and get real-time updates on all World Cup events.",
      'image': 'assets/images/morocco_bg3.jpeg',
      'color': const Color(0xFF8C4843),
    },
    {
      'title': "Explore Morocco",
      'description':
          "Discover the rich culture, stunning landscapes, and amazing experiences waiting for you across Morocco.",
      'image': 'assets/images/morocco_bg1.jpeg',
      'color': const Color(0xFF8C4843),
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _buttonAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    _animationController.forward().then((_) => _animationController.reverse());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => const LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  void _nextOrFinish() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Keep background dark so images blend well on large screens
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth >= 820;
            if (isWide) {
              return _buildWide(context, constraints);
            } else {
              return _buildNarrow(context);
            }
          },
        ),
      ),
    );
  }

  Widget _buildWide(BuildContext context, BoxConstraints constraints) {
    final double leftWidth = constraints.maxWidth * 0.55;
    final double rightWidth = constraints.maxWidth - leftWidth;
    return Stack(
      children: [
        Row(
          children: [
            // Left: PageView with images (visual)
            SizedBox(
              width: leftWidth,
              height: double.infinity,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(page['image'], fit: BoxFit.cover),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.18),
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Right: Content
            SizedBox(
              width: rightWidth,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Card(
                    elevation: 6,
                    margin: const EdgeInsets.symmetric(
                      vertical: 48.0,
                      horizontal: 24.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: TextButton(
                              onPressed: _completeOnboarding,
                              child: const Text('Skip'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  child: Text(
                                    _pages[_currentPage]['title'],
                                    key: ValueKey<int>(_currentPage),
                                    textAlign: TextAlign.center,
                                    style: (Theme.of(
                                              context,
                                            ).textTheme.headlineMedium ??
                                            Theme.of(
                                              context,
                                            ).textTheme.titleLarge ??
                                            const TextStyle(fontSize: 24))
                                        .copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 450),
                                  child: Text(
                                    _pages[_currentPage]['description'],
                                    key: ValueKey<String>(
                                      _pages[_currentPage]['description'],
                                    ),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(height: 1.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildIndicatorsAndActions(isWide: true),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNarrow(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          itemCount: _pages.length,
          onPageChanged: (int page) {
            setState(() {
              _currentPage = page;
            });
          },
          itemBuilder: (context, index) {
            final page = _pages[index];
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(page['image'], fit: BoxFit.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.25),
                        Colors.black.withOpacity(0.75),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            _pages[_currentPage]['title'],
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            _pages[_currentPage]['description'],
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Top-right skip
        Positioned(
          top: 12,
          right: 12,
          child: TextButton(
            onPressed: _completeOnboarding,
            child: const Text('Skip', style: TextStyle(color: Colors.white)),
          ),
        ),

        // Bottom controls
        Positioned(
          bottom: 28,
          left: 20,
          right: 20,
          child: _buildIndicatorsAndActions(isWide: false),
        ),
      ],
    );
  }

  Widget _buildIndicatorsAndActions({required bool isWide}) {
    final indicator = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: _currentPage == index ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color:
                  _currentPage == index
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );

    final button = ScaleTransition(
      scale: _buttonAnimation,
      child: ElevatedButton(
        onPressed: () {
          if (_currentPage < _pages.length - 1) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          } else {
            _completeOnboarding();
          }
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(_currentPage < _pages.length - 1 ? 'Next' : 'Get Started'),
      ),
    );

    if (isWide) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _currentPage > 0
                          ? () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                          : null,
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: button),
            ],
          ),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [indicator, const SizedBox(height: 12), button],
      );
    }
  }
}
