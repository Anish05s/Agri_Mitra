import '../core/constants.dart';

/// Lifecycle status of an advisory query.
enum QueryStatus {
  local, // Resolved immediately from local answer bank or on-device AI
  cloud, // Resolved via cloud LLM / knowledge base
  queued, // Saved offline, waiting for connectivity to escalate
  sent, // Transmitted to expert / sync server, awaiting response
  answered, // Expert response received via sync or SMS
}

/// The architectural execution path chosen by the RouterService.
enum RoutingPath {
  onDevice, // Path 1: Exact/high-confidence match from SQLite answer bank
  onDeviceAI, // Path 2: Offline inference via SLM (e.g. Gemma 2B) with RAG context
  cloud, // Path 3: Online cloud inference via ICAR knowledge base
  queued, // Path 4: Offline low-confidence query queued for expert human/cloud sync
}

/// Represents an advisory query submitted by a farmer (via voice or text),
/// its routing metadata, AI/expert answers, and sync status.
class QueryModel {
  final String id;
  final String queryText;
  final String locale;
  final DateTime createdAt;
  QueryStatus status;
  RoutingPath? path;
  String? answerText;
  String? source;
  String? verifiedBy;
  String? lastUpdated;
  double? confidence;
  bool isHighConfidence; // confidence >= 0.75
  String? expertAnswer; // arrives after sync or SMS reply
  DateTime? lastSyncedAt;

  QueryModel({
    required this.id,
    required this.queryText,
    required this.locale,
    required this.createdAt,
    required this.status,
    this.path,
    this.answerText,
    this.source,
    this.verifiedBy,
    this.lastUpdated,
    this.confidence,
    bool? isHighConfidence,
    this.expertAnswer,
    this.lastSyncedAt,
  }) : isHighConfidence = isHighConfidence ?? ((confidence ?? 0.0) >= AppConstants.confidenceHigh);

  /// Helper to get user-friendly label for the routing path
  String get pathLabel {
    switch (path) {
      case RoutingPath.onDevice:
        return AppConstants.pathLabelOnDevice;
      case RoutingPath.onDeviceAI:
        return AppConstants.pathLabelOnDeviceAI;
      case RoutingPath.cloud:
        return AppConstants.pathLabelCloud;
      case RoutingPath.queued:
        return AppConstants.pathLabelQueued;
      case null:
        return 'Pending';
    }
  }

  /// Helper to get status display label
  String get statusLabel {
    switch (status) {
      case QueryStatus.local:
        return 'Resolved Offline';
      case QueryStatus.cloud:
        return 'Resolved via Cloud';
      case QueryStatus.queued:
        return 'Queued Offline';
      case QueryStatus.sent:
        return 'Sent to Expert';
      case QueryStatus.answered:
        return 'Expert Answered';
    }
  }

  /// Factory constructor to convert from SQLite map
  factory QueryModel.fromMap(Map<String, dynamic> map) {
    final conf = (map['confidence'] as num?)?.toDouble();
    return QueryModel(
      id: map['id'] as String,
      queryText: map['query_text'] as String? ?? '',
      locale: map['locale'] as String? ?? 'en',
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      status: _parseQueryStatus(map['status']),
      path: _parseRoutingPath(map['path']),
      answerText: map['answer_text'] as String?,
      source: map['source'] as String?,
      verifiedBy: map['verified_by'] as String?,
      lastUpdated: map['last_updated'] as String?,
      confidence: conf,
      isHighConfidence: map['is_high_confidence'] == 1 || (conf != null && conf >= AppConstants.confidenceHigh),
      expertAnswer: map['expert_answer'] as String?,
      lastSyncedAt: map['last_synced_at'] != null ? DateTime.tryParse(map['last_synced_at'] as String) : null,
    );
  }

  /// Converts this [QueryModel] to an SQLite compatible Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'query_text': queryText,
      'locale': locale,
      'created_at': createdAt.toIso8601String(),
      'status': status.name,
      'path': path?.name,
      'answer_text': answerText,
      'source': source,
      'verified_by': verifiedBy,
      'last_updated': lastUpdated,
      'confidence': confidence,
      'is_high_confidence': isHighConfidence ? 1 : 0,
      'expert_answer': expertAnswer,
      'last_synced_at': lastSyncedAt?.toIso8601String(),
    };
  }

  /// Factory constructor from JSON
  factory QueryModel.fromJson(Map<String, dynamic> json) => QueryModel.fromMap(json);

  /// Converts this [QueryModel] to JSON
  Map<String, dynamic> toJson() => toMap();

  QueryModel copyWith({
    String? id,
    String? queryText,
    String? locale,
    DateTime? createdAt,
    QueryStatus? status,
    RoutingPath? path,
    String? answerText,
    String? source,
    String? verifiedBy,
    String? lastUpdated,
    double? confidence,
    bool? isHighConfidence,
    String? expertAnswer,
    DateTime? lastSyncedAt,
  }) {
    return QueryModel(
      id: id ?? this.id,
      queryText: queryText ?? this.queryText,
      locale: locale ?? this.locale,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      path: path ?? this.path,
      answerText: answerText ?? this.answerText,
      source: source ?? this.source,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      confidence: confidence ?? this.confidence,
      isHighConfidence: isHighConfidence ?? this.isHighConfidence,
      expertAnswer: expertAnswer ?? this.expertAnswer,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  static QueryStatus _parseQueryStatus(dynamic value) {
    if (value == null) return QueryStatus.local;
    for (final s in QueryStatus.values) {
      if (s.name.toLowerCase() == value.toString().toLowerCase()) {
        return s;
      }
    }
    return QueryStatus.local;
  }

  static RoutingPath? _parseRoutingPath(dynamic value) {
    if (value == null) return null;
    for (final p in RoutingPath.values) {
      if (p.name.toLowerCase() == value.toString().toLowerCase()) {
        return p;
      }
    }
    return null;
  }

  @override
  String toString() => 'QueryModel(id: $id, query: $queryText, status: $status, path: $path, confidence: $confidence)';
}
