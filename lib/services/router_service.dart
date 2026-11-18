import '../core/constants.dart';
import '../models/answer_entry.dart';
import '../models/query_model.dart';
import 'cloud_service.dart';
import 'database_service.dart';
import 'on_device_llm_service.dart';

/// Encapsulates the evaluation and final response returned by the router.
class QueryResult {
  final String answer;
  final RoutingPath path;
  final double confidence;
  final String? source;
  final String? verifiedBy;
  final String? lastUpdated;
  final bool isHighConfidence;
  final DateTime? lastSyncedAt;
  final List<AnswerEntry> matchedEntries;

  const QueryResult({
    required this.answer,
    required this.path,
    required this.confidence,
    this.source,
    this.verifiedBy,
    this.lastUpdated,
    required this.isHighConfidence,
    this.lastSyncedAt,
    this.matchedEntries = const [],
  });

  @override
  String toString() =>
      'QueryResult(path: $path, confidence: $confidence, isHigh: $isHighConfidence, source: $source)';
}

/// Core routing engine for Agri Mitra.
/// Evaluates queries against offline knowledge base and routes intelligently:
/// 1. Confidence >= 0.75 -> OnDevice (Instant SQLite response)
/// 2. Confidence >= 0.50 ->
///       Offline -> OnDeviceAI (Gemma 2B SLM with local RAG context)
///       Online  -> Cloud AI
/// 3. Confidence < 0.50  ->
///       Online  -> Cloud AI
///       Offline -> Queued for KVK expert synchronization
class RouterService {
  final DatabaseService _dbService;
  final OnDeviceLLM _onDeviceLLM;
  final CloudService _cloudService;

  RouterService({
    DatabaseService? dbService,
    OnDeviceLLM? onDeviceLLM,
    CloudService? cloudService,
  })  : _dbService = dbService ?? DatabaseService(),
        _onDeviceLLM = onDeviceLLM ?? MockOnDeviceLLM(),
        _cloudService = cloudService ?? CloudService();

  /// Routes farmer query based on confidence score, connectivity, and local bank matches.
  Future<QueryResult> route(String queryText, String locale, bool isOnline) async {
    // 1. Search local answer bank & compute normalized confidence
    final allAnswers = await _dbService.getAllAnswers();
    final scoredMatches = _scoreAnswerEntries(queryText, locale, allAnswers);

    final topScore = scoredMatches.isNotEmpty ? scoredMatches.first.score : 0.0;
    final topEntries = scoredMatches.map((m) => m.entry).take(3).toList();

    // 2. High Confidence Match (>= 0.75): Always OnDevice
    if (topScore >= AppConstants.confidenceHigh) {
      final best = topEntries.first;
      final localizedAnswer = best.getLocalizedAnswer(locale);

      return QueryResult(
        answer: localizedAnswer,
        path: RoutingPath.onDevice,
        confidence: topScore,
        source: best.source,
        verifiedBy: best.verifiedBy,
        lastUpdated: best.lastUpdated,
        isHighConfidence: true,
        lastSyncedAt: DateTime.now(),
        matchedEntries: topEntries,
      );
    }

    // 3. Medium Confidence Match (0.50 <= score < 0.75)
    if (topScore >= AppConstants.confidenceMedium) {
      if (!isOnline) {
        // Offline: On-device SLM with retrieved context
        final generatedText = await _onDeviceLLM.generate(
          queryText,
          topEntries,
        );

        final top = topEntries.isNotEmpty ? topEntries.first : null;
        return QueryResult(
          answer: generatedText,
          path: RoutingPath.onDeviceAI,
          confidence: topScore,
          source: 'On-device AI (Gemma 2B) + ${top?.source ?? 'ICAR'}',
          verifiedBy: top?.verifiedBy ?? 'On-Device AI Assistant',
          lastUpdated: top?.lastUpdated ?? DateTime.now().toIso8601String().substring(0, 10),
          isHighConfidence: false,
          lastSyncedAt: null,
          matchedEntries: topEntries,
        );
      } else {
        // Online: Cloud AI endpoint
        final cloudResp = await _cloudService.query(queryText, locale, topEntries);

        return QueryResult(
          answer: cloudResp.answer,
          path: RoutingPath.cloud,
          confidence: cloudResp.confidence,
          source: cloudResp.source,
          verifiedBy: cloudResp.verifiedBy,
          lastUpdated: cloudResp.lastUpdated,
          isHighConfidence: cloudResp.confidence >= AppConstants.confidenceHigh,
          lastSyncedAt: DateTime.now(),
          matchedEntries: topEntries,
        );
      }
    }

    // 4. Low Confidence Match (< 0.50)
    if (isOnline) {
      // Online: Escalate to Cloud AI
      final cloudResp = await _cloudService.query(queryText, locale, topEntries);

      return QueryResult(
        answer: cloudResp.answer,
        path: RoutingPath.cloud,
        confidence: cloudResp.confidence,
        source: cloudResp.source,
        verifiedBy: cloudResp.verifiedBy,
        lastUpdated: cloudResp.lastUpdated,
        isHighConfidence: cloudResp.confidence >= AppConstants.confidenceHigh,
        lastSyncedAt: DateTime.now(),
        matchedEntries: topEntries,
      );
    } else {
      // Offline: Low confidence cannot be answered reliably on-device -> Queue for KVK expert
      final followUpText = _getLocalizedQueueMessage(locale);

      return QueryResult(
        answer: followUpText,
        path: RoutingPath.queued,
        confidence: topScore,
        source: 'Queued for KVK Expert Review',
        verifiedBy: 'Agronomist Specialist (Pending Sync)',
        lastUpdated: DateTime.now().toIso8601String().substring(0, 10),
        isHighConfidence: false,
        lastSyncedAt: null,
        matchedEntries: topEntries,
      );
    }
  }

