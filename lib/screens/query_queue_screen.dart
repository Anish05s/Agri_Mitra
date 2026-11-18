import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/query_model.dart';
import '../providers/app_provider.dart';
import '../widgets/connectivity_banner.dart';
import 'answer_screen.dart';

/// Screen managing offline queries waiting in the SQLite queue for sync,
/// complete with visual status chips and expandable expert answer cards.
///
/// Features:
/// - AppBar with 'Sync Now' button
/// - Empty state: illustration + 'No pending queries'
/// - List of queued queries:
///   - Query text (truncated)
///   - Status chip: Queued (grey) | Sent (blue) | Answered (green)
///   - Timestamp
///   - If answered: expandable expert answer card
/// - Connectivity banner at top (red/green)
/// - 'Simulate Sync' button for demo purposes
class QueryQueueScreen extends StatefulWidget {
  const QueryQueueScreen({super.key});

  @override
  State<QueryQueueScreen> createState() => _QueryQueueScreenState();
}

class _QueryQueueScreenState extends State<QueryQueueScreen> {
  Future<void> _handleSync(AppProvider provider) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connecting to server and syncing queries...'),
        duration: Duration(seconds: 1),
      ),
    );
    await provider.syncNow();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sync completed! Answers updated.'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        // Queued or pending items
        final queuedQueries = provider.queryHistory.where((q) {
          return q.status == QueryStatus.queued ||
              q.status == QueryStatus.sent ||
              q.path == RoutingPath.queued ||
              q.status == QueryStatus.answered;
        }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAF7),
          appBar: AppBar(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            elevation: 2,
            title: const Text(
              'Query Queue & Sync',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            actions: [
              TextButton.icon(
                onPressed: provider.isSyncing ? null : () => _handleSync(provider),
                icon: provider.isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.sync_rounded, color: Colors.white),
                label: const Text(
                  'Sync Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // Connectivity banner at top (red/green with switch)
              ConnectivityBanner(
                isOnline: provider.isOnline,
                onToggle: (_) => provider.toggleOnlineMode(),
                onSyncPressed: () => _handleSync(provider),
              ),

              // Queue List or Empty State
              Expanded(
                child: queuedQueries.isEmpty
                    ? _buildEmptyState(context, provider)
                    : _buildQueueList(context, provider, queuedQueries),
              ),

              // Bottom 'Simulate Sync' button for demo purposes
              _buildSimulateSyncFooter(context, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFA5D6A7), width: 2),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 72,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No pending queries',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All queries have been synced. When offline, any questions you ask will be saved here automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                provider.submitQuery('Sample query: What is the seed rate for Potato per acre?');
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2E7D32)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.add_rounded, color: Color(0xFF2E7D32)),
              label: const Text(
                'Add Test Query',
                style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueList(
    BuildContext context,
    AppProvider provider,
    List<QueryModel> queries,
  ) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: queries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final query = queries[index];
        final isAnswered = query.status == QueryStatus.answered || query.status == QueryStatus.local;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isAnswered ? const Color(0xFF81C784) : Colors.grey.shade300,
              width: isAnswered ? 1.8 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: isAnswered && index == 0,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      query.queryText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF212121),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(query.status),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(query.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFFF9FBF9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            isAnswered ? Icons.verified_user : Icons.hourglass_empty,
                            color: isAnswered ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAnswered ? 'Expert / AI Answer:' : 'Status Details:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isAnswered ? const Color(0xFF1B5E20) : const Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        query.answerText ?? 'Awaiting sync to fetch expert answer...',
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
                        ),
                      ),
                      if (query.expertAnswer != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          query.expertAnswer!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AnswerScreen(query: query),
                                ),
                              );
                            },
                            icon: const Icon(Icons.open_in_new, size: 16, color: Color(0xFF2E7D32)),
                            label: const Text(
                              'Full Advice View',
                              style: TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(QueryStatus status) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status) {
      case QueryStatus.answered:
      case QueryStatus.local:
      case QueryStatus.cloud:
        label = 'Answered';
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32); // Green
        icon = Icons.check_circle_rounded;
        break;
      case QueryStatus.sent:
        label = 'Sent';
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF0D47A1); // Blue
        icon = Icons.cloud_upload_rounded;
        break;
      case QueryStatus.queued:
      default:
        label = 'Queued';
        bgColor = const Color(0xFFEEEEEE);
        textColor = Colors.grey.shade700; // Grey
        icon = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulateSyncFooter(BuildContext context, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: provider.isSyncing ? null : () => _handleSync(provider),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF9A825), // Amber accent
              foregroundColor: const Color(0xFF3E2723),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            icon: provider.isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3E2723)),
                  )
                : const Icon(Icons.sync_problem_rounded, color: Color(0xFF3E2723)),
            label: Text(
              provider.isSyncing ? 'Simulating Server Sync...' : 'Simulate Sync',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('dd MMM, hh:mm a').format(dt);
  }
}
