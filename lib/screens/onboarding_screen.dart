import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'setup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.analytics_outlined,
      title: 'Track GitHub Activity',
      description:
          'Visualize your monthly contributions as a beautiful heatmap wallpaper',
      color: Color(0xFF26A641),
    ),
    OnboardingPage(
      icon: Icons.wallpaper_outlined,
      title: 'Live Wallpaper',
      description:
          'Your GitHub graph updates automatically every 4 hours on your home screen',
      color: Color(0xFF58A6FF),
    ),
    OnboardingPage(
      icon: Icons.auto_awesome_outlined,
      title: 'Stay Motivated',
      description:
          'See your coding streak daily and stay committed to your goals',
      color: Color(0xFFFF9500),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(
                  top: AppTheme.spacing12,
                  right: AppTheme.spacing16,
                ),
                child: TextButton(
                  onPressed: _goToSetup,
                  child: Text(
                    'Skip',
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: context.colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Page indicators
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppTheme.spacing24),
              child: _buildPageIndicator(),
            ),

            // Bottom button
            Padding(
              padding: context.screenPadding,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _currentPage == _pages.length - 1
                          ? _goToSetup
                          : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].color,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: AppTheme.spacing16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: context.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppTheme.spacing16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.screenPadding.left),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with gradient background
          Container(
            width: context.screenWidth * 0.35,
            height: context.screenWidth * 0.35,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  page.color.withOpacity(0.2),
                  page.color.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            ),
            child: Icon(
              page.icon,
              size: context.screenWidth * 0.18,
              color: page.color,
            ),
          ),

          SizedBox(height: AppTheme.spacing48),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: context.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: AppTheme.spacing16),

          // Description
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
            child: Text(
              page.description,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colorScheme.onBackground.withOpacity(0.7),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => AnimatedContainer(
          duration: AppTheme.durationNormal,
          margin: EdgeInsets.symmetric(horizontal: AppTheme.spacing4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? _pages[index].color
                : _pages[index].color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppTheme.spacing4),
          ),
        ),
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: AppTheme.durationNormal,
      curve: Curves.easeInOut,
    );
  }

  void _goToSetup() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => SetupScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: AppTheme.durationNormal,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
