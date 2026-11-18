import '../core/constants.dart';
import '../models/answer_entry.dart';
import '../models/crop_calendar.dart';
import '../models/mandi_price.dart';
import '../models/query_model.dart';
import '../models/weather_cache.dart';

/// Response received from the Cloud AI advisory endpoint.
class CloudResponse {
  final String answer;
  final String source;
  final String verifiedBy;
  final double confidence;
  final String lastUpdated;

  const CloudResponse({
    required this.answer,
    required this.source,
    required this.verifiedBy,
    required this.confidence,
    required this.lastUpdated,
  });

  factory CloudResponse.fromJson(Map<String, dynamic> json) {
    return CloudResponse(
      answer: json['answer'] as String? ?? '',
      source: json['source'] as String? ?? 'Cloud AI (ICAR Knowledge Base)',
      verifiedBy: json['verifiedBy'] as String? ?? 'Dr. Rajan Kumar, ICAR-CRRI',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.92,
      lastUpdated: json['lastUpdated'] as String? ?? DateTime.now().toIso8601String().substring(0, 10),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'answer': answer,
      'source': source,
      'verifiedBy': verifiedBy,
      'confidence': confidence,
      'lastUpdated': lastUpdated,
    };
  }
}

/// Represents an expert human agronomist answer received after syncing a queued offline query.
class ExpertAnswer {
  final String queryId;
  final String answer;
  final String answeredBy;
  final DateTime answeredAt;

  const ExpertAnswer({
    required this.queryId,
    required this.answer,
    required this.answeredBy,
    required this.answeredAt,
  });

  factory ExpertAnswer.fromJson(Map<String, dynamic> json) {
    return ExpertAnswer(
      queryId: json['queryId'] as String,
      answer: json['answer'] as String,
      answeredBy: json['answeredBy'] as String,
      answeredAt: DateTime.tryParse(json['answeredAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'queryId': queryId,
      'answer': answer,
      'answeredBy': answeredBy,
      'answeredAt': answeredAt.toIso8601String(),
    };
  }
}

/// Mock cloud AI advisory service communicating with the central ICAR knowledge base.
/// Simulates cloud LLM latency and expert agronomist queue resolution.
class CloudService {
  static const String mockEndpoint = AppConstants.cloudMockEndpoint;

  /// Simulates online Cloud AI inference with 1.2s network roundtrip.
  Future<CloudResponse> query(
    String queryText,
    String locale,
    List<AnswerEntry> context,
  ) async {
    // Simulate real-world 3G/4G rural mobile latency
    await Future.delayed(const Duration(milliseconds: 1200));

    // Determine targeted content based on query text or context
    final queryLower = queryText.toLowerCase();
    String crop = 'Crops in West Bengal';
    if (queryLower.contains('rice') || queryLower.contains('paddy') || queryLower.contains('dhan')) {
      crop = 'Paddy / Rice (Oryza sativa)';
    } else if (queryLower.contains('potato') || queryLower.contains('alu') || queryLower.contains('aaloo')) {
      crop = 'Potato (Solanum tuberosum)';
    } else if (queryLower.contains('jute') || queryLower.contains('pat') || queryLower.contains('paat')) {
      crop = 'Jute (Corchorus olitorius)';
    }

    String answerText;
    if (context.isNotEmpty) {
      final top = context.first;
      final localizedBase = top.getLocalizedAnswer(locale);
      answerText = '🌾 [Cloud AI - Detailed Agronomic Assessment for $crop]\n\n'
          '$localizedBase\n\n'
          'Detailed Field Action:\n'
          '• Ensure clean irrigation channels to prevent water stagnation.\n'
          '• Apply bio-fertilizers (Azospirillum / PSB) alongside chemical dosages.\n'
          '• Monitor the field at dawn for early pest oviposition.\n\n'
          '📞 For immediate village-level queries, contact your nearest Krishi Vigyan Kendra helpline (${AppConstants.kisanHelplineDisplay}).';
    } else {
      answerText = '🌾 [Cloud AI - Comprehensive Recommendation for $crop]\n\n'
          'Based on satellite agro-indices and the ICAR national repository for eastern India:\n'
          '• For suspected pest or blight infestation, inspect lower leaf canopies.\n'
          '• Maintain balanced N-P-K ratios and avoid late-season nitrogen applications.\n'
          '• If disease symptoms worsen, spray contact fungicide (Mancozeb 75% WP @ 2.5g/L) during calm weather.\n\n'
          '📞 Validated by KVK Agronomists. Helpline: ${AppConstants.kisanHelplineDisplay}.';
    }

    return CloudResponse(
      answer: answerText,
      source: 'Cloud AI (ICAR-CRRI / Central Knowledge Base)',
      verifiedBy: 'Dr. Rajan Kumar, ICAR-CRRI Principal Scientist',
      confidence: 0.92,
      lastUpdated: DateTime.now().toIso8601String().substring(0, 10),
    );
  }

  /// Simulates syncing queued queries with agricultural experts at KVK.
  Future<List<ExpertAnswer>> syncQueuedQueries(List<QueryModel> pending) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final now = DateTime.now();
    return pending.map((q) {
      final preview = q.queryText.length > 30 ? '${q.queryText.substring(0, 30)}...' : q.queryText;

      return ExpertAnswer(
        queryId: q.id,
        answer: '✅ [Expert Agronomist Verified Solution]\n\n'
            'Regarding your query: "$preview"\n\n'
            'Based on field validation trials in local agro-climatic zones:\n'
            '1. Immediately isolate heavily affected plants to arrest pathogen spread.\n'
            '2. Apply recommended micronutrient spray (Zinc Sulphate 0.5% + Borax 0.2%) after morning dew dries.\n'
            '3. Maintain optimum soil moisture; avoid flood irrigation under high humidity.\n\n'
            'Answered by Dr. Priya Sharma (Subject Matter Specialist, KVK Nadia) on ${now.toIso8601String().substring(0, 10)}.',
        answeredBy: 'Dr. Priya Sharma, KVK Nadia',
        answeredAt: now,
      );
    }).toList();
  }

  /// Simulates fetching fresh weather data from IMD
  Future<WeatherCache> fetchFreshWeather() async {
    await Future.delayed(const Duration(milliseconds: 900));
    final now = DateTime.now();
    return WeatherCache(
      location: 'Hooghly & Murshidabad, West Bengal',
      tempCelsius: 30.2,
      condition: 'Partly Cloudy with Light Showers',
      humidity: 82,
      windKmh: 14.5,
      rainfall: '18mm expected next 48h',
      source: 'IMD Agro-Advisory Bulletin',
      fetchedAt: now,
      lastSyncedAt: now,
    );
  }

  /// Simulates fetching fresh mandi prices from Agmarknet
  Future<List<MandiPrice>> fetchFreshMandiPrices() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final now = DateTime.now();
    return [
      MandiPrice(
        crop: 'Paddy (Dhan)',
        variety: 'Swarna / Common',
        market: 'Burdwan Mandi',
        minPrice: 2200.0,
        maxPrice: 2380.0,
        modalPrice: 2310.0,
        unit: 'per quintal',
        date: now,
        source: 'Agmarknet Realtime',
        lastSyncedAt: now,
      ),
      MandiPrice(
        crop: 'Potato (Alu)',
        variety: 'Jyoti',
        market: 'Hooghly Mandi',
        minPrice: 1450.0,
        maxPrice: 1700.0,
        modalPrice: 1560.0,
        unit: 'per quintal',
        date: now,
        source: 'Agmarknet Realtime',
        lastSyncedAt: now,
      ),
      MandiPrice(
        crop: 'Potato (Alu)',
        variety: 'Chandramukhi',
        market: 'Singur Mandi',
        minPrice: 1850.0,
        maxPrice: 2150.0,
        modalPrice: 2000.0,
        unit: 'per quintal',
        date: now,
        source: 'Agmarknet Realtime',
        lastSyncedAt: now,
      ),
      MandiPrice(
        crop: 'Raw Jute (Pat)',
        variety: 'TD-5',
        market: 'Sheoraphuli Mandi',
        minPrice: 5300.0,
        maxPrice: 5750.0,
        modalPrice: 5500.0,
        unit: 'per quintal',
        date: now,
        source: 'Agmarknet Realtime',
        lastSyncedAt: now,
      ),
    ];
  }

