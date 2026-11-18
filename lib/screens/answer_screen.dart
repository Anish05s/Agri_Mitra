import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/query_model.dart';
import '../providers/app_provider.dart';
import '../services/speech_service.dart';
import '../widgets/routing_path_chip.dart';
import '../widgets/confidence_badge.dart';
import '../widgets/answer_source_card.dart';
import 'sms_fallback_screen.dart';

/// Detailed Answer Screen for an agricultural advisory inquiry.
///
/// Features:
/// - Grey Query text container at the top
/// - Dual indicators: RoutingPathChip and ConfidenceBadge
/// - If queued: Animated Queued → Sent → Answered progress stepper
/// - High-contrast readable answer text (18sp)
/// - Integrated Text-to-Speech (TTS) speaker button
/// - Detailed AnswerSourceCard (source, verified-by, last-updated, last-synced)
/// - Share / SMS action triggers
/// - Follow-up question input section (emphasized when confidence is low)
class AnswerScreen extends StatefulWidget {
  final QueryModel query;

  const AnswerScreen({super.key, required this.query});

  @override
  State<AnswerScreen> createState() => _AnswerScreenState();
}

class _AnswerScreenState extends State<AnswerScreen> {
  final TextEditingController _followUpController = TextEditingController();
  bool _isSubmittingFollowUp = false;
  late QueryModel _currentQuery;

  @override
  void initState() {
    super.initState();
    _currentQuery = widget.query;
  }

  @override
  void dispose() {
    _followUpController.dispose();
    super.dispose();
  }

  Future<void> _handleFollowUpSubmit(AppProvider provider) async {
    final text = _followUpController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmittingFollowUp = true);

