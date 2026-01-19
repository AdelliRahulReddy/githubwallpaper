import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/date_utils.dart';
import '../core/preferences.dart';
import '../core/github_api.dart';
import '../models/contribution_data.dart';
import 'customize_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isDarkMode = false;
  bool _isRefreshing = false;
  CachedContributionData? _cachedData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _isDarkMode = AppPreferences.getDarkMode();
      _cachedData = AppPreferences.getCachedData();
    });
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);

    try {
      final username = AppPreferences.getUsername();
      final token = AppPreferences.getToken();

      if (username == null || token == null) {
        throw Exception('Credentials not found');
      }

      final api = GitHubAPI(token: token);
      final data = await api.fetchContributions(username);

      await AppPreferences.setCachedData(data);
      await AppPreferences.setLastUpdate(DateTime.now());

      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Data synced successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: bgColor,
              elevation: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GitHub Wallpaper',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_cachedData != null)
                    Text(
                      '@${_cachedData!.username}',
                      style: TextStyle(color: textSecondary, fontSize: 14),
                    ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.settings_outlined, color: textColor),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsScreen()),
                    ).then((_) => _loadData());
                  },
                ),
              ],
            ),

            // Content
            SliverPadding(
              padding: EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Month Info Card
                  _buildMonthCard(surfaceColor, textColor, textSecondary),

                  SizedBox(height: 16),

                  // Stats Grid
                  if (_cachedData != null)
                    _buildStatsGrid(
                      surfaceColor,
                      textColor,
                      textSecondary,
                      screenWidth,
                    ),

                  SizedBox(height: 16),

                  // Preview Card
                  _buildPreviewCard(
                    surfaceColor,
                    textColor,
                    textSecondary,
                    screenWidth,
                  ),

                  SizedBox(height: 16),

                  // Quick Actions
                  _buildQuickActions(screenWidth),

                  SizedBox(height: 16),

                  // Last Update Info
                  _buildLastUpdateCard(surfaceColor, textSecondary),

                  SizedBox(height: screenHeight * 0.02),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthCard(
    Color surfaceColor,
    Color textColor,
    Color textSecondary,
  ) {
    final monthName = AppDateUtils.getCurrentMonthName();
    final year = DateTime.now().year;
    final daysInMonth = AppDateUtils.getDaysInCurrentMonth();
    final currentDay = AppDateUtils.getCurrentDayOfMonth();
    final progress = currentDay / daysInMonth;

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDarkMode
              ? [Color(0xFF1F2937), Color(0xFF111827)]
              : [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    monthName,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$year',
                    style: TextStyle(color: textSecondary, fontSize: 18),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppConstants.darkAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Day $currentDay/$daysInMonth',
                  style: TextStyle(
                    color: AppConstants.darkAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: _isDarkMode
                  ? AppConstants.darkBorder
                  : AppConstants.lightBorder,
              valueColor: AlwaysStoppedAnimation(AppConstants.darkAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    Color surfaceColor,
    Color textColor,
    Color textSecondary,
    double screenWidth,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          icon: Icons.commit_outlined,
          value: '${_cachedData!.totalContributions}',
          label: 'Contributions',
          color: Color(0xFF26A641),
          surfaceColor: surfaceColor,
          textColor: textColor,
          textSecondary: textSecondary,
        ),
        _buildStatCard(
          icon: Icons.local_fire_department_outlined,
          value: '${_cachedData!.currentStreak}',
          label: 'Day Streak',
          color: Color(0xFFFF9500),
          surfaceColor: surfaceColor,
          textColor: textColor,
          textSecondary: textSecondary,
        ),
        _buildStatCard(
          icon: Icons.calendar_today_outlined,
          value: '${_cachedData!.todayCommits}',
          label: 'Today',
          color: Color(0xFF58A6FF),
          surfaceColor: surfaceColor,
          textColor: textColor,
          textSecondary: textSecondary,
        ),
        _buildStatCard(
          icon: Icons.trending_up_outlined,
          value: '${_cachedData!.longestStreak}',
          label: 'Best Streak',
          color: Color(0xFFA371F7),
          surfaceColor: surfaceColor,
          textColor: textColor,
          textSecondary: textSecondary,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDarkMode
              ? AppConstants.darkBorder
              : AppConstants.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(label, style: TextStyle(color: textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(
    Color surfaceColor,
    Color textColor,
    Color textSecondary,
    double screenWidth,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDarkMode
              ? AppConstants.darkBorder
              : AppConstants.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🖼️ Wallpaper Preview',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: textSecondary, size: 16),
            ],
          ),
          SizedBox(height: 12),
          Container(
            height: screenWidth * 0.4,
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? AppConstants.darkBackground
                  : AppConstants.lightBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDarkMode
                    ? AppConstants.darkBorder
                    : AppConstants.lightBorder,
              ),
            ),
            child: Center(
              child: Text(
                '📊 Tap to customize',
                style: TextStyle(color: textSecondary, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(double screenWidth) {
    final successColor = _isDarkMode
        ? AppConstants.darkSuccess
        : AppConstants.lightSuccess;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CustomizeScreen()),
              );
            },
            icon: Icon(Icons.palette_outlined),
            label: Text('Customize'),
            style: ElevatedButton.styleFrom(
              backgroundColor: successColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: _isRefreshing ? null : _refreshData,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(
                color: _isDarkMode
                    ? AppConstants.darkBorder
                    : AppConstants.lightBorder,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isRefreshing
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.refresh),
          ),
        ),
      ],
    );
  }

  Widget _buildLastUpdateCard(Color surfaceColor, Color textSecondary) {
    final lastUpdate = AppPreferences.getLastUpdate();

    if (lastUpdate == null) return SizedBox.shrink();

    final formattedDate = AppDateUtils.formatDateTime(lastUpdate);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDarkMode
              ? AppConstants.darkBorder
              : AppConstants.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Last synced: $formattedDate',
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