  /// Simulates fetching updated crop calendar
  Future<List<CropCalendarEntry>> fetchCropCalendar() async {
    await Future.delayed(const Duration(milliseconds: 800));
    final now = DateTime.now();
    return [
      CropCalendarEntry(
        crop: 'Rice (Kharif / Aman)',
        stage: 'Panicle Initiation & Tillering',
        months: 'July - August',
        advice: 'Apply second top dressing of Nitrogen @ 30kg/ha at tillering. Maintain 3-5cm water level.',
        adviceLocale: {
          'en': 'Apply second top dressing of Nitrogen @ 30kg/ha at tillering. Maintain 3-5cm water level.',
          'hi': 'कल्ले निकलते समय 30 किग्रा/हेक्टेयर नाइट्रोजन की दूसरी खुराक दें। खेत में 3-5 सेमी पानी रखें।',
          'bn': 'কুশি আসার সময় হেক্টর প্রতি ৩০ কেজি নাইট্রোজেনের দ্বিতীয় টপ ড্রেসিং দিন। ৩-৫ সেমি জল রাখুন।',
        },
        source: 'ICAR-CRRI / BCKV Updated',
        lastSyncedAt: now,
      ),
      CropCalendarEntry(
        crop: 'Potato (Rabi)',
        stage: 'Earthing Up & Tuberization',
        months: 'November - December',
        advice: 'Perform first earthing up at 30-35 days after planting. Spray Mancozeb as prophylactic against blight.',
        adviceLocale: {
          'en': 'Perform first earthing up at 30-35 days after planting. Spray Mancozeb as prophylactic against blight.',
          'hi': 'बुवाई के 30-35 दिन बाद पहली बार मिट्टी चढ़ाएं। झुलसा से बचाव हेतु मैंकोजेब का छिड़काव करें।',
          'bn': 'রোপণের ৩০-৩৫ দিনে প্রথম মাটি তুলুন। ধসা রোগ রোধে প্রতিষেধক হিসেবে ম্যানকোজেব স্প্রে করুন।',
        },
        source: 'ICAR-CPRI Updated',
        lastSyncedAt: now,
      ),
      CropCalendarEntry(
        crop: 'Jute (Pre-Kharif)',
        stage: 'Harvesting & Retting',
        months: 'July - August',
        advice: 'Harvest at 120-135 days (small pod stage) for superior fiber strength. Steep in slow-flowing clean water.',
        adviceLocale: {
          'en': 'Harvest at 120-135 days (small pod stage) for superior fiber strength. Steep in slow-flowing clean water.',
          'hi': 'उत्कृष्ट रेशे के लिए 120-135 दिन (छोटी फली अवस्था) पर कटाई करें। बहते साफ पानी में भिगोएं।',
          'bn': 'উন্নত আঁশের জন্য ১২০-১৩৫ দিনে (ছোট শুঁটি অবস্থায়) পাট কাটুন। ধীরগতির পরিষ্কার জলে জাব দিন।',
        },
        source: 'ICAR-CRIJAF Updated',
        lastSyncedAt: now,
      ),
    ];
  }
}
