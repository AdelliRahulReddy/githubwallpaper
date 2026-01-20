import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/preferences.dart';
import '../core/github_api.dart';
import '../core/wallpaper_service.dart';
import '../models/contribution_data.dart';
import '../widgets/heatmap_painter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isRefreshing = false;
  CachedContributionData? _cachedData;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto-refresh on app open
    _autoRefreshOnOpen();
  }

  void _loadData() {
    setState(() {
      _cachedData = AppPreferences.getCachedData();
    });
  }

  /// Auto refresh when app opens (if last update > 1 hour ago)
  Future<void> _autoRefreshOnOpen() async {
    final lastUpdate = AppPreferences.getLastUpdate();
    final now = DateTime.now();
    
    // Auto-refresh if: no data, or last update > 1 hour ago
    if (_cachedData == null || 
        lastUpdate == null || 
        now.difference(lastUpdate).inHours >= 1) {
      await _refreshData(showSnackbar: false);
    }
  }

  Future<void> _refreshData({bool showSnackbar = true}) async {
    if (_isRefreshing) return;
    
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

      // Also regenerate and set wallpaper automatically!
      final target = AppPreferences.getWallpaperTarget();
      await WallpaperService.generateAndSetWallpaper(data, target: target);

      _loadData();

      if (mounted && showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Data synced & wallpaper updated!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted && showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // 70% Live Preview
            Expanded(
              flex: 7,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.screenPadding.left,
                ),
                child: _buildLivePreview(),
              ),
            ),

            // 30% Quick Info
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusRound),
                    topRight: Radius.circular(AppTheme.radiusRound),
                  ),
                ),
                child: _buildQuickInfo(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(context.screenPadding.left),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GitHub Wallpaper',
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_cachedData != null)
                  Text(
                    '@${_cachedData!.username}',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onBackground.withOpacity(0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
              ],
            ),
          ),
          SizedBox(width: AppTheme.spacing8),
          IconButton(
            onPressed: _isRefreshing ? null : () => _refreshData(),
            icon: _isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.refresh_outlined),
            style: IconButton.styleFrom(
              backgroundColor: context.primaryColor.withOpacity(0.1),
              foregroundColor: context.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Live Preview',
          style: context.textTheme.titleMedium?.copyWith(
            color: context.colorScheme.onBackground.withOpacity(0.6),
          ),
        ),
        SizedBox(height: AppTheme.spacing12),

        // Phone Mockup with Wallpaper
        Flexible(
          child: AspectRatio(
            aspectRatio: 9 / 19.5,
            child: Container(
              decoration: BoxDecoration(
                color: context.backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.spacing32),
                border: Border.all(
                  color: context.colorScheme.onBackground.withOpacity(0.1),
                  width: 8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.spacing24),
                child: _cachedData == null
                    ? _buildLoadingState()
                    : CustomPaint(
                        painter: HeatmapPainter(
                          data: _cachedData!,
                          isDarkMode: context.theme.brightness == Brightness.dark,
                          verticalPosition: AppPreferences.getVerticalPosition(),
                          horizontalPosition: AppPreferences.getHorizontalPosition(),
                          scale: AppPreferences.getScale(),
                          opacity: AppPreferences.getOpacity(),
                          customQuote: AppPreferences.getCustomQuote(),
                          paddingTop: AppPreferences.getPaddingTop(),
                          paddingBottom: AppPreferences.getPaddingBottom(),
                          paddingLeft: AppPreferences.getPaddingLeft(),
                          paddingRight: AppPreferences.getPaddingRight(),
                          cornerRadius: AppPreferences.getCornerRadius(),
                          quoteFontSize: AppPreferences.getQuoteFontSize(),
                          quoteOpacity: AppPreferences.getQuoteOpacity(),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isRefreshing) ...[
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Syncing...',
              style: TextStyle(
                color: context.colorScheme.onBackground.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ] else ...[
            Icon(
              Icons.cloud_download_outlined,
              size: 48,
              color: context.colorScheme.onBackground.withOpacity(0.3),
            ),
            SizedBox(height: 16),
            Text(
              'Tap refresh to sync',
              style: TextStyle(
                color: context.colorScheme.onBackground.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickInfo() {
    final lastUpdate = AppPreferences.getLastUpdate();

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_cachedData != null) ...[
            // Quick Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildQuickStatCard(
                    icon: Icons.calendar_month_outlined,
                    value: '${_cachedData!.totalContributions}',
                    label: 'This Month',
                    color: Color(0xFF39D353),
                  ),
                ),
                SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: _buildQuickStatCard(
                    icon: Icons.local_fire_department_outlined,
                    value: '${_cachedData!.currentStreak}d',
                    label: 'Streak',
                    color: Color(0xFFFF9500),
                  ),
                ),
                SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: _buildQuickStatCard(
                    icon: Icons.commit_outlined,
                    value: '${_cachedData!.todayCommits}',
                    label: 'Today',
                    color: Color(0xFF58A6FF),
                  ),
                ),
              ],
            ),
          ],

          if (lastUpdate != null) ...[
            SizedBox(height: AppTheme.spacing16),

            // Last Update & Auto-update status
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.autorenew, color: Colors.green, size: 16),
                  SizedBox(width: AppTheme.spacing8),
                  Text(
                    'Auto-updates every 4 hours',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: AppTheme.spacing4),
          Text(
            value,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: context.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
