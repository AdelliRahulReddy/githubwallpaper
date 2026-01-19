import 'package:flutter/material.dart';
import '../models/contribution_data.dart';
import '../core/date_utils.dart';

class HeatmapPainter extends CustomPainter {
  final CachedContributionData data;
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

  HeatmapPainter({
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
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    final bgPaint = Paint()
      ..color = isDarkMode ? Color(0xFF0D1117) : Color(0xFFFFFFFF);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // SMART LAYOUT: Calculate optimal cell size to fill width
    final daysInMonth = AppDateUtils.getDaysInCurrentMonth();
    final cols = 7;
    final rows = (daysInMonth / cols).ceil();

    // Use padding for margins (default 5% of width on each side)
    final marginX = size.width * 0.05;
    final marginY = size.height * 0.08;
    
    final availableWidth = size.width - (marginX * 2);
    final availableHeight = size.height - (marginY * 2);

    // Calculate cell size to fit width perfectly (edge-to-edge)
    final cellSpacingRatio = 0.15;  // 15% of cell is spacing
    final totalCellUnits = cols + (cols - 1) * cellSpacingRatio;
    final baseCellSize = availableWidth / totalCellUnits;
    
    // Apply user scale
    final cellSize = baseCellSize * scale;
    final cellSpacing = cellSize * cellSpacingRatio;

    // Actual grid dimensions
    final heatmapWidth = (cols * cellSize) + ((cols - 1) * cellSpacing);
    final heatmapHeight = (rows * cellSize) + ((rows - 1) * cellSpacing);

    // Layout sections with proportional spacing
    final headerHeight = cellSize * 2.5;
    final headerGap = cellSize * 0.8;
    final statsHeight = cellSize * 2;
    final statsGap = cellSize * 0.5;
    final quoteHeight = customQuote.isNotEmpty ? cellSize * 1.5 : 0.0;
    
    final totalContentHeight = headerHeight + headerGap + heatmapHeight + statsGap + statsHeight + (quoteHeight > 0 ? statsGap + quoteHeight : 0);

    // Center content vertically (with user position offset)
    final centerX = marginX + (availableWidth - heatmapWidth) * horizontalPosition;
    final centerY = marginY + (availableHeight - totalContentHeight) * verticalPosition;

    canvas.save();
    canvas.translate(centerX, centerY);

    double currentY = 0;

    // 1. Draw month header (centered above grid)
    _drawCenteredHeader(canvas, heatmapWidth, cellSize);
    currentY += headerHeight + headerGap;

    // 2. Draw heatmap grid
    canvas.save();
    canvas.translate(0, currentY);
    _drawHeatmapGrid(canvas, cellSize, cellSpacing, cols, rows, daysInMonth);
    canvas.restore();
    currentY += heatmapHeight + statsGap;

    // 3. Draw stats row (centered below grid)
    canvas.save();
    canvas.translate(0, currentY);
    _drawCenteredStats(canvas, heatmapWidth, cellSize);
    canvas.restore();
    currentY += statsHeight;

    // 4. Draw quote if provided (centered below stats)
    if (customQuote.isNotEmpty) {
      currentY += statsGap;
      canvas.save();
      canvas.translate(0, currentY);
      _drawCenteredQuote(canvas, heatmapWidth, cellSize);
      canvas.restore();
    }

    canvas.restore();
  }

  void _drawCenteredHeader(Canvas canvas, double heatmapWidth, double cellSize) {
    final monthName = AppDateUtils.getCurrentMonthName();
    final year = DateTime.now().year;
    final headerText = '$monthName $year';

    final titlePainter = TextPainter(
      text: TextSpan(
        text: headerText,
        style: TextStyle(
          color: (isDarkMode ? Colors.white : Colors.black).withOpacity(opacity),
          fontSize: cellSize * 1.8,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();
    
    // Center the header
    final headerX = (heatmapWidth - titlePainter.width) / 2;
    titlePainter.paint(canvas, Offset(headerX, 0));
  }

  void _drawHeatmapGrid(
    Canvas canvas,
    double cellSize,
    double cellSpacing,
    int cols,
    int rows,
    int daysInMonth,
  ) {
    final currentDay = AppDateUtils.getCurrentDayOfMonth();

    for (int day = 1; day <= daysInMonth; day++) {
      final row = (day - 1) ~/ cols;
      final col = (day - 1) % cols;

      final x = col * (cellSize + cellSpacing);
      final y = row * (cellSize + cellSpacing);

      final contributions = data.dailyContributions[day] ?? 0;
      final color = _getContributionColor(contributions);

      final cellPaint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      final radius = cellSize * 0.15;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, cellSize, cellSize),
        Radius.circular(cornerRadius > 0 ? cornerRadius : radius),
      );

      canvas.drawRRect(rect, cellPaint);

      // Draw day number inside cell
      final dayPainter = TextPainter(
        text: TextSpan(
          text: '$day',
          style: TextStyle(
            color: _getTextColorForCell(contributions, day <= currentDay).withOpacity(opacity),
            fontSize: cellSize * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      dayPainter.layout();

      final textX = x + (cellSize - dayPainter.width) / 2;
      final textY = y + (cellSize - dayPainter.height) / 2;
      dayPainter.paint(canvas, Offset(textX, textY));
    }
  }

  void _drawCenteredStats(Canvas canvas, double heatmapWidth, double cellSize) {
    final stats = [
      {'label': 'Total', 'value': '${data.totalContributions}', 'icon': '📊'},
      {'label': 'Streak', 'value': '${data.currentStreak}d', 'icon': '🔥'},
      {'label': 'Today', 'value': '${data.todayCommits}', 'icon': '✨'},
    ];

    final statWidth = heatmapWidth / stats.length;
    
    for (int i = 0; i < stats.length; i++) {
      final stat = stats[i];
      final centerX = statWidth * i + statWidth / 2;

      // Icon
      final iconPainter = TextPainter(
        text: TextSpan(
          text: stat['icon'],
          style: TextStyle(fontSize: cellSize * 0.9),
        ),
        textDirection: TextDirection.ltr,
      );
      iconPainter.layout();

      // Value
      final valuePainter = TextPainter(
        text: TextSpan(
          text: stat['value'],
          style: TextStyle(
            color: (isDarkMode ? Colors.white : Colors.black).withOpacity(opacity),
            fontSize: cellSize * 0.7,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      valuePainter.layout();

      // Label
      final labelPainter = TextPainter(
        text: TextSpan(
          text: stat['label'],
          style: TextStyle(
            color: (isDarkMode ? Colors.white70 : Colors.black54).withOpacity(opacity),
            fontSize: cellSize * 0.45,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();

      // Draw centered vertically stacked
      final totalWidth = iconPainter.width + 8 + valuePainter.width;
      final startX = centerX - totalWidth / 2;

      iconPainter.paint(canvas, Offset(startX, 0));
      valuePainter.paint(canvas, Offset(startX + iconPainter.width + 8, (iconPainter.height - valuePainter.height) / 2));
      labelPainter.paint(canvas, Offset(centerX - labelPainter.width / 2, iconPainter.height + 4));
    }
  }

  void _drawCenteredQuote(Canvas canvas, double heatmapWidth, double cellSize) {
    final quotePainter = TextPainter(
      text: TextSpan(
        text: '"$customQuote"',
        style: TextStyle(
          color: (isDarkMode ? Colors.white70 : Colors.black54).withOpacity(opacity * quoteOpacity),
          fontSize: cellSize * 0.55,
          fontStyle: FontStyle.italic,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      textAlign: TextAlign.center,
    );
    quotePainter.layout(maxWidth: heatmapWidth);
    
    // Center quote
    final quoteX = (heatmapWidth - quotePainter.width) / 2;
    quotePainter.paint(canvas, Offset(quoteX, 0));
  }

  Color _getContributionColor(int contributions) {
    if (contributions == 0) {
      return isDarkMode ? Color(0xFF161B22) : Color(0xFFEBEDF0);
    } else if (contributions <= 3) {
      return Color(0xFF0E4429);
    } else if (contributions <= 6) {
      return Color(0xFF006D32);
    } else if (contributions <= 9) {
      return Color(0xFF26A641);
    } else {
      return Color(0xFF39D353);
    }
  }

  Color _getTextColorForCell(int contributions, bool isPast) {
    if (!isPast) {
      return isDarkMode ? Colors.white24 : Colors.black26;
    }
    if (contributions == 0) {
      return isDarkMode ? Colors.white54 : Colors.black54;
    } else {
      return Colors.white;
    }
  }

  @override
  bool shouldRepaint(HeatmapPainter oldDelegate) {
    return oldDelegate.verticalPosition != verticalPosition ||
        oldDelegate.horizontalPosition != horizontalPosition ||
        oldDelegate.scale != scale ||
        oldDelegate.opacity != opacity ||
        oldDelegate.customQuote != customQuote ||
        oldDelegate.paddingTop != paddingTop ||
        oldDelegate.paddingBottom != paddingBottom ||
        oldDelegate.paddingLeft != paddingLeft ||
        oldDelegate.paddingRight != paddingRight ||
        oldDelegate.cornerRadius != cornerRadius ||
        oldDelegate.quoteFontSize != quoteFontSize ||
        oldDelegate.quoteOpacity != quoteOpacity ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}
