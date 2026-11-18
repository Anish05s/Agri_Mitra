import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/query_model.dart';
import '../providers/app_provider.dart';
import '../services/speech_service.dart';
import '../widgets/mic_button.dart';
import '../widgets/routing_path_chip.dart';
import 'voice_query_screen.dart';
import 'answer_screen.dart';
import 'photo_diagnosis_screen.dart';
import 'data_cache_screen.dart';
import 'query_queue_screen.dart';
import 'sms_fallback_screen.dart';

/// Main Dashboard Screen for Agri Mitra.
///
/// Features:
/// - AppBar with logo, language selector dropdown (EN/HI/BN), and online/offline toggle chip
/// - Status bar row: green dot + 'Online' or red dot + 'Offline (Demo)' + small sync button
/// - Large center card with the BIG MIC BUTTON (FAB-style, 90px radius, green) with pulse animation when listening
/// - Query input textfield (shows STT result, also editable)
/// - 'Ask' submit button (amber #F9A825)
/// - Recent queries list (last 5) with routing path chip (On-device/Cloud/Queued)
/// - Bottom nav: Home | Diagnose | Data Cache | Queue
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _queryController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _handleQuerySubmit(AppProvider provider) async {
    final queryText = _queryController.text.trim();
    if (queryText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please speak or type your question first'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await provider.submitQuery(queryText);
      _queryController.clear();

      if (!mounted) return;

      // The newly created query is the first in queryHistory
      final latest = provider.queryHistory.isNotEmpty
          ? provider.queryHistory.first
          : QueryModel(
              id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
              queryText: queryText,
              locale: provider.locale,
              createdAt: DateTime.now(),
              status: provider.effectiveOnline ? QueryStatus.cloud : QueryStatus.local,
              path: provider.effectiveOnline ? RoutingPath.cloud : RoutingPath.onDevice,
              answerText: 'Processing advice...',
            );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AnswerScreen(query: latest),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, SpeechService>(
      builder: (context, appProvider, speechService, _) {
        final List<Widget> pages = [
          _buildHomeDashboard(context, appProvider, speechService),
          const PhotoDiagnosisScreen(),
          const DataCacheScreen(),
          const QueryQueueScreen(),
        ];

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9F7),
          appBar: _buildAppBar(context, appProvider),
          body: pages[_currentIndex],
          bottomNavigationBar: _buildBottomNav(context, appProvider),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AppProvider provider) {
    return AppBar(
      elevation: 2,
      backgroundColor: const Color(0xFF2E7D32),
      titleSpacing: 12,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.agriculture,
              size: 24,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Agri Mitra',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
      actions: [
        // Language Selector Dropdown (EN/HI/BN)
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: provider.locale,
              dropdownColor: const Color(0xFF1B5E20),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items: const [
                DropdownMenuItem(
                  value: 'en',
                  child: Text('EN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                DropdownMenuItem(
                  value: 'hi',
                  child: Text('HI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                DropdownMenuItem(
                  value: 'bn',
                  child: Text('BN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
              onChanged: (lang) {
                if (lang != null) provider.setLocale(lang);
              },
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Online / Offline Toggle Chip in AppBar
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ActionChip(
            backgroundColor: provider.isOnline ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
            side: BorderSide(
              color: provider.isOnline ? const Color(0xFF81C784) : const Color(0xFFE57373),
            ),
            avatar: Icon(
              provider.isOnline ? Icons.cloud_done : Icons.cloud_off,
              size: 16,
              color: provider.isOnline ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
            ),
            label: Text(
              provider.isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: provider.isOnline ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
              ),
            ),
            onPressed: () {
              provider.toggleOnlineMode();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHomeDashboard(
    BuildContext context,
    AppProvider provider,
    SpeechService speechService,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status bar row: green dot + 'Online' or red dot + 'Offline (Demo)' + small sync button
          _buildStatusBarRow(context, provider),

          const SizedBox(height: 12),

          // Large Center Card with the BIG MIC BUTTON (FAB-style, 90px radius, green) with pulse animation
          _buildMicInputCard(context, provider, speechService),

          const SizedBox(height: 16),

          // Fallback Banner
          _buildFallbackTile(context),

          const SizedBox(height: 16),

          // Recent Queries Section (Last 5 with routing path chips)
          _buildRecentQueriesSection(context, provider),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusBarRow(BuildContext context, AppProvider provider) {
    final isOnline = provider.isOnline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isOnline ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
              boxShadow: [
                BoxShadow(
                  color: (isOnline ? const Color(0xFF2E7D32) : const Color(0xFFC62828))
                      .withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isOnline ? 'Online • Ready for questions' : 'Offline (Demo) • Local KB Active',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isOnline ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
            ),
          ),
          const Spacer(),
          // Small sync button
          InkWell(
            onTap: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Syncing latest advisory & prices...'),
                  duration: Duration(seconds: 1),
                ),
              );
              await provider.syncNow();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isOnline ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  provider.isSyncing
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.sync,
                          size: 15,
                          color: isOnline ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                        ),
                  const SizedBox(width: 4),
                  Text(
                    'Sync',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isOnline ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicInputCard(
    BuildContext context,
    AppProvider provider,
    SpeechService speechService,
  ) {
    final isListening = speechService.isListening;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Ask Your Farming Question',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isListening ? 'Listening to your voice...' : 'Tap the microphone to speak in your language',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isListening ? const Color(0xFFE65100) : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),

          // BIG MIC BUTTON (FAB-style, 90px radius, green with pulse animation)
          MicButton(
            radius: 48, // 96px diameter core + 160px pulse canvas
            isListening: isListening,
            onTap: () {
              if (isListening) {
                speechService.stopListening();
              } else {
                speechService.startListening(
                  locale: provider.locale,
                  onResult: (spoken) {
                    setState(() {
                      _queryController.text = spoken;
                    });
                  },
                );
              }
            },
          ),

          const SizedBox(height: 14),

          // Dedicated Voice Flow Shortcut
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VoiceQueryScreen()),
              );
            },
            icon: const Icon(Icons.record_voice_over_rounded, color: Color(0xFF2E7D32)),
            label: const Text(
              'Open Full-Screen Voice Mode',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Query Input Text Field (Shows STT result or allows typing)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _queryController,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              maxLines: 2,
              minLines: 1,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                hintText: 'Spoken text appears here or type query...',
                hintStyle: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                border: InputBorder.none,
                suffixIcon: _queryController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _queryController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          const SizedBox(height: 14),

          // 'Ask' submit button (amber #F9A825)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : () => _handleQuerySubmit(provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF9A825), // Amber accent
                foregroundColor: const Color(0xFF3E2723), // Dark text on amber
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, size: 22, color: Color(0xFF3E2723)),
                        SizedBox(width: 8),
                        Text(
                          'Ask Agri Mitra',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackTile(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD54F), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF9A825),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sms_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Internet? Use SMS or Call',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
                Text(
                  'Get advisory via free SMS or Kisan Call Centre',
                  style: TextStyle(fontSize: 12, color: Color(0xFF795548)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5D4037),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SmsFallbackScreen()),
              );
            },
            child: const Text('Open', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentQueriesSection(BuildContext context, AppProvider provider) {
    final recents = provider.queryHistory;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, color: Color(0xFF2E7D32), size: 24),
              const SizedBox(width: 8),
              const Text(
                'Recent Inquiries',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const Spacer(),
              Text(
                '${recents.length} inquiries',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recents.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                'No inquiries yet.\nTap the mic above to ask your first question!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recents.take(5).length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, index) {
                final item = recents[index];
                return InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AnswerScreen(query: item),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.queryText,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF212121),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            RoutingPathChip(
                              path: item.path,
                              isCompact: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.answerText ?? 'No answer recorded',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(item.createdAt),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            const Spacer(),
                            const Text(
                              'View Answer →',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, AppProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        iconSize: 28,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_rounded),
            label: 'Diagnose',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.storage_rounded),
            label: 'Data Cache',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: provider.pendingQueriesCount > 0,
              label: Text('${provider.pendingQueriesCount}'),
              backgroundColor: const Color(0xFFF57C00),
              child: const Icon(Icons.hourglass_top_rounded),
            ),
            label: 'Queue',
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
