import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import '../core/constants.dart';
import '../core/preferences.dart';
import 'setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _autoUpdateEnabled = true;
  int _updateIntervalHours = 4;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _isDarkMode = AppPreferences.getDarkMode();
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    setState(() => _isDarkMode = value);
    await AppPreferences.setDarkMode(value);
  }

  Future<void> _toggleAutoUpdate(bool value) async {
    setState(() => _autoUpdateEnabled = value);

    if (value) {
      // Re-register periodic task
      await Workmanager().registerPeriodicTask(
        AppConstants.wallpaperTaskName,
        AppConstants.wallpaperTaskTag,
        frequency: Duration(hours: _updateIntervalHours),
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('✅ Auto-update enabled')));
      }
    } else {
      // Cancel periodic task
      await Workmanager().cancelByUniqueName(AppConstants.wallpaperTaskName);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('🛑 Auto-update disabled')));
      }
    }
  }

  Future<void> _changeUpdateInterval(int hours) async {
    setState(() => _updateIntervalHours = hours);

    // Re-register with new interval
    await Workmanager().registerPeriodicTask(
      AppConstants.wallpaperTaskName,
      AppConstants.wallpaperTaskTag,
      frequency: Duration(hours: hours),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⏰ Update interval changed to $hours hours')),
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
            child: Text('Clear', style: TextStyle(color: Colors.red)),
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
      appBar: AppBar(
        backgroundColor: surfaceColor,
        title: Text('Settings', style: TextStyle(color: textColor)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          // Appearance Section
          _buildSectionHeader('Appearance', textColor),
          SizedBox(height: 12),
          _buildSettingTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: _isDarkMode ? 'Enabled' : 'Disabled',
            trailing: Switch(
              value: _isDarkMode,
              onChanged: _toggleDarkMode,
              activeColor: AppConstants.darkAccent,
            ),
            surfaceColor: surfaceColor,
            textColor: textColor,
            textSecondary: textSecondary,
          ),

          SizedBox(height: 24),

          // Auto-Update Section
          _buildSectionHeader('Auto-Update', textColor),
          SizedBox(height: 12),
          _buildSettingTile(
            icon: Icons.autorenew_outlined,
            title: 'Auto-Update Wallpaper',
            subtitle: _autoUpdateEnabled
                ? 'Every $_updateIntervalHours hours'
                : 'Disabled',
            trailing: Switch(
              value: _autoUpdateEnabled,
              onChanged: _toggleAutoUpdate,
              activeColor: AppConstants.darkAccent,
            ),
            surfaceColor: surfaceColor,
            textColor: textColor,
            textSecondary: textSecondary,
          ),

          if (_autoUpdateEnabled) ...[
            SizedBox(height: 12),
            _buildIntervalSelector(surfaceColor, textColor, textSecondary),
          ],

          SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.battery_charging_full_outlined,
            title: 'Battery Optimization',
            subtitle:
                'Disable battery optimization for this app to ensure auto-updates work reliably.',
            surfaceColor: surfaceColor,
            textColor: textColor,
            textSecondary: textSecondary,
          ),

          SizedBox(height: 24),

          // Account Section
          _buildSectionHeader('Account', textColor),
          SizedBox(height: 12),
          _buildSettingTile(
            icon: Icons.person_outline,
            title: 'Change GitHub Account',
            subtitle: AppPreferences.getUsername() ?? 'Not set',
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: textSecondary,
            ),
            onTap: _changeCredentials,
            surfaceColor: surfaceColor,
            textColor: textColor,
            textSecondary: textSecondary,
          ),

          SizedBox(height: 24),

          // Data Section
          _buildSectionHeader('Data', textColor),
          SizedBox(height: 12),
          _buildSettingTile(
            icon: Icons.delete_outline,
            title: 'Clear Cache',
            subtitle: 'Remove all saved data',
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.red,
            ),
            onTap: _clearCache,
            surfaceColor: surfaceColor,
            textColor: textColor,
            textSecondary: textSecondary,
            isDestructive: true,
          ),

          SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About', textColor),
          SizedBox(height: 12),
          _buildSettingTile(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: '1.0.0',
            surfaceColor: surfaceColor,
            textColor: textColor,
            textSecondary: textSecondary,
          ),

          SizedBox(height: 12),
          _buildSettingTile(
            icon: Icons.code_outlined,
            title: 'GitHub Repository',
            subtitle: 'View source code',
            trailing: Icon(Icons.open_in_new, size: 16, color: textSecondary),
            surfaceColor: surfaceColor,
            textColor: textColor,
            textSecondary: textSecondary,
          ),

          SizedBox(height: screenHeight * 0.05),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
    Widget? trailing,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return Container(
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
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withOpacity(0.1)
                : AppConstants.darkAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : AppConstants.darkAccent,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: textSecondary, fontSize: 13),
        ),
        trailing: trailing,
      ),
    );
  }

  Widget _buildIntervalSelector(
    Color surfaceColor,
    Color textColor,
    Color textSecondary,
  ) {
    final intervals = [2, 4, 6, 12];

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Update Interval',
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: intervals.map((hours) {
              final isSelected = _updateIntervalHours == hours;
              return ChoiceChip(
                label: Text('$hours hrs'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) _changeUpdateInterval(hours);
                },
                selectedColor: AppConstants.darkAccent,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : textColor,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color surfaceColor,
    required Color textColor,
    required Color textSecondary,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.darkAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.darkAccent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppConstants.darkAccent, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
