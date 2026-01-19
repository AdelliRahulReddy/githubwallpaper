import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/date_utils.dart';
import '../models/contribution_data.dart';

class WallpaperPreviewWidget extends StatelessWidget {
  final CachedContributionData? data;
  final bool isDarkMode;
  final double verticalPosition;
  final double horizontalPosition;
  final double scale;
  final double opacity;
  final String? customQuote;

  const WallpaperPreviewWidget({
    Key? key,
    this.data,
    required this.isDarkMode,
    this.verticalPosition = 0.5,
    this.horizontalPosition = 0.5,
    this.scale = 1.0,
    this.opacity = 1.0,
    this.customQuote,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = isDarkMode ? Color(0xFF0D1117) : Color(0xFFFFFFFF);
    final textColor = isDarkMode ? Color(0xFFF9FAFB) : Color(0xFF111827);
    final accentColor = isDarkMode ? Color(0xFF3B82F6) : Color(0xFF2563EB);

    return Container(
      color: bgColor,
      child: data == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported_outlined,
                    size: 48,
                    color: textColor.withOpacity(0.3),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No data available',
                    style: TextStyle(
                      color: textColor.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // Background gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDarkMode
                          ? [Color(0xFF0D1117), Color(0xFF1F2937)]
                          : [Color(0xFFFFFFFF), Color(0xFFF3F4F6)],
                    ),
                  ),
                ),

                // Main content
                Align(
                  alignment: Alignment(
                    (horizontalPosition - 0.5) * 2,
                    (verticalPosition - 0.5) * 2,
                  ),
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: 400, // Prevent overflow
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header - Username
                                Text(
                                  '@${data!.username}',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                SizedBox(height: 8),

                                // Month & Year
                                Text(
                                  '${AppDateUtils.getCurrentMonthName()} ${DateTime.now().year}',
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 24),

                                // Stats Row
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 12,
                                  children: [
                                    _buildStatItem(
                                      icon: Icons.commit_outlined,
                                      value: '${data!.totalContributions}',
                                      label: 'Total',
                                      color: Color(0xFF26A641),
                                      textColor: textColor,
                                    ),
                                    _buildStatItem(
                                      icon: Icons.local_fire_department_outlined,
                                      value: '${data!.currentStreak}',
                                      label: 'Streak',
                                      color: Color(0xFFFF9500),
                                      textColor: textColor,
                                    ),
                                    _buildStatItem(
                                      icon: Icons.calendar_today_outlined,
                                      value: '${data!.todayCommits}',
                                      label: 'Today',
                                      color: accentColor,
                                      textColor: textColor,
                                    ),
                                  ],
                                ),

                                SizedBox(height: 24),

                                // Contribution Heatmap Preview (simplified)
                                _buildMiniHeatmap(textColor),

                                // Custom Quote (if set)
                                if (customQuote != null && customQuote!.isNotEmpty) ...[
                                  SizedBox(height: 20),
                                  Container(
                                    constraints: BoxConstraints(maxWidth: 350),
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: accentColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: accentColor.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      customQuote!,
                                      style: TextStyle(
                                        color: textColor.withOpacity(0.8),
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: textColor.withOpacity(0.6),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniHeatmap(Color textColor) {
    if (data == null || data!.dailyContributions.isEmpty) {
      return SizedBox.shrink();
    }

    // Get last 7 days
    final today = DateTime.now();
    final last7Days = List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      return date.day;
    });

    final maxContributions = data!.dailyContributions.values.isEmpty
        ? 1
        : data!.dailyContributions.values.reduce((a, b) => a > b ? a : b);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: last7Days.map((day) {
        final count = data!.dailyContributions[day] ?? 0;
        final intensity = maxContributions > 0 ? count / maxContributions : 0.0;

        Color boxColor;
        if (count == 0) {
          boxColor = textColor.withOpacity(0.1);
        } else if (intensity < 0.25) {
          boxColor = Color(0xFF26A641).withOpacity(0.4);
        } else if (intensity < 0.5) {
          boxColor = Color(0xFF26A641).withOpacity(0.6);
        } else if (intensity < 0.75) {
          boxColor = Color(0xFF26A641).withOpacity(0.8);
        } else {
          boxColor = Color(0xFF26A641);
        }

        return Container(
          width: 12,
          height: 12,
          margin: EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }).toList(),
    );
  }
}
