import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/query_model.dart';
import '../providers/app_provider.dart';
import '../services/speech_service.dart';
import '../widgets/mic_button.dart';
import '../widgets/routing_path_chip.dart';
import '../widgets/confidence_badge.dart';
import '../widgets/answer_source_card.dart';
import '../widgets/connectivity_banner.dart';
import 'sms_fallback_screen.dart';

/// Dedicated full-screen voice query interface designed for hands-free and low-literacy farmers.
///
/// Features:
/// - 120px diameter pulsing Mic button
/// - Dynamic speech status indicator ('Tap to speak' / 'Listening...' / 'Processing...')
/// - Large transcribed speech area
/// - Submit and Clear action buttons
/// - Rich Answer card with source, confidence badge, and TTS playback
/// - Fallback SMS escalation button
class VoiceQueryScreen extends StatefulWidget {
  const VoiceQueryScreen({super.key});

  @override
  State<VoiceQueryScreen> createState() => _VoiceQueryScreenState();
}

class _VoiceQueryScreenState extends State<VoiceQueryScreen> {
  final TextEditingController _speechController = TextEditingController();
  bool _isProcessing = false;
  QueryModel? _resultQuery;

  @override
  void dispose() {
    _speechController.dispose();
    super.dispose();
  }

  void _onMicTapped(AppProvider provider, SpeechService speechService) {
    if (speechService.isListening) {
      speechService.stopListening();
    } else {
      setState(() {
        _resultQuery = null;
      });
      speechService.startListening(
        locale: provider.locale,
        onResult: (text) {
          setState(() {
            _speechController.text = text;
          });
        },
      );
    }
  }

  Future<void> _submitVoiceQuery(AppProvider provider, SpeechService speechService) async {
    final text = _speechController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please tap the microphone and speak your query first.'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    if (speechService.isListening) {
      speechService.stopListening();
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await provider.submitQuery(text);
      if (!mounted) return;

      // The new QueryModel is in provider.queryHistory.first
      final answered = provider.queryHistory.isNotEmpty
          ? provider.queryHistory.first
          : QueryModel(
              id: 'temp-voice',
              queryText: text,
              locale: provider.locale,
              createdAt: DateTime.now(),
              status: provider.effectiveOnline ? QueryStatus.cloud : QueryStatus.local,
              path: provider.effectiveOnline ? RoutingPath.cloud : RoutingPath.onDevice,
              answerText: 'Advice received.',
            );

      setState(() {
        _resultQuery = answered;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _clearSpeech(SpeechService speechService) {
    if (speechService.isListening) {
      speechService.stopListening();
    }
    setState(() {
      _speechController.clear();
      _resultQuery = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, SpeechService>(
      builder: (context, provider, speechService, _) {
        String statusText;
        Color statusColor;

        if (_isProcessing) {
          statusText = 'Processing query with Agronomy AI...';
          statusColor = const Color(0xFFE65100);
        } else if (speechService.isListening) {
          statusText = 'Listening... Speak clearly into microphone';
          statusColor = const Color(0xFF2E7D32);
        } else {
          statusText = 'Tap to speak your query';
          statusColor = Colors.grey.shade700;
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF9FBF9),
          appBar: AppBar(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            title: const Text(
              'Voice Query Assistant',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            actions: [
              IconButton(
                tooltip: 'Network Mode',
                icon: Icon(
                  provider.isOnline ? Icons.wifi : Icons.wifi_off,
                  color: Colors.white,
                ),
                onPressed: () => provider.toggleOnlineMode(),
              ),
            ],
          ),
          body: Column(
            children: [
              // Animated Connectivity Banner at top
              ConnectivityBanner(
                isOnline: provider.isOnline,
                onToggle: (_) => provider.toggleOnlineMode(),
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    children: [
                      // Status Label with pulsing dot if listening
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (speechService.isListening || _isProcessing) ...[
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              statusText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Very Large Mic Button (120px diameter = radius 60)
                      MicButton(
                        radius: 60, // 120px diameter center button
                        isListening: speechService.isListening,
                        onTap: () => _onMicTapped(provider, speechService),
                      ),

                      const SizedBox(height: 24),

                      // Transcribed text display card
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 110),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: speechService.isListening
                                ? const Color(0xFF2E7D32)
                                : Colors.grey.shade300,
                            width: speechService.isListening ? 2 : 1.2,
                          ),
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
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 18,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Transcribed Speech:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _speechController.text.isEmpty
                                ? Text(
                                    'Your voice transcription will appear here in your language...',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey.shade400,
                                    ),
                                  )
                                : Text(
                                    _speechController.text,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1B5E20),
                                      height: 1.4,
                                    ),
                                  ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Action Buttons: 'Submit' and 'Clear'
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 52,
                              child: OutlinedButton.icon(
                                onPressed: () => _clearSpeech(speechService),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(Icons.clear_all_rounded, color: Colors.grey),
                                label: const Text(
                                  'Clear',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: _isProcessing
                                    ? null
                                    : () => _submitVoiceQuery(provider, speechService),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: _isProcessing
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.send_rounded, size: 20),
                                label: Text(
                                  _isProcessing ? 'Analyzing...' : 'Submit Query',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Result Answer Card Section (Appears after answer)
                      if (_resultQuery != null) ...[
                        const SizedBox(height: 24),
                        _buildAnswerCard(context, provider, speechService, _resultQuery!),
                      ],

                      const SizedBox(height: 30),

                      // 'Ask via SMS' fallback button at bottom
                      _buildSmsFallbackButton(context),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnswerCard(
    BuildContext context,
    AppProvider provider,
    SpeechService speechService,
    QueryModel query,
  ) {
    final answer = query.answerText ?? 'No advice recorded';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF81C784), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Badges & Routing Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RoutingPathChip(path: query.path),
              ConfidenceBadge(score: query.confidence),
            ],
          ),

          const SizedBox(height: 16),

          // Answer Title
          const Text(
            'Agricultural Advisory Answer:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 8),

          // Main Answer Text (Large 18sp)
          Text(
            answer,
            style: const TextStyle(
              fontSize: 18,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),

          const SizedBox(height: 16),

          // Read Answer button (TTS)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                if (speechService.isSpeaking) {
                  speechService.stop();
                } else {
                  speechService.speak(answer, provider.locale);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: speechService.isSpeaking
                    ? const Color(0xFFE65100)
                    : const Color(0xFFF9A825),
                foregroundColor: const Color(0xFF212121),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(
                speechService.isSpeaking ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: const Color(0xFF212121),
              ),
              label: Text(
                speechService.isSpeaking ? 'Stop Reading' : 'Read Answer Aloud',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Answer Source Card
          AnswerSourceCard(
            source: query.source ?? 'ICAR Knowledge Base',
            verifiedBy: query.verifiedBy,
            lastUpdated: query.lastUpdated,
            lastSynced: query.lastSyncedAt?.toIso8601String().substring(0, 10),
            isOffline: query.status == QueryStatus.local || query.status == QueryStatus.queued,
          ),
        ],
      ),
    );
  }

  Widget _buildSmsFallbackButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFF57C00),
          child: Icon(Icons.sms_rounded, color: Colors.white),
        ),
        title: const Text(
          'Network issues? Ask via Free SMS',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE65100),
          ),
        ),
        subtitle: const Text(
          'Send your query via SMS or call 1800-180-1551',
          style: TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFE65100)),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SmsFallbackScreen(
                initialQuery: _speechController.text.isNotEmpty
                    ? _speechController.text
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
