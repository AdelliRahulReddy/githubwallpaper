import 'package:flutter/material.dart';
import '../models/contribution_data.dart';
import '../core/constants.dart';
import '../core/date_utils.dart';

class HeatmapPainter extends CustomPainter {
  final CachedContributionData data;
  final bool isDarkMode;
  final double verticalPosition;
  final double horizontalPosition;
  final double scale;
  final String customQuote;

  HeatmapPainter({
    required this.data,
    required this.isDarkMode,
    required this.verticalPosition,
    required this.horizontalPosition,
    required this.scale,
    this.customQuote = '',
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawStatsHeader(canvas, size);
    _drawHeatmap(canvas, size);
    if (customQuote.isNotEmpty) {
      _drawQuote(canvas, size);
    }
  }

  void _drawStatsHeader(Canvas canvas, Size size) {
    final textColor = isDarkMode
        ? AppConstants.darkTextPrimary
        : AppConstants.lightTextPrimary;

    final monthName = AppDateUtils.getCurrentMonthName();
    final year = DateTime.now().year;
    final totalContributions = data.totalContributions;
    final currentStreak = data.currentStreak;

    final headerY = size.height * 0.1;

    final monthStyle = TextStyle(
      color: textColor,
      fontSize: 32 * scale,
      fontWeight: FontWeight.bold,
    );

    final monthPainter = TextPainter(
      text: TextSpan(text: '$monthName $year', style: monthStyle),
      textDirection: TextDirection.ltr,
    );
    monthPainter.layout();
    monthPainter.paint(
      canvas,
      Offset((size.width - monthPainter.width) / 2, headerY),
    );

    final statsY = headerY + monthPainter.height + 20;
    final statsStyle = TextStyle(
      color: isDarkMode
          ? AppConstants.darkTextSecondary
          : AppConstants.lightTextSecondary,
      fontSize: 16 * scale,
    );

    final statsText =
        '$totalContributions contributions • $currentStreak day streak';
    final statsPainter = TextPainter(
      text: TextSpan(text: statsText, style: statsStyle),
      textDirection: TextDirection.ltr,
    );
    statsPainter.layout();
    statsPainter.paint(
      canvas,
      Offset((size.width - statsPainter.width) / 2, statsY),
    );
  }

  void _drawHeatmap(Canvas canvas, Size size) {
    final boxSize = AppConstants.boxSize * scale;
    final spacing = AppConstants.boxSpacing * scale;

    final maxDaysInWeek = 7;
    final totalWeeks = data.weeks.length;

    final gridWidth = totalWeeks * (boxSize + spacing);
    final gridHeight = maxDaysInWeek * (boxSize + spacing);

    final startX = (size.width - gridWidth) * horizontalPosition;
    final startY = size.height * verticalPosition;

    _drawDayLabels(canvas, startX, startY, boxSize, spacing);

    double currentX = startX + 40;

    for (var week in data.weeks) {
      double currentY = startY;

      for (var day in week.contributionDays) {
        _drawContributionBox(canvas, Offset(currentX, currentY), boxSize, day);

        currentY += boxSize + spacing;
      }

      currentX += boxSize + spacing;
    }
  }

  void _drawDayLabels(
    Canvas canvas,
    double startX,
    double startY,
    double boxSize,
    double spacing,
  ) {
    final labels = ['Mon', 'Wed', 'Fri'];
    final indices = [0, 2, 4];

    final labelStyle = TextStyle(
      color: isDarkMode
          ? AppConstants.darkTextSecondary
          : AppConstants.lightTextSecondary,
      fontSize: 10 * scale,
    );

    for (var i = 0; i < labels.length; i++) {
      final labelY = startY + (indices[i] * (boxSize + spacing));

      final painter = TextPainter(
        text: TextSpan(text: labels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      );
      painter.layout();
      painter.paint(canvas, Offset(startX - 35, labelY));
    }
  }

  void _drawContributionBox(
    Canvas canvas,
    Offset position,
    double size,
    ContributionDay day,
  ) {
    final level = day.getLevelInt();
    final color = _getColorForLevel(level);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(position.dx, position.dy, size, size),
      Radius.circular(AppConstants.boxRadius),
    );

    canvas.drawRRect(rect, paint);

    if (day.isToday()) {
      final borderPaint = Paint()
        ..color = AppConstants.todayHighlight
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppConstants.todayBorderWidth;

      canvas.drawRRect(rect, borderPaint);
    }
  }

  Color _getColorForLevel(int level) {
    if (isDarkMode) {
      switch (level) {
        case 0:
          return AppConstants.level0;
        case 1:
          return AppConstants.level1;
        case 2:
          return AppConstants.level2;
        case 3:
          return AppConstants.level3;
        case 4:
          return AppConstants.level4;
        default:
          return AppConstants.level0;
      }
    } else {
      switch (level) {
        case 0:
          return AppConstants.level0Light;
        case 1:
          return AppConstants.level1Light;
        case 2:
          return AppConstants.level2Light;
        case 3:
          return AppConstants.level3Light;
        case 4:
          return AppConstants.level4Light;
        default:
          return AppConstants.level0Light;
      }
    }
  }

  void _drawQuote(Canvas canvas, Size size) {
    final quoteStyle = TextStyle(
      color: isDarkMode
          ? AppConstants.darkTextSecondary
          : AppConstants.lightTextSecondary,
      fontSize: 14 * scale,
      fontStyle: FontStyle.italic,
    );

    final quotePainter = TextPainter(
      text: TextSpan(text: '"$customQuote"', style: quoteStyle),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      textAlign: TextAlign.center,
    );

    quotePainter.layout(maxWidth: size.width * 0.8);
    quotePainter.paint(
      canvas,
      Offset((size.width - quotePainter.width) / 2, size.height * 0.85),
    );
  }

  @override
  bool shouldRepaint(HeatmapPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.isDarkMode != isDarkMode ||
        oldDelegate.verticalPosition != verticalPosition ||
        oldDelegate.horizontalPosition != horizontalPosition ||
        oldDelegate.scale != scale ||
        oldDelegate.customQuote != customQuote;
  }
}
