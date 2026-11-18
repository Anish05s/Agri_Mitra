import 'package:flutter/material.dart';
import '../models/query_model.dart';

/// A custom chip indicating where the advisory answer was resolved or routed.
///
/// Designed with high-contrast colors and large, recognizable icons for
/// low-literacy farmers:
/// - On-device: Blue (cached local knowledge base)
/// - On-device AI: Purple (lightweight offline SLM)
/// - Cloud AI: Green (full cloud AI engine)
/// - Queued: Orange (offline, pending network sync)
class RoutingPathChip extends StatelessWidget {
  final RoutingPath? path;
  final String? rawPath;
  final bool isCompact;

  const RoutingPathChip({
    super.key,
    this.path,
    this.rawPath,
    this.isCompact = false,
  });

  /// Factory constructor to parse from a raw string identifier or display label.
  factory RoutingPathChip.fromString(String raw, {Key? key, bool isCompact = false}) {
    return RoutingPathChip(
      key: key,
      rawPath: raw,
      isCompact: isCompact,
    );
  }

  RoutingPath _resolvePath() {
    if (path != null) return path!;
    final lower = (rawPath ?? '').toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    if (lower.contains('device_ai') || lower.contains('slm') || lower.contains('local_ai')) {
      return RoutingPath.onDeviceAI;
    } else if (lower.contains('device') || lower.contains('cache') || lower.contains('local')) {
      return RoutingPath.onDevice;
    } else if (lower.contains('cloud') || lower.contains('online')) {
      return RoutingPath.cloud;
    } else {
      return RoutingPath.queued;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolvePath();
    final config = _getConfig(resolved);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 14,
        vertical: isCompact ? 5 : 8,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: config.borderColor.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: isCompact ? 16 : 20,
            color: config.textColor,
          ),
          const SizedBox(width: 6),
          Text(
            config.label,
            style: TextStyle(
              color: config.textColor,
              fontSize: isCompact ? 13 : 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  _RoutingChipConfig _getConfig(RoutingPath path) {
    switch (path) {
      case RoutingPath.onDevice:
        return const _RoutingChipConfig(
          label: 'On-device Answer',
          icon: Icons.phone_android_rounded,
          backgroundColor: Color(0xFFE3F2FD),
          borderColor: Color(0xFF1976D2),
          textColor: Color(0xFF0D47A1),
        );
      case RoutingPath.onDeviceAI:
        return const _RoutingChipConfig(
          label: 'On-device AI',
          icon: Icons.psychology_rounded,
          backgroundColor: Color(0xFFF3E5F5),
          borderColor: Color(0xFF7B1FA2),
          textColor: Color(0xFF4A148C),
        );
      case RoutingPath.cloud:
        return const _RoutingChipConfig(
          label: 'Cloud AI',
          icon: Icons.cloud_done_rounded,
          backgroundColor: Color(0xFFE8F5E9),
          borderColor: Color(0xFF2E7D32),
          textColor: Color(0xFF1B5E20),
        );
      case RoutingPath.queued:
        return const _RoutingChipConfig(
          label: 'Queued',
          icon: Icons.schedule_rounded,
          backgroundColor: Color(0xFFFFF3E0),
          borderColor: Color(0xFFF57C00),
          textColor: Color(0xFFE65100),
        );
    }
  }
}

class _RoutingChipConfig {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _RoutingChipConfig({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });
}
