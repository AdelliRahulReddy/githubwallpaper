import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/preferences.dart';
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
  }

  Future<void> _toggleAutoUpdate(bool value) async {
    setState(() => _autoUpdateEnabled = value);

    if (value) {
      await Workmanager().registerPeriodicTask(
        AppConstants.wallpaperTaskName,
        AppConstants.wallpaperTaskTag,
        frequency: Duration(hours: _updateIntervalHours),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Auto-update enabled'),
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

    await Workmanager().registerPeriodicTask(
      AppConstants.wallpaperTaskName,
      AppConstants.wallpaperTaskTag,
      frequency: Duration(hours: hours),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
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

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Cache?'),
        content: Text(
          'This will remove all saved data. You\'ll need to sync again.',
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
            child: Text('Clear'),
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

  Future<void> _changeCredentials() async {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => SetupScreen()),
      (route) => false,
    );
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
            // Appearance Section
            _buildSectionHeader('Appearance'),
            SizedBox(height: AppTheme.spacing12),
            _buildSettingTile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              subtitle: isDarkMode ? 'Enabled' : 'Disabled',
              trailing: Switch(
                value: isDarkMode,
                onChanged: (value) {
                  AppPreferences.setDarkMode(value);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsScreen()),
                  );
                },
                activeColor: context.primaryColor,
              ),
            ),

            SizedBox(height: AppTheme.spacing24),

            // Auto-Update Section
            _buildSectionHeader('Auto-Update'),
            SizedBox(height: AppTheme.spacing12),
            _buildSettingTile(
              icon: Icons.autorenew_outlined,
              title: 'Auto-Update Wallpaper',
              subtitle: _autoUpdateEnabled
                  ? 'Every $_updateIntervalHours hours'
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
              icon: Icons.battery_charging_full_outlined,
              title: 'Battery Optimization',
              subtitle:
                  'Disable battery optimization for this app in system settings to ensure auto-updates work reliably.',
            ),

            SizedBox(height: AppTheme.spacing24),

            // Account Section
            _buildSectionHeader('Account'),
            SizedBox(height: AppTheme.spacing12),
            _buildSettingTile(
              icon: Icons.person_outline,
              title: 'Change GitHub Account',
              subtitle: AppPreferences.getUsername() ?? 'Not set',
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: context.colorScheme.onBackground.withOpacity(0.5),
              ),
              onTap: _changeCredentials,
            ),

            SizedBox(height: AppTheme.spacing24),

            // Data Section
            _buildSectionHeader('Data'),
            SizedBox(height: AppTheme.spacing12),
            _buildSettingTile(
              icon: Icons.delete_outline,
              title: 'Clear Cache',
              subtitle: 'Remove all saved data',
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

            SizedBox(height: AppTheme.spacing12),
            _buildSettingTile(
              icon: Icons.code_outlined,
              title: 'GitHub Repository',
              subtitle: 'View source code',
              trailing: Icon(
                Icons.open_in_new,
                size: 16,
                color: context.colorScheme.onBackground.withOpacity(0.5),
              ),
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
