import 'dart:convert';

/// Represents a verified agricultural advisory entry in the local answer bank.
/// Pre-loaded from official agricultural research bodies (ICAR, KVK).
class AnswerEntry {
  final String id;
  final String crop; // 'rice' | 'potato' | 'jute'
  final String category; // 'pest' | 'disease' | 'irrigation' | 'general'
  final List<String> keywords; // For offline keyword matching
  final Map<String, String> question; // locale -> question text
  final Map<String, String> answer; // locale -> answer text
  final String source; // e.g. 'ICAR-CRRI', 'KVK Murshidabad'
  final String verifiedBy; // Agronomist name/title
  final String lastUpdated; // ISO date string e.g. '2024-10-15'
  final double confidence; // Base confidence score (0.0 to 1.0)

  const AnswerEntry({
    required this.id,
    required this.crop,
    required this.category,
    required this.keywords,
    required this.question,
    required this.answer,
    required this.source,
    required this.verifiedBy,
    required this.lastUpdated,
    required this.confidence,
  });

  /// Factory constructor to create an [AnswerEntry] from a standard JSON Map.
  factory AnswerEntry.fromJson(Map<String, dynamic> json) {
    return AnswerEntry(
      id: json['id'] as String? ?? '',
      crop: json['crop'] as String? ?? 'general',
      category: json['category'] as String? ?? 'general',
      keywords: _parseStringList(json['keywords']),
      question: _parseStringMap(json['question']),
      answer: _parseStringMap(json['answer']),
      source: json['source'] as String? ?? 'ICAR',
      verifiedBy: json['verifiedBy'] as String? ?? json['verified_by'] as String? ?? 'ICAR Agronomist',
      lastUpdated: json['lastUpdated'] as String? ?? json['last_updated'] as String? ?? DateTime.now().toIso8601String().substring(0, 10),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.85,
    );
  }

  /// Converts this [AnswerEntry] to a standard JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'crop': crop,
      'category': category,
      'keywords': keywords,
      'question': question,
      'answer': answer,
      'source': source,
      'verifiedBy': verifiedBy,
      'lastUpdated': lastUpdated,
      'confidence': confidence,
    };
  }

  /// Factory constructor from SQLite database row.
  /// Handles JSON-encoded strings for keywords, question, and answer.
  factory AnswerEntry.fromMap(Map<String, dynamic> map) {
    return AnswerEntry(
      id: map['id'] as String? ?? '',
      crop: map['crop'] as String? ?? 'general',
      category: map['category'] as String? ?? 'general',
      keywords: _parseStringList(map['keywords']),
      question: _parseStringMap(map['question']),
      answer: _parseStringMap(map['answer']),
      source: map['source'] as String? ?? 'ICAR',
      verifiedBy: map['verified_by'] as String? ?? map['verifiedBy'] as String? ?? 'ICAR Agronomist',
      lastUpdated: map['last_updated'] as String? ?? map['lastUpdated'] as String? ?? '',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.85,
    );
  }

  /// Converts this [AnswerEntry] to an SQLite compatible Map with JSON-encoded nested maps.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'crop': crop,
      'category': category,
      'keywords': jsonEncode(keywords),
      'question': jsonEncode(question),
      'answer': jsonEncode(answer),
      'source': source,
      'verified_by': verifiedBy,
      'last_updated': lastUpdated,
      'confidence': confidence,
    };
  }

  /// Retrieves the question in the requested locale, falling back to 'en' or first available.
  String getLocalizedQuestion(String locale) {
    if (question.containsKey(locale) && question[locale]!.trim().isNotEmpty) {
      return question[locale]!;
    }
    if (question.containsKey('en') && question['en']!.trim().isNotEmpty) {
      return question['en']!;
    }
    return question.values.isNotEmpty ? question.values.first : '';
  }

  /// Retrieves the answer in the requested locale, falling back to 'en' or first available.
  String getLocalizedAnswer(String locale) {
    if (answer.containsKey(locale) && answer[locale]!.trim().isNotEmpty) {
      return answer[locale]!;
    }
    if (answer.containsKey('en') && answer['en']!.trim().isNotEmpty) {
      return answer['en']!;
    }
    return answer.values.isNotEmpty ? answer.values.first : 'Please contact your local Krishi Vigyan Kendra.';
  }

  AnswerEntry copyWith({
    String? id,
    String? crop,
    String? category,
    List<String>? keywords,
    Map<String, String>? question,
    Map<String, String>? answer,
    String? source,
    String? verifiedBy,
    String? lastUpdated,
    double? confidence,
  }) {
    return AnswerEntry(
      id: id ?? this.id,
      crop: crop ?? this.crop,
      category: category ?? this.category,
      keywords: keywords ?? this.keywords,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      source: source ?? this.source,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  String toString() => 'AnswerEntry(id: $id, crop: $crop, category: $category, confidence: $confidence)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnswerEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Helper parsing methods
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    }
    return [];
  }

  static Map<String, String> _parseStringMap(dynamic value) {
    if (value == null) return {};
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      } catch (_) {
        return {'en': value};
      }
    }
    return {};
  }
}
