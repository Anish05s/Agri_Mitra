import 'dart:convert';

/// Represents a seasonal crop calendar recommendation for farmers.
/// Details stage-by-stage agronomic practices, sowing/harvesting windows, and localized tips.
class CropCalendarEntry {
  final String crop; // e.g. 'Rice', 'Potato', 'Jute'
  final String stage; // e.g. 'Nursery Sowing', 'Transplanting', 'Tillering', 'Harvesting'
  final String months; // e.g. 'June-July', 'October-November'
  final String advice; // Default English advisory text
  final Map<String, String> adviceLocale; // Multilingual translations: locale -> advice
  final String source; // e.g. 'ICAR-CRRI / BCKV Kalyani'
  final DateTime lastSyncedAt;

  const CropCalendarEntry({
    required this.crop,
    required this.stage,
    required this.months,
    required this.advice,
    required this.adviceLocale,
    required this.source,
    required this.lastSyncedAt,
  });

  /// Factory constructor from SQLite database map
  factory CropCalendarEntry.fromMap(Map<String, dynamic> map) {
    return CropCalendarEntry(
      crop: map['crop'] as String? ?? '',
      stage: map['stage'] as String? ?? '',
      months: map['months'] as String? ?? '',
      advice: map['advice'] as String? ?? '',
      adviceLocale: _parseLocaleMap(map['advice_locale'] ?? map['adviceLocale']),
      source: map['source'] as String? ?? 'ICAR',
      lastSyncedAt: DateTime.tryParse(map['last_synced_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  /// Converts this [CropCalendarEntry] to an SQLite compatible Map
  Map<String, dynamic> toMap() {
    return {
      'crop': crop,
      'stage': stage,
      'months': months,
      'advice': advice,
      'advice_locale': jsonEncode(adviceLocale),
      'source': source,
      'last_synced_at': lastSyncedAt.toIso8601String(),
    };
  }

  /// Factory constructor from JSON
  factory CropCalendarEntry.fromJson(Map<String, dynamic> json) => CropCalendarEntry.fromMap(json);

  /// Converts to JSON
  Map<String, dynamic> toJson() => toMap();

  /// Gets localized advice based on the requested locale with fallback to English or default advice
  String getLocalizedAdvice(String locale) {
    if (adviceLocale.containsKey(locale) && adviceLocale[locale]!.trim().isNotEmpty) {
      return adviceLocale[locale]!;
    }
    if (adviceLocale.containsKey('en') && adviceLocale['en']!.trim().isNotEmpty) {
      return adviceLocale['en']!;
    }
    return advice.isNotEmpty ? advice : 'Follow standard agronomic practices.';
  }

  CropCalendarEntry copyWith({
    String? crop,
    String? stage,
    String? months,
    String? advice,
    Map<String, String>? adviceLocale,
    String? source,
    DateTime? lastSyncedAt,
  }) {
    return CropCalendarEntry(
      crop: crop ?? this.crop,
      stage: stage ?? this.stage,
      months: months ?? this.months,
      advice: advice ?? this.advice,
      adviceLocale: adviceLocale ?? this.adviceLocale,
      source: source ?? this.source,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  static Map<String, String> _parseLocaleMap(dynamic value) {
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
      } catch (_) {}
    }
    return {};
  }

  @override
  String toString() => 'CropCalendarEntry(crop: $crop, stage: $stage, months: $months)';
}
