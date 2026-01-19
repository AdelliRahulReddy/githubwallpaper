import 'package:flutter/material.dart';
import '../core/constants.dart';
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    final bgColor = isDarkMode
        ? AppConstants.darkBackground
        : AppConstants.lightBackground;

    final textColor = isDarkMode
        ? AppConstants.darkTextPrimary
        : AppConstants.lightTextPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _goToSetup,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: isDarkMode
                        ? AppConstants.darkTextSecondary
                        : AppConstants.lightTextSecondary,
                    fontSize: 16,
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
                  return _buildPage(_pages[index], screenWidth, isDarkMode);
                },
              ),
            ),

            // Page indicators
            _buildPageIndicator(),

            SizedBox(height: screenHeight * 0.03),

            // Bottom button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _currentPage == _pages.length - 1
                      ? _goToSetup
                      : _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pages[_currentPage].color,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.04),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, double screenWidth, bool isDarkMode) {
    final textColor = isDarkMode
        ? AppConstants.darkTextPrimary
        : AppConstants.lightTextPrimary;

    final textSecondary = isDarkMode
        ? AppConstants.darkTextSecondary
        : AppConstants.lightTextSecondary;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with gradient background
          Container(
            width: screenWidth * 0.35,
            height: screenWidth * 0.35,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  page.color.withOpacity(0.2),
                  page.color.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(page.icon, size: screenWidth * 0.18, color: page.color),
          ),

          SizedBox(height: 48),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.2,
            ),
          ),

          SizedBox(height: 16),

          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: textSecondary, height: 1.5),
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
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? _pages[index].color
                : _pages[index].color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _goToSetup() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SetupScreen()),
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
