import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../storage/preferences.dart';
import '../storage/cache_manager.dart';
import '../services/wallpaper_service.dart';
import '../services/background_worker.dart';
import 'widgets/preview_card.dart';
import 'widgets/compact_slider.dart';

class CustomizeScreen extends StatefulWidget {
  const CustomizeScreen({Key? key}) : super(key: key);

  @override
  State<CustomizeScreen> createState() => _CustomizeScreenState();
}

class _CustomizeScreenState extends State<CustomizeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isDarkMode = false;
  double _verticalPosition = AppConstants.defaultVerticalPosition;
  double _horizontalPosition = AppConstants.defaultHorizontalPosition;
  double _scale = AppConstants.defaultScale;
  String _customQuote = '';
  bool _isSettingWallpaper = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _isDarkMode = AppPreferences.getDarkMode();
      _verticalPosition = AppPreferences.getVerticalPosition();
      _horizontalPosition = AppPreferences.getHorizontalPosition();
      _scale = AppPreferences.getScale();
      _customQuote = AppPreferences.getCustomQuote();
    });
  }

  Future<void> _saveSettings() async {
    await AppPreferences.setDarkMode(_isDarkMode);
    await AppPreferences.setVerticalPosition(_verticalPosition);
    await AppPreferences.setHorizontalPosition(_horizontalPosition);
    await AppPreferences.setScale(_scale);
    await AppPreferences.setCustomQuote(_customQuote);
  }

  Future<void> _setWallpaper() async {
    setState(() => _isSettingWallpaper = true);

    try {
      await _saveSettings();
      final result = await WallpaperService.updateWallpaper();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ $result'), backgroundColor: Colors.green),
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
      setState(() => _isSettingWallpaper = false);
    }
  }

  Future<void> _resetSettings() async {
    setState(() {
      _verticalPosition = AppConstants.defaultVerticalPosition;
      _horizontalPosition = AppConstants.defaultHorizontalPosition;
      _scale = AppConstants.defaultScale;
      _customQuote = '';
    });

    await _saveSettings();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('🔄 Settings reset to defaults')));
  }

  @override
  Widget build(BuildContext context) {
    final cachedData = CacheManager.getCachedData();

    final bgColor = _isDarkMode
        ? AppConstants.darkBackground
        : AppConstants.lightBackground;

    final surfaceColor = _isDarkMode
        ? AppConstants.darkSurface
        : AppConstants.lightSurface;

    final textColor = _isDarkMode
        ? AppConstants.darkTextPrimary
        : AppConstants.lightTextPrimary;

    final successColor = _isDarkMode
        ? AppConstants.darkSuccess
        : AppConstants.lightSuccess;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        title: Text('Customize Wallpaper', style: TextStyle(color: textColor)),
        actions: [
          Row(
            children: [
              Text(
                _isDarkMode ? 'Dark' : 'Light',
                style: TextStyle(color: textColor, fontSize: 14),
              ),
              Switch(
                value: _isDarkMode,
                onChanged: (value) {
                  setState(() => _isDarkMode = value);
                  _saveSettings();
                },
                activeColor: AppConstants.darkAccent,
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 70% Preview Area
          Expanded(
            flex: 7,
            child: Container(
              padding: EdgeInsets.all(20),
              child: PreviewCard(
                data: cachedData,
                isDarkMode: _isDarkMode,
                verticalPosition: _verticalPosition,
                horizontalPosition: _horizontalPosition,
                scale: _scale,
                customQuote: _customQuote,
              ),
            ),
          ),

          // 30% Controls Area
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Tab Bar
                  Container(
                    margin: EdgeInsets.only(top: 16, left: 20, right: 20),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: _isDarkMode
                            ? AppConstants.darkAccent
                            : AppConstants.lightAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: textColor,
                      tabs: [
                        Tab(text: 'Position'),
                        Tab(text: 'Quote'),
                      ],
                    ),
                  ),

                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildPositionTab(), _buildQuoteTab()],
                    ),
                  ),

                  // Action Buttons
                  _buildActionButtons(successColor, textColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          CompactSlider(
            label: 'Vertical Position',
            value: _verticalPosition,
            min: AppConstants.minVerticalPos,
            max: AppConstants.maxVerticalPos,
            divisions: 50,
            onChanged: (value) {
              setState(() => _verticalPosition = value);
            },
            isDarkMode: _isDarkMode,
            suffix: '%',
          ),

          SizedBox(height: 16),

          CompactSlider(
            label: 'Horizontal Position',
            value: _horizontalPosition,
            min: 0.0,
            max: 1.0,
            divisions: 100,
            onChanged: (value) {
              setState(() => _horizontalPosition = value);
            },
            isDarkMode: _isDarkMode,
            suffix: '%',
          ),

          SizedBox(height: 16),

          CompactSlider(
            label: 'Scale',
            value: _scale,
            min: AppConstants.minScale,
            max: AppConstants.maxScale,
            divisions: 60,
            onChanged: (value) {
              setState(() => _scale = value);
            },
            isDarkMode: _isDarkMode,
            suffix: 'x',
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteTab() {
    final textColor = _isDarkMode
        ? AppConstants.darkTextPrimary
        : AppConstants.lightTextPrimary;

    final surfaceColor = _isDarkMode
        ? AppConstants.darkBackground
        : AppConstants.lightSurface;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Custom Quote',
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: _customQuote),
            onChanged: (value) {
              setState(() => _customQuote = value);
            },
            maxLines: 3,
            maxLength: 100,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Enter a motivational quote...',
              filled: true,
              fillColor: surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'ℹ️ Optional. Leave empty to hide.',
            style: TextStyle(
              color: _isDarkMode
                  ? AppConstants.darkTextSecondary
                  : AppConstants.lightTextSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Color successColor, Color textColor) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: _isSettingWallpaper ? null : _setWallpaper,
              style: ElevatedButton.styleFrom(
                backgroundColor: successColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSettingWallpaper
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      '✨ Set Wallpaper',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: _resetSettings,
              style: OutlinedButton.styleFrom(
                foregroundColor: textColor,
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
              child: Text('🔄'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
