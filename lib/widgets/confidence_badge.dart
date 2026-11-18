import 'package:flutter/material.dart';

/// A badge displaying model prediction confidence with distinct high-contrast
/// color coding and icons for farmer readability.
///
/// Rules:
/// - HIGH (>= 0.75): Green background, shield check icon
/// - MEDIUM (0.50 - 0.74): Amber background, info icon
/// - LOW (< 0.50): Red background, alert/warning icon
class ConfidenceBadge extends StatelessWidget {
  /// Confidence level expressed as a value between 0.0 and 1.0 (or 0 to 100).
  final double? score;

  /// Optional override for font size.
  final double fontSize;

  /// Whether to display in compact mode.
  final bool isCompact;

  const ConfidenceBadge({
    super.key,
    required this.score,
    this.fontSize = 15,
    this.isCompact = false,
  });

  /// Normalizes score between 0.0 and 1.0.
  double get _normalizedScore {
    final s = score ?? 0.0;
    if (s > 1.0) return (s / 100.0).clamp(0.0, 1.0);
    return s.clamp(0.0, 1.0);
  }

  int get _percentage => (_normalizedScore * 100).round();

  @override
  Widget build(BuildContext context) {
    final norm = _normalizedScore;
    Color bgColor;
    Color textColor;
    Color borderColor;
    String label;
    IconData icon;

    if (norm >= 0.75) {
      label = 'HIGH';
      bgColor = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF1B5E20);
      borderColor = const Color(0xFF2E7D32);
      icon = Icons.verified_rounded;
    } else if (norm >= 0.50) {
      label = 'MEDIUM';
      bgColor = const Color(0xFFFFF8E1);
      textColor = const Color(0xFFE65100);
      borderColor = const Color(0xFFF9A825);
      icon = Icons.help_outline_rounded;
    } else {
      label = 'LOW';
      bgColor = const Color(0xFFFFEBEE);
      textColor = const Color(0xFFB71C1C);
      borderColor = const Color(0xFFD32F2F);
      icon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 14,
        vertical: isCompact ? 4 : 7,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.12),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 16 : 20, color: textColor),
          const SizedBox(width: 6),
          Text(
            '$label ($_percentage%)',
            style: TextStyle(
              color: textColor,
              fontSize: isCompact ? fontSize - 2 : fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
