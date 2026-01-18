import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import '../storage/preferences.dart';
import '../storage/cache_manager.dart';
import '../api/github_api.dart';
import '../api/github_repository.dart';
import 'customize_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _usernameController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _isDarkMode = AppPreferences.getDarkMode();
  }

  Future<void> _loadSavedCredentials() async {
    final username = AppPreferences.getUsername();
    final token = AppPreferences.getToken();

    if (username != null) _usernameController.text = username;
    if (token != null) _tokenController.text = token;
  }

  Future<void> _syncData() async {
    final username = _usernameController.text.trim();
    final token = _tokenController.text.trim();

    if (username.isEmpty || token.isEmpty) {
      setState(() {
        _errorMessage = '❌ Please enter both username and token';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Save credentials
      await AppPreferences.setUsername(username);
      await AppPreferences.setToken(token);

      // Fetch data
      final api = GitHubAPI(token: token);
      final repository = GitHubRepository(api: api);
      final data = await repository.getContributions(username);

      // Save to cache
      await CacheManager.saveCachedData(data);
      await AppPreferences.setLastUpdate(DateTime.now());

      setState(() {
        _isLoading = false;
      });

      // Navigate to customize screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CustomizeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '❌ ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode
        ? AppConstants.darkBackground
        : AppConstants.lightBackground;

    final surfaceColor = _isDarkMode
        ? AppConstants.darkSurface
        : AppConstants.lightSurface;

    final textColor = _isDarkMode
        ? AppConstants.darkTextPrimary
        : AppConstants.lightTextPrimary;

    final textSecondary = _isDarkMode
        ? AppConstants.darkTextSecondary
        : AppConstants.lightTextSecondary;

    final successColor = _isDarkMode
        ? AppConstants.darkSuccess
        : AppConstants.lightSuccess;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        title: Text('GitHub Wallpaper', style: TextStyle(color: textColor)),
        actions: [
          IconButton(
            icon: Icon(
              _isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: textColor,
            ),
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
                AppPreferences.setDarkMode(_isDarkMode);
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current month info card
            _buildMonthInfoCard(surfaceColor, textColor, textSecondary),

            SizedBox(height: 24),

            // Username input
            _buildTextField(
              controller: _usernameController,
              label: 'GitHub Username',
              hint: 'e.g., AdelliRahulReddy',
              icon: Icons.person,
              surfaceColor: surfaceColor,
              textColor: textColor,
            ),

            SizedBox(height: 16),

            // Token input
            _buildTextField(
              controller: _tokenController,
              label: 'Personal Access Token',
              hint: 'ghp_xxxxxxxxxxxx',
              icon: Icons.key,
              isPassword: true,
              surfaceColor: surfaceColor,
              textColor: textColor,
            ),

            SizedBox(height: 12),

            // Token instructions
            _buildTokenInstructions(textSecondary),

            SizedBox(height: 24),

            // Sync button
            ElevatedButton(
              onPressed: _isLoading ? null : _syncData,
              style: ElevatedButton.styleFrom(
                backgroundColor: successColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                      '🔄 Sync GitHub Data',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),

            // Error message
            if (_errorMessage != null) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],

            // Last sync info
            _buildLastSyncInfo(textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthInfoCard(
    Color surfaceColor,
    Color textColor,
    Color textSecondary,
  ) {
    final monthName = AppDateUtils.getCurrentMonthName();
    final year = DateTime.now().year;
    final daysInMonth = AppDateUtils.getDaysInCurrentMonth();
    final currentDay = AppDateUtils.getCurrentDayOfMonth();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$monthName $year',
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '$daysInMonth days • Day $currentDay',
            style: TextStyle(color: textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color surfaceColor,
    required Color textColor,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: textColor.withOpacity(0.7)),
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildTokenInstructions(Color textSecondary) {
    return Text(
      'ℹ️ Generate token at: Settings → Developer settings → Personal access tokens → Generate new token (classic). Select "read:user" scope.',
      style: TextStyle(color: textSecondary, fontSize: 12),
    );
  }

  Widget _buildLastSyncInfo(Color textSecondary) {
    final lastUpdate = AppPreferences.getLastUpdate();

    if (lastUpdate == null) return SizedBox.shrink();

    final formattedDate = AppDateUtils.formatDateTime(lastUpdate);

    return Padding(
      padding: EdgeInsets.only(top: 24),
      child: Text(
        '✅ Last synced: $formattedDate',
        textAlign: TextAlign.center,
        style: TextStyle(color: textSecondary, fontSize: 12),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _tokenController.dispose();
    super.dispose();
  }
}
