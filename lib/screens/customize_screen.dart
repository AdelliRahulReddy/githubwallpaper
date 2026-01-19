import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:async_wallpaper/async_wallpaper.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/preferences.dart';
import '../widgets/heatmap_painter.dart';
import '../widgets/compact_slider.dart';
import '../models/contribution_data.dart';

class CustomizeScreen extends StatefulWidget {
  const CustomizeScreen({Key? key}) : super(key: key);

  @override
  State<CustomizeScreen> createState() => _CustomizeScreenState();
}

class _CustomizeScreenState extends State<CustomizeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Position
  double _verticalPosition = AppConstants.defaultVerticalPosition;
  double _horizontalPosition = AppConstants.defaultHorizontalPosition;
  double _paddingTop = 0.0;
  double _paddingBottom = 0.0;
  double _paddingLeft = 0.0;
  double _paddingRight = 0.0;

  // Appearance
  double _scale = AppConstants.defaultScale;
  double _opacity = 1.0;
  double _cornerRadius = 0.0;

  // Text
  String _customQuote = '';
  double _quoteFontSize = 14.0;
  double _quoteOpacity = 1.0;

  bool _isSettingWallpaper = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _verticalPosition = AppPreferences.getVerticalPosition();
      _horizontalPosition = AppPreferences.getHorizontalPosition();
      _scale = AppPreferences.getScale();
      _opacity = AppPreferences.getOpacity();
      _customQuote = AppPreferences.getCustomQuote();
      _paddingTop = AppPreferences.getPaddingTop();
      _paddingBottom = AppPreferences.getPaddingBottom();
      _paddingLeft = AppPreferences.getPaddingLeft();
      _paddingRight = AppPreferences.getPaddingRight();
      _cornerRadius = AppPreferences.getCornerRadius();
      _quoteFontSize = AppPreferences.getQuoteFontSize();
      _quoteOpacity = AppPreferences.getQuoteOpacity();
    });
  }

  Future<void> _saveSettings() async {
    await AppPreferences.setVerticalPosition(_verticalPosition);
    await AppPreferences.setHorizontalPosition(_horizontalPosition);
    await AppPreferences.setScale(_scale);
    await AppPreferences.setOpacity(_opacity);
    await AppPreferences.setCustomQuote(_customQuote);
    await AppPreferences.setPaddingTop(_paddingTop);
    await AppPreferences.setPaddingBottom(_paddingBottom);
    await AppPreferences.setPaddingLeft(_paddingLeft);
    await AppPreferences.setPaddingRight(_paddingRight);
    await AppPreferences.setCornerRadius(_cornerRadius);
    await AppPreferences.setQuoteFontSize(_quoteFontSize);
    await AppPreferences.setQuoteOpacity(_quoteOpacity);
  }

  Future<void> _setWallpaper() async {
    // Show dialog to select wallpaper target
    final target = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Wallpaper'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.lock_outline, color: context.primaryColor),
              title: Text('Lock Screen'),
              onTap: () => Navigator.pop(context, 'lock'),
            ),
            ListTile(
              leading: Icon(Icons.home_outlined, color: context.primaryColor),
              title: Text('Home Screen'),
              onTap: () => Navigator.pop(context, 'home'),
            ),
            ListTile(
              leading: Icon(Icons.phone_android_outlined, color: context.primaryColor),
              title: Text('Both Screens'),
              onTap: () => Navigator.pop(context, 'both'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );

    if (target == null) return;

    setState(() => _isSettingWallpaper = true);

    try {
      await _saveSettings();
      final data = AppPreferences.getCachedData();

      if (data == null) {
        throw Exception('No cached data. Please sync first.');
      }

      final file = await _generateWallpaperImage(data);

      int location;
      switch (target) {
        case 'lock':
          location = AsyncWallpaper.LOCK_SCREEN;
          break;
        case 'home':
          location = AsyncWallpaper.HOME_SCREEN;
          break;
        case 'both':
        default:
          location = AsyncWallpaper.BOTH_SCREENS;
      }

      await AsyncWallpaper.setWallpaperFromFile(
        filePath: file.path,
        wallpaperLocation: location,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Wallpaper set successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isSettingWallpaper = false);
    }
  }

  Future<File> _generateWallpaperImage(data) async {
    final isDarkMode = context.theme.brightness == Brightness.dark;

    final size = Size(
      AppConstants.wallpaperWidth.toDouble(),
      AppConstants.wallpaperHeight.toDouble(),
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final bgPaint = Paint()
      ..color = isDarkMode
          ? AppConstants.darkBackground
          : AppConstants.lightBackground;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final painter = HeatmapPainter(
      data: data,
      isDarkMode: isDarkMode,
      verticalPosition: _verticalPosition,
      horizontalPosition: _horizontalPosition,
      scale: _scale,
      opacity: _opacity,
      customQuote: _customQuote,
      paddingTop: _paddingTop,
      paddingBottom: _paddingBottom,
      paddingLeft: _paddingLeft,
      paddingRight: _paddingRight,
      cornerRadius: _cornerRadius,
      quoteFontSize: _quoteFontSize,
      quoteOpacity: _quoteOpacity,
    );

    painter.paint(canvas, size);

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/github_wallpaper_$timestamp.png');
    await file.writeAsBytes(pngBytes);

    return file;
  }

  Future<void> _resetSettings() async {
    setState(() {
      _verticalPosition = AppConstants.defaultVerticalPosition;
      _horizontalPosition = AppConstants.defaultHorizontalPosition;
      _scale = AppConstants.defaultScale;
      _opacity = 1.0;
      _customQuote = '';
      _paddingTop = 0.0;
      _paddingBottom = 0.0;
      _paddingLeft = 0.0;
      _paddingRight = 0.0;
      _cornerRadius = 0.0;
      _quoteFontSize = 14.0;
      _quoteOpacity = 1.0;
    });

    await _saveSettings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔄 Settings reset to defaults'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cachedData = AppPreferences.getCachedData();
    final isDarkMode = context.theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // 60% Phone Preview (matching home screen)
            Expanded(
              flex: 6,
              child: Column(
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
                          child: _buildWallpaperPreview(cachedData, isDarkMode),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 40% Controls
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusRound),
                    topRight: Radius.circular(AppTheme.radiusRound),
                  ),
                ),
                child: Column(
                  children: [
                    // Tab Bar
                    _buildTabBar(),

                    // Tab Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPositionTab(),
                          _buildAppearanceTab(),
                          _buildTextTab(),
                        ],
                      ),
                    ),

                    // Action Buttons
                    _buildActionButtons(),
                  ],
                ),
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
                  'Customize',
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Adjust wallpaper settings',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWallpaperPreview(CachedContributionData? data, bool isDarkMode) {
    if (data == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: context.colorScheme.onBackground.withOpacity(0.3),
            ),
            SizedBox(height: 16),
            Text(
              'No data available',
              style: TextStyle(
                color: context.colorScheme.onBackground.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return CustomPaint(
      painter: HeatmapPainter(
        data: data,
        isDarkMode: isDarkMode,
        verticalPosition: _verticalPosition,
        horizontalPosition: _horizontalPosition,
        scale: _scale,
        opacity: _opacity,
        customQuote: _customQuote,
        paddingTop: _paddingTop,
        paddingBottom: _paddingBottom,
        paddingLeft: _paddingLeft,
        paddingRight: _paddingRight,
        cornerRadius: _cornerRadius,
        quoteFontSize: _quoteFontSize,
        quoteOpacity: _quoteOpacity,
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: context.primaryColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: context.textColor,
        dividerColor: Colors.transparent,
        tabs: [
          Tab(text: 'Position'),
          Tab(text: 'Appearance'),
          Tab(text: 'Text'),
        ],
      ),
    );
  }

  Widget _buildPositionTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        children: [
          CompactSlider(
            label: 'Vertical',
            value: _verticalPosition,
            min: AppConstants.minVerticalPos,
            max: AppConstants.maxVerticalPos,
            divisions: 100,
            onChanged: (value) {
              setState(() => _verticalPosition = value);
              _saveSettings();
            },
            isDarkMode: context.theme.brightness == Brightness.dark,
            suffix: '%',
          ),

          SizedBox(height: AppTheme.spacing12),

          CompactSlider(
            label: 'Horizontal',
            value: _horizontalPosition,
            min: 0.0,
            max: 1.0,
            divisions: 100,
            onChanged: (value) {
              setState(() => _horizontalPosition = value);
              _saveSettings();
            },
            isDarkMode: context.theme.brightness == Brightness.dark,
            suffix: '%',
          ),

          SizedBox(height: AppTheme.spacing16),
          Divider(),
          SizedBox(height: AppTheme.spacing8),

          Text('Padding', style: context.textTheme.titleSmall),

          SizedBox(height: AppTheme.spacing12),

          CompactSlider(
            label: 'Top',
            value: _paddingTop,
            min: 0.0,
            max: 200.0,
            divisions: 40,
            onChanged: (value) {
              setState(() => _paddingTop = value);
              _saveSettings();
            },
            isDarkMode: context.theme.brightness == Brightness.dark,
            suffix: 'px',
          ),

          SizedBox(height: AppTheme.spacing12),

          CompactSlider(
            label: 'Bottom',
            value: _paddingBottom,
            min: 0.0,
            max: 200.0,
            divisions: 40,
            onChanged: (value) {
              setState(() => _paddingBottom = value);
              _saveSettings();
            },
            isDarkMode: context.theme.brightness == Brightness.dark,
            suffix: 'px',
          ),

          SizedBox(height: AppTheme.spacing12),

          CompactSlider(
            label: 'Left',
            value: _paddingLeft,
            min: 0.0,
            max: 200.0,
            divisions: 40,
            onChanged: (value) {
              setState(() => _paddingLeft = value);
              _saveSettings();
            },
            isDarkMode: context.theme.brightness == Brightness.dark,
            suffix: 'px',
          ),

          SizedBox(height: AppTheme.spacing12),

          CompactSlider(
            label: 'Right',
            value: _paddingRight,
            min: 0.0,
            max: 200.0,
            divisions: 40,
            onChanged: (value) {
              setState(() => _paddingRight = value);
              _saveSettings();
            },
            isDarkMode: context.theme.brightness == Brightness.dark,
            suffix: 'px',
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        children: [
          CompactSlider(
            label: 'Scale',
            value: _scale,
            min: AppConstants.minScale,
            max: AppConstants.maxScale,
            divisions: 60,
            onChanged: (value) {
              setState(() => _scale = value);
              _saveSettings();
            },
            isDarkMode: context.theme.brightness == Brightness.dark,
            suffix: 'x',
          ),

          SizedBox(height: AppTheme.spacing16),

          CompactSlider(
            label: 'Opacity',
            value: _opacity,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            onChanged: (value) {
              setState(() => _opacity = value);
              _saveSettings();
            },
            isDarkMode: context.theme.brightness == Brightness.dark,
            suffix: '%',
          ),

          SizedBox(height: AppTheme.spacing16),

          CompactSlider(
            label: 'Corner Radius',
            value: _cornerRadius,
            min: 0.0,
            max: 50.0,
            divisions: 50,
            onChanged: (value) {
              setState(() => _cornerRadius = value);
              _saveSettings();
            },
            isDarkMode: context.theme.brightness == Brightness.dark,
            suffix: 'px',
          ),
        ],
      ),
    );
  }

  Widget _buildTextTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Custom Quote', style: context.textTheme.titleMedium),
          SizedBox(height: AppTheme.spacing8),
          TextField(
            controller: TextEditingController(text: _customQuote)
              ..selection = TextSelection.fromPosition(
                TextPosition(offset: _customQuote.length),
              ),
            onChanged: (value) {
              setState(() => _customQuote = value);
              _saveSettings();
            },
            maxLines: 3,
            maxLength: 100,
            style: context.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Enter a motivational quote...',
            ),
          ),

          SizedBox(height: AppTheme.spacing16),

          CompactSlider(
            label: 'Font Size',
            value: _quoteFontSize,
            min: 10.0,
            max: 24.0,
            divisions: 14,
            onChanged: (value) {
              setState(() => _quoteFontSize = value);
              _saveSettings();
            },
            isDarkMode: context.theme.brightness == Brightness.dark,
            suffix: 'pt',
          ),

          SizedBox(height: AppTheme.spacing16),

          CompactSlider(
            label: 'Quote Opacity',
            value: _quoteOpacity,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            onChanged: (value) {
              setState(() => _quoteOpacity = value);
              _saveSettings();
            },
            isDarkMode: context.theme.brightness == Brightness.dark,
            suffix: '%',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: _isSettingWallpaper ? null : _setWallpaper,
              child: _isSettingWallpaper
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text('✨ Set Wallpaper'),
            ),
          ),
          SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: OutlinedButton(
              onPressed: _resetSettings,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: AppTheme.spacing16),
              ),
              child: Icon(Icons.restart_alt),
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
