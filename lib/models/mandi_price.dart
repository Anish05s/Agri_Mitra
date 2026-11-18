/// Represents agricultural market price (Mandi Bhav) cached offline for local APMC markets.
/// Source: Agmarknet (Directorate of Marketing & Inspection, Ministry of Agriculture).
class MandiPrice {
  final String crop; // e.g. 'Rice', 'Potato', 'Jute'
  final String variety; // e.g. 'Swarna', 'Jyoti', 'TD-5'
  final String market; // e.g. 'Hooghly Mandi', 'Burdwan Mandi'
  final double minPrice; // Minimum price per quintal in INR
  final double maxPrice; // Maximum price per quintal in INR
  final double modalPrice; // Modal (most frequent) price per quintal in INR
  final String unit; // e.g. 'per quintal'
  final DateTime date; // Reporting date
  final String source; // e.g. 'Agmarknet'
  final DateTime lastSyncedAt; // Timestamp when synced into local device

  const MandiPrice({
    required this.crop,
    required this.variety,
    required this.market,
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
    required this.unit,
    required this.date,
    required this.source,
    required this.lastSyncedAt,
  });

  /// Factory constructor from SQLite database map
  factory MandiPrice.fromMap(Map<String, dynamic> map) {
    return MandiPrice(
      crop: map['crop'] as String? ?? '',
      variety: map['variety'] as String? ?? 'Common',
      market: map['market'] as String? ?? 'Local APMC',
      minPrice: (map['min_price'] as num?)?.toDouble() ?? 0.0,
      maxPrice: (map['max_price'] as num?)?.toDouble() ?? 0.0,
      modalPrice: (map['modal_price'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String? ?? 'per quintal',
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      source: map['source'] as String? ?? 'Agmarknet',
      lastSyncedAt: DateTime.tryParse(map['last_synced_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  /// Converts this [MandiPrice] to an SQLite compatible Map
  Map<String, dynamic> toMap() {
    return {
      'crop': crop,
      'variety': variety,
      'market': market,
      'min_price': minPrice,
      'max_price': maxPrice,
      'modal_price': modalPrice,
      'unit': unit,
      'date': date.toIso8601String().substring(0, 10),
      'source': source,
      'last_synced_at': lastSyncedAt.toIso8601String(),
    };
  }

  /// Factory constructor from JSON
  factory MandiPrice.fromJson(Map<String, dynamic> json) => MandiPrice.fromMap(json);

  /// Converts to JSON
  Map<String, dynamic> toJson() => toMap();

  MandiPrice copyWith({
    String? crop,
    String? variety,
    String? market,
    double? minPrice,
    double? maxPrice,
    double? modalPrice,
    String? unit,
    DateTime? date,
    String? source,
    DateTime? lastSyncedAt,
  }) {
    return MandiPrice(
      crop: crop ?? this.crop,
      variety: variety ?? this.variety,
      market: market ?? this.market,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      modalPrice: modalPrice ?? this.modalPrice,
      unit: unit ?? this.unit,
      date: date ?? this.date,
      source: source ?? this.source,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  String get formattedModalPrice => '₹${modalPrice.toStringAsFixed(0)} / quintal';

  @override
  String toString() =>
      'MandiPrice(crop: $crop, market: $market, modalPrice: ₹$modalPrice, date: ${date.toIso8601String().substring(0,10)})';
}
