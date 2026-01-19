import 'package:flutter/material.dart';
import '../models/contribution_data.dart';
import '../core/constants.dart';
import 'heatmap_painter.dart';

class PreviewCard extends StatelessWidget {
  final CachedContributionData? data;
  final bool isDarkMode;
  final double verticalPosition;
  final double horizontalPosition;
  final double scale;
  final String customQuote;

  const PreviewCard({
    Key? key,
    required this.data,
    required this.isDarkMode,
    required this.verticalPosition,
    required this.horizontalPosition,
    required this.scale,
    this.customQuote = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return _buildPlaceholder();
    }

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppConstants.darkBackground
            : AppConstants.lightBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? AppConstants.darkBorder
              : AppConstants.lightBorder,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 9 / 19.5,
          child: CustomPaint(
            painter: HeatmapPainter(
              data: data!,
              isDarkMode: isDarkMode,
              verticalPosition: verticalPosition,
              horizontalPosition: horizontalPosition,
              scale: scale * 0.5,
              customQuote: customQuote,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppConstants.darkSurface
            : AppConstants.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? AppConstants.darkBorder
              : AppConstants.lightBorder,
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 48,
              color: isDarkMode
                  ? AppConstants.darkTextSecondary
                  : AppConstants.lightTextSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'No data yet',
              style: TextStyle(
                color: isDarkMode
                    ? AppConstants.darkTextSecondary
                    : AppConstants.lightTextSecondary,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Sync your GitHub account first',
              style: TextStyle(
                color: isDarkMode
                    ? AppConstants.darkTextSecondary
                    : AppConstants.lightTextSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
