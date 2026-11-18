import '../core/constants.dart';

/// Represents the outcome of sending an advisory SMS or IVR fallback request.
class SmsResult {
  final bool sent;
  final String messageId;
  final String mockReply;
  final String phoneNumber;
  final DateTime sentAt;
  final String statusMessage;

  const SmsResult({
    required this.sent,
    required this.messageId,
    required this.mockReply,
    required this.phoneNumber,
    required this.sentAt,
    required this.statusMessage,
  });

  @override
  String toString() =>
      'SmsResult(sent: $sent, id: $messageId, phone: $phoneNumber, status: $statusMessage)';
}

/// Fallback SMS/IVR Service for zero-internet rural environments.
/// Enables farmers to dispatch queries via GSM cellular SMS or place direct
/// toll-free calls to the Kisan Call Center (1800-180-1551).
class SmsService {
  static const String defaultHelpline = AppConstants.smsMockNumber;

  /// Simulates transmitting a query over GSM SMS network to the KVK gateway.
  Future<SmsResult> sendQuery(String queryText, String phoneNumber) async {
    // Simulate GSM network transmission latency
    await Future.delayed(const Duration(seconds: 2));

    final cleanPhone = phoneNumber.trim().isEmpty ? defaultHelpline : phoneNumber.trim();
    final messageId = 'SMS-${DateTime.now().millisecondsSinceEpoch}';

    final reply = _generateLocalizedMockReply(queryText);

    return SmsResult(
      sent: true,
      messageId: messageId,
      mockReply: reply,
      phoneNumber: cleanPhone,
      sentAt: DateTime.now(),
      statusMessage: 'Message delivered to Kisan Call Center (KVK)',
    );
  }

  /// Returns direct dialer URI for toll-free emergency call
  String getEmergencyCallUri() => 'tel:${AppConstants.smsMockNumber}';

  /// Returns USSD quick code
  String getUssdDialCode() => AppConstants.smsEmergencyUssd;

  /// Generates a realistic mock automated reply from KVK
  String _generateLocalizedMockReply(String queryText) {
    final lower = queryText.toLowerCase();

    if (lower.contains('dhan') || lower.contains('rice') || lower.contains('ধান')) {
      return 'KrishiSeva: Aapka dhan/rice rog ka sawaal KVK Murshidabad expert ke paas register ho gaya hai. '
          'Sifaarish: Tricyclazole 0.6g/L spray karein. Sahayata: ${AppConstants.kisanHelplineDisplay}';
    } else if (lower.contains('alu') || lower.contains('potato') || lower.contains('আলু')) {
      return 'KrishiSeva: Aapka aaloo jhulsa ka sawaal register ho gaya hai. '
          'Sifaarish: Mancozeb 2.5g/L spray karein. Helpline: ${AppConstants.kisanHelplineDisplay}';
    } else {
      return 'KrishiSeva: Aapka sawaal hamare expert ke paas bheja gaya hai. '
          'Jawab SMS mein milega. [KVK Helpline: ${AppConstants.kisanHelplineDisplay}]';
    }
  }
}
