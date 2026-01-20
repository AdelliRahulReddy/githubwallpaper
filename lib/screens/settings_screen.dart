import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/preferences.dart';
import '../main.dart';
import 'setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoUpdateEnabled = true;
  int _updateIntervalHours = 4;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    // Load persisted settings
    _autoUpdateEnabled = AppPreferences.prefs.getBool('auto_update_enabled') ?? true;
    _updateIntervalHours = AppPreferences.prefs.getInt('update_interval_hours') ?? 4;
  }

  Future<void> _saveSettings() async {
    await AppPreferences.prefs.setBool('auto_update_enabled', _autoUpdateEnabled);
    await AppPreferences.prefs.setInt('update_interval_hours', _updateIntervalHours);
  }

  Future<void> _toggleAutoUpdate(bool value) async {
    setState(() => _autoUpdateEnabled = value);
    await _saveSettings();

    if (value) {
      await Workmanager().registerPeriodicTask(
        AppConstants.wallpaperTaskName,
        AppConstants.wallpaperTaskTag,
        frequency: Duration(hours: _updateIntervalHours),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Auto-update enabled (every $_updateIntervalHours hours)'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      await Workmanager().cancelByUniqueName(AppConstants.wallpaperTaskName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🛑 Auto-update disabled'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _changeUpdateInterval(int hours) async {
    setState(() => _updateIntervalHours = hours);
    await _saveSettings();

    if (_autoUpdateEnabled) {
      await Workmanager().registerPeriodicTask(
        AppConstants.wallpaperTaskName,
        AppConstants.wallpaperTaskTag,
        frequency: Duration(hours: hours),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⏰ Update interval changed to $hours hours'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Data?'),
        content: Text(
          'This will log you out and remove all settings. You\'ll need to set up the app again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: context.colorScheme.error,
            ),
            child: Text('Clear & Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AppPreferences.clearAll();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => SetupScreen()),
          (route) => false,
        );
      }
    }
  }

  /// Navigate to edit account - user can come back!
  Future<void> _editAccount() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetupScreen(canGoBack: true),
      ),
    );

    // If account was updated, refresh the UI
    if (result == true && mounted) {
      setState(() {}); // Refresh to show new username
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(title: Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: context.screenPadding,
          children: [
            // Auto-Update Section
            _buildSectionHeader('Wallpaper Updates'),
            SizedBox(height: AppTheme.spacing12),
            _buildSettingTile(
              icon: Icons.autorenew_outlined,
              title: 'Auto-Update Wallpaper',
              subtitle: _autoUpdateEnabled
                  ? 'Active - every $_updateIntervalHours hours'
                  : 'Disabled',
              trailing: Switch(
                value: _autoUpdateEnabled,
                onChanged: _toggleAutoUpdate,
                activeColor: context.primaryColor,
              ),
            ),

            if (_autoUpdateEnabled) ...[
              SizedBox(height: AppTheme.spacing12),
              _buildIntervalSelector(),
            ],

            SizedBox(height: AppTheme.spacing12),
            _buildInfoCard(
              icon: Icons.info_outline,
              title: 'How it works',
              subtitle:
                  'Your wallpaper automatically updates with the latest GitHub contributions every ${_updateIntervalHours} hours, even when the app is closed.',
            ),

            SizedBox(height: AppTheme.spacing24),

            // Appearance Section
            _buildSectionHeader('Appearance'),
            SizedBox(height: AppTheme.spacing12),
            _buildSettingTile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              subtitle: isDarkMode ? 'Enabled' : 'Disabled',
              trailing: Switch(
                value: isDarkMode,
                onChanged: (value) async {
                  await AppPreferences.setDarkMode(value);
                  // Restart entire app to apply theme everywhere
                  MyApp.restartApp(context);
                },
                activeColor: context.primaryColor,
              ),
            ),

            SizedBox(height: AppTheme.spacing24),

            // Account Section
            _buildSectionHeader('Account'),
            SizedBox(height: AppTheme.spacing12),
            _buildSettingTile(
              icon: Icons.person_outline,
              title: 'GitHub Account',
              subtitle: '@${AppPreferences.getUsername() ?? 'Not connected'}',
              trailing: Icon(
                Icons.edit_outlined,
                size: 20,
                color: context.primaryColor,
              ),
              onTap: _editAccount,  // Now navigates properly with back support!
            ),

            SizedBox(height: AppTheme.spacing24),

            // Data Section
            _buildSectionHeader('Data'),
            SizedBox(height: AppTheme.spacing12),
            _buildSettingTile(
              icon: Icons.delete_outline,
              title: 'Clear All Data & Logout',
              subtitle: 'Remove everything and start fresh',
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: context.colorScheme.error,
              ),
              onTap: _clearCache,
              isDestructive: true,
            ),

            SizedBox(height: AppTheme.spacing24),

            // About Section
            _buildSectionHeader('About'),
            SizedBox(height: AppTheme.spacing12),
            _buildSettingTile(
              icon: Icons.info_outline,
              title: 'Version',
              subtitle: '1.0.0',
            ),

            SizedBox(height: AppTheme.spacing40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: AppTheme.spacing4),
      child: Text(
        title.toUpperCase(),
        style: context.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacing12),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppTheme.spacing8),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? context.colorScheme.error.withOpacity(0.1)
                      : context.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  icon,
                  color: isDestructive
                      ? context.colorScheme.error
                      : context.primaryColor,
                  size: 20,
                ),
              ),
              SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: isDestructive ? context.colorScheme.error : null,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacing4),
                    Text(subtitle, style: context.textTheme.bodySmall),
                  ],
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: AppTheme.spacing12),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntervalSelector() {
    final intervals = [2, 4, 6, 12];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update Interval', style: context.textTheme.titleMedium),
            SizedBox(height: AppTheme.spacing12),
            Wrap(
              spacing: AppTheme.spacing8,
              runSpacing: AppTheme.spacing8,
              children: intervals.map((hours) {
                final isSelected = _updateIntervalHours == hours;
                return ChoiceChip(
                  label: Text('$hours hrs'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) _changeUpdateInterval(hours);
                  },
                  selectedColor: context.primaryColor,
                  backgroundColor: context.surfaceColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : context.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                  side: BorderSide(
                    color: context.colorScheme.onBackground.withOpacity(0.1),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: context.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: context.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.primaryColor, size: 20),
          SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppTheme.spacing4),
                Text(
                  subtitle,
                  style: context.textTheme.bodySmall?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