    try {
      final combined = '${_currentQuery.queryText} -> Follow-up: $text';
      await provider.submitQuery(combined);
      _followUpController.clear();

      if (!mounted) return;
      if (provider.queryHistory.isNotEmpty) {
        setState(() {
          _currentQuery = provider.queryHistory.first;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Follow-up answered!'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmittingFollowUp = false);
    }
  }

  void _shareViaSms() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SmsFallbackScreen(
          initialQuery: _currentQuery.queryText,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, SpeechService>(
      builder: (context, provider, speechService, _) {
        final isQueued = _currentQuery.status == QueryStatus.queued ||
            _currentQuery.path == RoutingPath.queued;
        final conf = _currentQuery.confidence ?? 0.0;
        final isLowConfidence = conf < 0.70;

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAF7),
          appBar: AppBar(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            elevation: 2,
            title: const Text(
              'Farming Advice',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            actions: [
              IconButton(
                tooltip: 'Share Advice via SMS / App',
                icon: const Icon(Icons.share_rounded),
                onPressed: _shareViaSms,
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Query Text Container at Top (Grey background card)
                _buildQueryHeaderCard(_currentQuery.queryText),

                const SizedBox(height: 14),

                // 2. Routing Path Chip & Confidence Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RoutingPathChip(path: _currentQuery.path),
                    ConfidenceBadge(score: _currentQuery.confidence),
                  ],
                ),

                const SizedBox(height: 16),

                // 3. If Queued: Queue Status Progress Stepper (Queued -> Sent -> Answered)
                if (isQueued) ...[
                  _buildQueueStatusStepper(_currentQuery.status),
                  const SizedBox(height: 16),
                ],

                // 4. Main Answer Text Card (Large, readable)
                _buildAnswerContentCard(context, provider, _currentQuery),

                const SizedBox(height: 16),

                // 5. Source Card (Provenance, verified-by, last-updated, last-synced)
                AnswerSourceCard(
                  source: _currentQuery.source ?? 'ICAR Agronomy Repository',
                  verifiedBy: _currentQuery.verifiedBy,
                  lastUpdated: _currentQuery.lastUpdated,
                  lastSynced: _currentQuery.lastSyncedAt?.toIso8601String().substring(0, 10),
                  isOffline: _currentQuery.status == QueryStatus.local || _currentQuery.status == QueryStatus.queued,
                ),

                const SizedBox(height: 16),

                // 6. Action Bar: TTS Button & Share / SMS Button
                _buildActionButtons(provider, speechService),

                const SizedBox(height: 20),

                // 7. Follow-Up Question Section (Shown when low confidence or user needs clarity)
                _buildFollowUpSection(provider, isLowConfidence),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQueryHeaderCard(String queryText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF1), // Soft grey background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCFD8DC), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF455A64),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Question',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  queryText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF263238),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueStatusStepper(QueryStatus status) {
    int activeStep = 0;
    if (status == QueryStatus.sent) activeStep = 1;
    if (status == QueryStatus.answered) activeStep = 2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.hourglass_top_rounded, color: Color(0xFFE65100), size: 20),
              SizedBox(width: 8),
              Text(
                'Offline Queue Sync Progress',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE65100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildStepItem('1. Queued', 0, activeStep),
              _buildStepConnector(activeStep >= 1),
              _buildStepItem('2. Sent', 1, activeStep),
              _buildStepConnector(activeStep >= 2),
              _buildStepItem('3. Answered', 2, activeStep),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            activeStep == 0
                ? 'Your query is saved locally. It will upload automatically as soon as internet connection is available.'
                : activeStep == 1
                    ? 'Uploaded to Agronomy cloud. Specialist review in progress.'
                    : 'Expert review completed.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.brown.shade800,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String title, int stepIndex, int currentStep) {
    final isDone = currentStep > stepIndex;
    final isActive = currentStep == stepIndex;

    Color color;
    if (isDone || isActive) {
      color = const Color(0xFF2E7D32);
    } else {
      color = Colors.grey.shade400;
    }

    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? const Color(0xFF2E7D32) : Colors.white,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            color: isActive ? const Color(0xFF2E7D32) : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isDone) {
    return Expanded(
      child: Container(
        height: 3,
        color: isDone ? const Color(0xFF2E7D32) : Colors.grey.shade300,
        margin: const EdgeInsets.only(bottom: 16),
      ),
    );
  }

  Widget _buildAnswerContentCard(
    BuildContext context,
    AppProvider provider,
    QueryModel query,
  ) {
    final answerText = query.answerText ?? 'No advice content available.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA5D6A7), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_alt_rounded, color: Color(0xFF2E7D32), size: 24),
              const SizedBox(width: 8),
              const Text(
                'Recommended Action',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const Spacer(),
              if (query.status == QueryStatus.local)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Last synced: ${query.lastSyncedAt?.toIso8601String().substring(0, 10) ?? "Offline"}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 20, thickness: 1, color: Color(0xFFE0E0E0)),
          Text(
            answerText,
            style: const TextStyle(
              fontSize: 18,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B1B1B),
            ),
          ),
          if (query.expertAnswer != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF81C784)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified, color: Color(0xFF2E7D32), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      query.expertAnswer!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppProvider provider, SpeechService speechService) {
    final answerText = _currentQuery.answerText ?? '';

    return Row(
      children: [
        // TTS Play / Stop Button
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                if (speechService.isSpeaking) {
                  speechService.stop();
                } else {
                  speechService.speak(answerText, provider.locale);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: speechService.isSpeaking
                    ? const Color(0xFFE65100)
                    : const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              icon: Icon(
                speechService.isSpeaking ? Icons.volume_off : Icons.volume_up,
                size: 22,
              ),
              label: Text(
                speechService.isSpeaking ? 'Stop Audio' : 'Listen (TTS)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Share / SMS Button
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _shareViaSms,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFF9A825), width: 2),
                backgroundColor: const Color(0xFFFFF8E1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.sms_outlined, color: Color(0xFFE65100), size: 20),
              label: const Text(
                'SMS Advice',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE65100),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFollowUpSection(AppProvider provider, bool isLowConfidence) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isLowConfidence ? const Color(0xFFFFF8E1) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLowConfidence ? const Color(0xFFF9A825) : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isLowConfidence ? Icons.warning_amber_rounded : Icons.add_comment_rounded,
                color: isLowConfidence ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                isLowConfidence
                    ? 'Need More Clarity? Ask Follow-up'
                    : 'Ask Follow-up Question',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isLowConfidence ? const Color(0xFFE65100) : const Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isLowConfidence
                ? 'Confidence is medium or low. Providing more details or asking a follow-up helps improve recommendation accuracy.'
                : 'Have questions about dosage, organic alternatives, or application timing?',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),

          // Quick Suggested Follow-Up Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickChip('What is the exact dosage per acre?', provider),
                const SizedBox(width: 8),
                _buildQuickChip('Any organic / bio alternatives?', provider),
                const SizedBox(width: 8),
                _buildQuickChip('Will rain wash this away?', provider),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Follow-up Input TextField + Submit Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _followUpController,
                  decoration: InputDecoration(
                    hintText: 'Type follow-up question here...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSubmittingFollowUp ? null : () => _handleFollowUpSubmit(provider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9A825),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmittingFollowUp
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String chipText, AppProvider provider) {
    return ActionChip(
      backgroundColor: const Color(0xFFE8F5E9),
      side: const BorderSide(color: Color(0xFFA5D6A7)),
      label: Text(
        chipText,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1B5E20)),
      ),
      onPressed: () {
        _followUpController.text = chipText;
        _handleFollowUpSubmit(provider);
      },
    );
  }
}
