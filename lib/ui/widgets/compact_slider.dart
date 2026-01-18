import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class CompactSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final bool isDarkMode;
  final String? suffix;

  const CompactSlider({
    Key? key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    required this.isDarkMode,
    this.suffix,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode
        ? AppConstants.darkTextPrimary
        : AppConstants.lightTextPrimary;

    final accentColor = isDarkMode
        ? AppConstants.darkAccent
        : AppConstants.lightAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${_formatValue(value)}${suffix ?? ''}',
              style: TextStyle(
                color: accentColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: accentColor,
            inactiveTrackColor: isDarkMode
                ? AppConstants.darkBorder
                : AppConstants.lightBorder,
            thumbColor: accentColor,
            overlayColor: accentColor.withOpacity(0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  String _formatValue(double value) {
    if (suffix == '%') {
      return (value * 100).toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}
