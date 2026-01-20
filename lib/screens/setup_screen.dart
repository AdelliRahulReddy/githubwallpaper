import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/date_utils.dart';
import '../core/preferences.dart';
import '../core/github_api.dart';
import 'main_navigation.dart';

class SetupScreen extends StatefulWidget {
  /// If true, user came from Settings and can go back
  final bool canGoBack;
  
  const SetupScreen({Key? key, this.canGoBack = false}) : super(key: key);

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _usernameController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
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
        _errorMessage = 'Please enter both username and token';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AppPreferences.setUsername(username);
      await AppPreferences.setToken(token);

      final api = GitHubAPI(token: token);
      final data = await api.fetchContributions(username);

      await AppPreferences.setCachedData(data);
      await AppPreferences.setLastUpdate(DateTime.now());

      setState(() => _isLoading = false);

      if (mounted) {
        if (widget.canGoBack) {
          // User came from Settings, just go back with success
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Account updated successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          // First-time setup, go to main app
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  MainNavigation(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: AppTheme.durationNormal,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(widget.canGoBack ? 'Edit Account' : 'Setup'),
        leading: widget.canGoBack
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        automaticallyImplyLeading: widget.canGoBack,
        actions: [
          IconButton(
            icon: Icon(
              context.theme.brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              final isDark = context.theme.brightness == Brightness.dark;
              AppPreferences.setDarkMode(!isDark);
              // Restart screen to apply theme
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => SetupScreen(canGoBack: widget.canGoBack),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: context.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppTheme.spacing8),

              // Month Info Card
              _buildMonthInfoCard(),

              SizedBox(height: AppTheme.spacing24),

              // Username Input
              TextField(
                controller: _usernameController,
                style: context.textTheme.bodyLarge,
                decoration: InputDecoration(
                  labelText: 'GitHub Username',
                  hintText: 'e.g., octocat',
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              SizedBox(height: AppTheme.spacing16),

              // Token Input
              TextField(
                controller: _tokenController,
                obscureText: true,
                style: context.textTheme.bodyLarge,
                decoration: InputDecoration(
                  labelText: 'Personal Access Token',
                  hintText: 'ghp_xxxxxxxxxxxx',
                  prefixIcon: Icon(Icons.key),
                ),
              ),

              SizedBox(height: AppTheme.spacing12),

              // Token Instructions
              Container(
                padding: EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: context.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: context.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: context.primaryColor,
                    ),
                    SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: Text(
                        'Generate token at GitHub: Settings → Developer settings → Personal access tokens → Generate new token (classic). Select "read:user" scope.',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onBackground.withOpacity(
                            0.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppTheme.spacing24),

              // Sync/Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _syncData,
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(widget.canGoBack ? '💾 Save & Sync' : '🔄 Sync GitHub Data'),
                ),
              ),

              // Cancel button (only when editing)
              if (widget.canGoBack) ...[
                SizedBox(height: AppTheme.spacing12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                ),
              ],

              // Error Message
              if (_errorMessage != null) ...[
                SizedBox(height: AppTheme.spacing16),
                Container(
                  padding: EdgeInsets.all(AppTheme.spacing12),
                  decoration: BoxDecoration(
                    color: context.colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: context.colorScheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: context.colorScheme.error,
                        size: 20,
                      ),
                      SizedBox(width: AppTheme.spacing12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Last Sync Info
              _buildLastSyncInfo(),

              SizedBox(height: AppTheme.spacing24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthInfoCard() {
    final monthName = AppDateUtils.getCurrentMonthName();
    final year = DateTime.now().year;
    final daysInMonth = AppDateUtils.getDaysInCurrentMonth();
    final currentDay = AppDateUtils.getCurrentDayOfMonth();

    return Card(
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacing20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: context.theme.brightness == Brightness.dark
                ? [Color(0xFF1F2937), Color(0xFF111827)]
                : [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Column(
          children: [
            Text(
              '$monthName $year',
              style: context.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppTheme.spacing8),
            Text(
              '$daysInMonth days • Day $currentDay',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastSyncInfo() {
    final lastUpdate = AppPreferences.getLastUpdate();

    if (lastUpdate == null) return SizedBox.shrink();

    final formattedDate = AppDateUtils.formatDateTime(lastUpdate);

    return Padding(
      padding: EdgeInsets.only(top: AppTheme.spacing24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          SizedBox(width: AppTheme.spacing8),
          Flexible(
            child: Text(
              'Last synced: $formattedDate',
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall,
            ),
          ),
        ],
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
