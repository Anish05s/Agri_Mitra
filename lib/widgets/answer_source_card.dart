import 'package:flutter/material.dart';

/// A card widget showing advisory provenance, institutional source,
/// expert verification credentials, and sync timestamps.
/// Used in both the Answer screen and offline Data Cache screens.
class AnswerSourceCard extends StatelessWidget {
  final String source;
  final String? verifiedBy;
  final String? lastUpdated;
  final String? lastSynced;
  final bool isOffline;

  const AnswerSourceCard({
    super.key,
    required this.source,
    this.verifiedBy,
    this.lastUpdated,
    this.lastSynced,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9), // Light green tint
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with verified icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF2E7D32),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Source & Verification',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const Spacer(),
              if (isOffline)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0B2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.offline_pin_rounded, size: 14, color: Color(0xFFE65100)),
                      SizedBox(width: 4),
                      Text(
                        'Offline Cache',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Divider(height: 18, thickness: 1, color: Color(0xFFC8E6C9)),

          // Source line
          _buildInfoRow(
            icon: Icons.account_balance_rounded,
            label: 'Source:',
            value: source,
          ),

          // Verified By line
          if (verifiedBy != null && verifiedBy!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildInfoRow(
              icon: Icons.person_pin_rounded,
              label: 'Verified By:',
              value: verifiedBy!,
            ),
          ],

          // Last Updated line
          if (lastUpdated != null && lastUpdated!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildInfoRow(
              icon: Icons.edit_calendar_rounded,
              label: 'Last Updated:',
              value: lastUpdated!,
            ),
          ],

          // Last Synced line
          if (lastSynced != null && lastSynced!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildInfoRow(
              icon: Icons.sync_alt_rounded,
              label: 'Last Synced:',
              value: lastSynced!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF33691E),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF212121),
            ),
          ),
        ),
      ],
    );
  }
}