  /// Calculates keyword matching score for all answer entries (normalized 0.0 to 1.0).
  List<_ScoredAnswer> _scoreAnswerEntries(
    String queryText,
    String locale,
    List<AnswerEntry> entries,
  ) {
    final queryClean = queryText.trim().toLowerCase();
    if (queryClean.isEmpty) return [];

    // Tokenize query into distinct words, stripping common punctuation
    final queryTokens = queryClean
        .replaceAll(RegExp(r'[^\w\s\u0900-\u097F\u0980-\u09FF]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 2 && !_stopWords.contains(t))
        .toSet();

    if (queryTokens.isEmpty) return [];

    final scored = <_ScoredAnswer>[];

    for (final entry in entries) {
      double rawScore = 0.0;
      int matchedCount = 0;

      final entryKeywords = entry.keywords.map((k) => k.toLowerCase()).toSet();
      final cropLower = entry.crop.toLowerCase();
      final categoryLower = entry.category.toLowerCase();
      final questionText = entry.getLocalizedQuestion(locale).toLowerCase();

      for (final token in queryTokens) {
        // Direct keyword match
        if (entryKeywords.contains(token)) {
          rawScore += 0.40;
          matchedCount++;
        } else if (entryKeywords.any((k) => k.contains(token) || token.contains(k))) {
          rawScore += 0.25;
          matchedCount++;
        }

        // Crop match bonus
        if (cropLower.contains(token) || token.contains(cropLower)) {
          rawScore += 0.30;
        }

        // Category match bonus
        if (categoryLower.contains(token) || token.contains(categoryLower)) {
          rawScore += 0.15;
        }

        // Question text overlap
        if (questionText.contains(token)) {
          rawScore += 0.20;
        }
      }

      if (matchedCount > 0 || rawScore >= 0.35) {
        // Normalize score between 0.0 and 1.0 weighted by entry base confidence
        final expectedMatches = queryTokens.length.clamp(1, 4);
        final ratio = (rawScore / (expectedMatches * 0.70)).clamp(0.0, 1.0);
        final finalConfidence = (ratio * 0.85 + entry.confidence * 0.15).clamp(0.0, 1.0);

        scored.add(_ScoredAnswer(entry: entry, score: finalConfidence));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored;
  }

  String _getLocalizedQueueMessage(String locale) {
    switch (locale) {
      case 'hi':
        return '⏳ आपका सवाल सुरक्षित कर लिया गया है।\n\n'
            'ऑफ़लाइन होने के कारण यह सवाल हमारे कृषि विज्ञान केंद्र (KVK) के विशेषज्ञों को भेजा गया है। नेटवर्क आते ही विशेषज्ञ का जवाब आपको प्राप्त हो जाएगा।\n\n'
            'आपातकालीन सहायता के लिए किसान हेल्पलाइन 1800-180-1551 पर कॉल करें।';
      case 'bn':
        return '⏳ আপনার প্রশ্নটি অফলাইনে সংরক্ষিত হয়েছে।\n\n'
            'সঠিক উত্তরের জন্য প্রশ্নটি কৃষি বিজ্ঞান কেন্দ্রের (KVK) বিশেষজ্ঞের কাছে পাঠানো হয়েছে। ইন্টারনেট সংযোগ পেলেই বিস্তারিত উত্তর পেয়ে যাবেন।\n\n'
            'জরুরী সহায়তার জন্য কিষাণ হেল্পলাইন ১৮০০-১৮০-১৫৫১ নম্বরে ফোন করুন।';
      default:
        return '⏳ Your query has been saved offline and queued for our Krishi Vigyan Kendra (KVK) agronomists.\n\n'
            'Since on-device confidence is low for this specific symptom, our experts will review it as soon as your device connects to the internet.\n\n'
            'For immediate help, call the Kisan Call Center Helpline at 1800-180-1551.';
    }
  }

  static const Set<String> _stopWords = {
    'the', 'is', 'a', 'an', 'and', 'or', 'in', 'on', 'at', 'to', 'for', 'with', 'from', 'by', 'of',
    'ka', 'ki', 'ke', 'ko', 'me', 'hai', 'hain', 'se', 'par', 'kya', 'kaise', 'kare', 'karein',
    'er', 'ar', 'ei', 'o', 'te', 'ba', 'ebong', 'kivabe', 'korbo', 'hoy', 'holo',
  };
}

class _ScoredAnswer {
  final AnswerEntry entry;
  final double score;
  _ScoredAnswer({required this.entry, required this.score});
}
