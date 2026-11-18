import 'package:flutter/material.dart';

/// Animated banner displayed at the top of screens showing online/offline status
/// along with an interactive toggle switch for demo and simulation purposes.
class ConnectivityBanner extends StatelessWidget {
  final bool isOnline;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onSyncPressed;

  const ConnectivityBanner({
    super.key,
    required this.isOnline,
    this.onToggle,
    this.onSyncPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isOnline
            ? (isDark ? const Color(0xFF1B5E20) : const Color(0xFFE8F5E9))
            : (isDark ? const Color(0xFFB71C1C) : const Color(0xFFFFEBEE)),
        border: Border(
          bottom: BorderSide(
            color: isOnline
                ? const Color(0xFF2E7D32).withOpacity(0.5)
                : const Color(0xFFC62828).withOpacity(0.5),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Animated Status Dot & Pulse
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
              boxShadow: [
                BoxShadow(
                  color: (isOnline ? const Color(0xFF2E7D32) : const Color(0xFFC62828))
                      .withOpacity(0.6),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Connectivity status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isOnline ? 'Online (Cloud AI Active)' : 'Offline (Local Knowledge Base)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isOnline ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
                  ),
                ),
                Text(
                  isOnline
                      ? 'Sync enabled • Real-time advisory'
                      : 'Queries saved to queue • Cached answers',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOnline
                        ? const Color(0xFF2E7D32).withOpacity(0.8)
                        : const Color(0xFFC62828).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          // Optional manual sync button if offline
          if (!isOnline && onSyncPressed != null) ...[
            IconButton(
              tooltip: 'Sync Now',
              icon: const Icon(Icons.sync_rounded, size: 22, color: Color(0xFFC62828)),
              onPressed: onSyncPressed,
            ),
          ],

          // Demo Mode Toggle Switch
          if (onToggle != null) ...[
            const SizedBox(width: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Demo',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: isOnline,
                    activeColor: const Color(0xFF2E7D32),
                    inactiveThumbColor: const Color(0xFFC62828),
                    inactiveTrackColor: const Color(0xFFFFCDD2),
                    onChanged: onToggle,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
