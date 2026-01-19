import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/contribution_data.dart';
import 'heatmap_painter.dart';

class PreviewCard extends StatelessWidget {
  final CachedContributionData? data;
  final bool isDarkMode;
  final double verticalPosition;
  final double horizontalPosition;
  final double scale;
  final double opacity;
  final String customQuote;
  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;
  final double cornerRadius;
  final double quoteFontSize;
  final double quoteOpacity;

  const PreviewCard({
    Key? key,
    required this.data,
    required this.isDarkMode,
    required this.verticalPosition,
    required this.horizontalPosition,
    required this.scale,
    required this.opacity,
    required this.customQuote,
    this.paddingTop = 0.0,
    this.paddingBottom = 0.0,
    this.paddingLeft = 0.0,
    this.paddingRight = 0.0,
    this.cornerRadius = 0.0,
    this.quoteFontSize = 14.0,
    this.quoteOpacity = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF0D1117) : Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: context.colorScheme.onBackground.withOpacity(0.1),
          width: 2,
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
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge - 2),
        child: data == null
            ? _buildEmptyState(context)
            : CustomPaint(
                painter: HeatmapPainter(
                  data: data!,
                  isDarkMode: isDarkMode,
                  verticalPosition: verticalPosition,
                  horizontalPosition: horizontalPosition,
                  scale: scale,
                  opacity: opacity,
                  customQuote: customQuote,
                  paddingTop: paddingTop,
                  paddingBottom: paddingBottom,
                  paddingLeft: paddingLeft,
                  paddingRight: paddingRight,
                  cornerRadius: cornerRadius,
                  quoteFontSize: quoteFontSize,
                  quoteOpacity: quoteOpacity,
                ),
                child: Container(),
              ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wallpaper_outlined,
            size: 64,
            color: context.colorScheme.onBackground.withOpacity(0.3),
          ),
          SizedBox(height: AppTheme.spacing16),
          Text(
            'No data available',
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colorScheme.onBackground.withOpacity(0.6),
            ),
          ),
          SizedBox(height: AppTheme.spacing8),
          Text(
            'Sync your GitHub data first',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onBackground.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
