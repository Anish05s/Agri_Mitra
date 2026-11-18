import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';

/// SMS and IVR fallback screen designed for zero-connectivity situations.
///
/// Features:
/// - Phone icon (large)
/// - 'Send via SMS' button
/// - Query text display
/// - After sending: animated 'Sending...' then success state
/// - Mock SMS reply shown in a 'chat bubble' style
/// - IVR number display: '1800-180-1551 (Toll Free)'
class SmsFallbackScreen extends StatefulWidget {
  final String? initialQuery;

  const SmsFallbackScreen({super.key, this.initialQuery});

  @override
  State<SmsFallbackScreen> createState() => _SmsFallbackScreenState();
}

class _SmsFallbackScreenState extends State<SmsFallbackScreen> {
  late TextEditingController _queryController;
  bool _isSending = false;
  bool _isSent = false;
  bool _hasReceivedReply = false;
  String? _simulatedReply;
  String? _sentTime;
  String? _replyTime;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(
      text: widget.initialQuery ?? 'How to control yellow rust in wheat?',
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _sendViaSms(AppProvider provider) async {
    final text = _queryController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your question to send via SMS.'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
      _isSent = false;
      _hasReceivedReply = false;
    });

    try {
      // Send through provider to persist in SQLite query queue as well
      final result = await provider.sendViaSms(text);
      final now = DateTime.now();
      _sentTime = DateFormat('hh:mm a').format(now);

      if (!mounted) return;
      setState(() {
        _isSending = false;
        _isSent = true;
      });

      // Simulate network carrier SMS reply delay
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;

      final replyTime = DateTime.now();
      _replyTime = DateFormat('hh:mm a').format(replyTime);

      setState(() {
        _hasReceivedReply = true;
        _simulatedReply = result.mockReply ??
            'SMS from KISAN-GOV / ICAR: For "$text", spray Propiconazole 25% EC @ 1ml/L in clear weather. Follow up with 15kg Urea per acre during irrigation. Helpline: 1800-180-1551.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SMS dispatch failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7FAF7),
          appBar: AppBar(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            elevation: 2,
            title: const Text(
              'SMS & Call Fallback',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Zero-Connectivity Alert
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFB74D)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.signal_cellular_connected_no_internet_4_bar_rounded,
                          color: Color(0xFFE65100), size: 26),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No Internet Needed',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE65100),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Works on standard 2G cellular SMS and toll-free voice calls.',
                              style: TextStyle(fontSize: 13, color: Color(0xFF5D4037)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Large Phone / SMS Icon & Section Title
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF2E7D32), width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.phone_forwarded_rounded,
                      size: 50,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Free SMS Advisory Gateway',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Government Kisan Portal Shortcode: 51969',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 20),

                // Query Input Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit_note_rounded, color: Color(0xFF2E7D32), size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'Your Question (SMS Content):',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _queryController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF9FBF9),
                          hintText: 'Enter question to send via SMS...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 'Send via SMS' Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isSending ? null : () => _sendViaSms(provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF9A825), // Amber accent
                      foregroundColor: const Color(0xFF3E2723),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF3E2723)),
                          )
                        : const Icon(Icons.send_rounded, size: 22, color: Color(0xFF3E2723)),
                    label: Text(
                      _isSending
                          ? 'Sending SMS to 51969...'
                          : (_isSent ? 'Resend via SMS' : 'Send via SMS'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),

                // SMS Conversation Thread (Chat Bubble Style)
                if (_isSent || _hasReceivedReply) ...[
                  const SizedBox(height: 24),
                  _buildChatThreadSection(),
                ],

                const SizedBox(height: 28),

                // IVR Toll-Free Helpline Section: '1800-180-1551 (Toll Free)'
                _buildIvrHelplineSection(context),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatThreadSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.mark_chat_read_rounded, color: Color(0xFF2E7D32), size: 20),
              const SizedBox(width: 8),
              const Text(
                'SMS Advisory Conversation',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Delivered',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 1, color: Color(0xFFEEEEEE)),

          // 1. Sent Outgoing Message Bubble (Right-aligned, green)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 290),
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFDCEDC8), // Light green bubble
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _queryController.text,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _sentTime ?? '',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.done_all_rounded, size: 14, color: Color(0xFF2E7D32)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 2. Incoming Advisory Reply Bubble (Left-aligned, chat bubble style)
          if (_hasReceivedReply && _simulatedReply != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 310),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border.all(color: const Color(0xFF81C784)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified_rounded, size: 16, color: Color(0xFF2E7D32)),
                        SizedBox(width: 4),
                        Text(
                          'VM-KISAN-GOV (Free SMS)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _simulatedReply!,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        _replyTime ?? '',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Typing / Waiting indicator
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 4.0),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Awaiting government gateway response...',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIvrHelplineSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF81C784), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.headset_mic_rounded, color: Color(0xFF2E7D32), size: 28),
              SizedBox(width: 8),
              Text(
                'Kisan Call Centre (IVR)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Speak directly to agricultural scientists and agronomists in your regional language.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF2E7D32), height: 1.3),
          ),
          const SizedBox(height: 16),

          // Big Toll-Free Number Display: '1800-180-1551 (Toll Free)'
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2E7D32), width: 2),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone_in_talk_rounded, color: Color(0xFF2E7D32), size: 26),
                SizedBox(width: 10),
                Text(
                  '1800-180-1551 (Toll Free)',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Text(
            '(Toll Free • 6:00 AM to 10:00 PM • All 22 Languages)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF388E3C)),
          ),
          const SizedBox(height: 16),

          // Tap to Call Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Row(
                      children: [
                        Icon(Icons.call, color: Color(0xFF2E7D32)),
                        SizedBox(width: 8),
                        Text('Dial Kisan Helpline'),
                      ],
                    ),
                    content: const Text(
                      'Directing call to Toll-Free: 1800-180-1551.\nFree government call without airtime charges.',
                      style: TextStyle(fontSize: 15),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Call 1800-180-1551', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.call_rounded, size: 22),
              label: const Text(
                'Call Toll-Free Helpline Now',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
