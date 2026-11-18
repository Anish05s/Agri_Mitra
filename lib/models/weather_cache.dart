/// Represents offline cached agrometeorological weather data for the farmer's district.
/// Source: India Meteorological Department (IMD) / Gramin Krishi Mausam Sewa.
class WeatherCache {
  final String location;
  final double tempCelsius;
  final String condition; // e.g. 'Partly Cloudy', 'Sunny', 'Light Rain'
  final int humidity; // percentage e.g. 78
  final double windKmh; // wind speed in km/h
  final String rainfall; // e.g. '12mm expected', 'No rain expected'
  final String source; // e.g. 'IMD'
  final DateTime fetchedAt;
  final DateTime lastSyncedAt;

  const WeatherCache({
    required this.location,
    required this.tempCelsius,
    required this.condition,
    required this.humidity,
    required this.windKmh,
    required this.rainfall,
    required this.source,
    required this.fetchedAt,
    required this.lastSyncedAt,
  });

  /// Factory constructor from SQLite database map.
  factory WeatherCache.fromMap(Map<String, dynamic> map) {
    return WeatherCache(
      location: map['location'] as String? ?? 'West Bengal',
      tempCelsius: (map['temp_celsius'] as num?)?.toDouble() ?? 28.5,
      condition: map['condition'] as String? ?? 'Partly Cloudy',
      humidity: (map['humidity'] as num?)?.toInt() ?? 75,
      windKmh: (map['wind_kmh'] as num?)?.toDouble() ?? 12.0,
      rainfall: map['rainfall'] as String? ?? '0mm',
      source: map['source'] as String? ?? 'IMD',
      fetchedAt: DateTime.tryParse(map['fetched_at'] as String? ?? '') ?? DateTime.now(),
      lastSyncedAt: DateTime.tryParse(map['last_synced_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  /// Converts to an SQLite compatible Map
  Map<String, dynamic> toMap() {
    return {
      'id': 1, // Single-row cache table
      'location': location,
      'temp_celsius': tempCelsius,
      'condition': condition,
      'humidity': humidity,
      'wind_kmh': windKmh,
      'rainfall': rainfall,
      'source': source,
      'fetched_at': fetchedAt.toIso8601String(),
      'last_synced_at': lastSyncedAt.toIso8601String(),
    };
  }

  /// Factory constructor from JSON
  factory WeatherCache.fromJson(Map<String, dynamic> json) => WeatherCache.fromMap(json);

  /// Converts to JSON
  Map<String, dynamic> toJson() => toMap();

  WeatherCache copyWith({
    String? location,
    double? tempCelsius,
    String? condition,
    int? humidity,
    double? windKmh,
    String? rainfall,
    String? source,
    DateTime? fetchedAt,
    DateTime? lastSyncedAt,
  }) {
    return WeatherCache(
      location: location ?? this.location,
      tempCelsius: tempCelsius ?? this.tempCelsius,
      condition: condition ?? this.condition,
      humidity: humidity ?? this.humidity,
      windKmh: windKmh ?? this.windKmh,
      rainfall: rainfall ?? this.rainfall,
      source: source ?? this.source,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  String toString() =>
      'WeatherCache(location: $location, temp: ${tempCelsius}°C, condition: $condition, rainfall: $rainfall)';
}
