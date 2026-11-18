import 'dart:async';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../models/query_model.dart';
import 'cloud_service.dart';
import 'database_service.dart';

/// Result summary returned after a sync cycle.
class SyncResult {
  final int syncedQueriesCount;
  final bool weatherUpdated;
  final bool mandiUpdated;
  final DateTime timestamp;
  final bool success;
  final String? errorMessage;

  const SyncResult({
    required this.syncedQueriesCount,
    required this.weatherUpdated,
    required this.mandiUpdated,
    required this.timestamp,
    required this.success,
    this.errorMessage,
  });

  @override
  String toString() =>
      'SyncResult(synced: $syncedQueriesCount, weather: $weatherUpdated, mandi: $mandiUpdated, success: $success)';
}

/// Service that manages automatic and manual synchronization between
/// local SQLite storage and remote cloud services when connectivity is available.
class SyncService {
  final DatabaseService _dbService;
  final CloudService _cloudService;

  Timer? _syncTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncedAt;
  final List<VoidCallback> _listeners = [];

  SyncService({
    DatabaseService? dbService,
    CloudService? cloudService,
  })  : _dbService = dbService ?? DatabaseService(),
        _cloudService = cloudService ?? CloudService();

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  void addListener(VoidCallback listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      try {
        listener();
      } catch (e) {
        debugPrint('Error notifying sync listener: $e');
      }
    }
  }

  /// Starts recurring background sync timer (every 30 seconds).
  void startAutoSync({bool Function()? isOnlineCheck}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(AppConstants.syncInterval, (_) async {
      final online = isOnlineCheck != null ? isOnlineCheck() : true;
      if (online && !_isSyncing) {
        await sync(isOnline: true);
      }
    });
  }

  /// Stops recurring background sync timer.
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Executes full synchronization cycle:
  /// 1. Retrieves pending/queued queries from SQLite
  /// 2. Calls CloudService.syncQueuedQueries
  /// 3. Updates query statuses and answers in SQLite
  /// 4. Fetches and caches fresh IMD weather and Agmarknet mandi prices
  /// 5. Notifies registered listeners
  Future<SyncResult> sync({bool isOnline = true}) async {
    if (!isOnline) {
      return SyncResult(
        syncedQueriesCount: 0,
        weatherUpdated: false,
        mandiUpdated: false,
        timestamp: DateTime.now(),
        success: false,
        errorMessage: 'Device is offline',
      );
    }

    if (_isSyncing) {
      return SyncResult(
        syncedQueriesCount: 0,
        weatherUpdated: false,
        mandiUpdated: false,
        timestamp: DateTime.now(),
        success: false,
        errorMessage: 'Sync already in progress',
      );
    }

    _isSyncing = true;
    _notifyListeners();

    try {
      int syncedCount = 0;

      // 1. Get pending queries from DB
      final pendingQueries = await _dbService.getPendingQueries();

      // 2. Resolve queued queries via Cloud Service / KVK experts
      if (pendingQueries.isNotEmpty) {
        final expertAnswers = await _cloudService.syncQueuedQueries(pendingQueries);

        final answerMap = {for (var a in expertAnswers) a.queryId: a};

        for (final query in pendingQueries) {
          final expertResp = answerMap[query.id];
          if (expertResp != null) {
            query.expertAnswer = expertResp.answer;
            query.status = QueryStatus.answered;
            query.verifiedBy = expertResp.answeredBy;
            query.lastSyncedAt = expertResp.answeredAt;
            query.lastUpdated = expertResp.answeredAt.toIso8601String().substring(0, 10);
            await _dbService.updateQuery(query);
            syncedCount++;
          }
        }
      }

      // 3. Fetch and cache fresh weather and prices
      await fetchWeatherAndPrices();

      _lastSyncedAt = DateTime.now();
      _isSyncing = false;
      _notifyListeners();

      return SyncResult(
        syncedQueriesCount: syncedCount,
        weatherUpdated: true,
        mandiUpdated: true,
        timestamp: _lastSyncedAt!,
        success: true,
      );
    } catch (e) {
      _isSyncing = false;
      _notifyListeners();
      return SyncResult(
        syncedQueriesCount: 0,
        weatherUpdated: false,
        mandiUpdated: false,
        timestamp: DateTime.now(),
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Fetches fresh weather and mandi prices and updates SQLite cache.
  Future<void> fetchWeatherAndPrices() async {
    try {
      final freshWeather = await _cloudService.fetchFreshWeather();
      await _dbService.cacheWeather(freshWeather);

      final freshPrices = await _cloudService.fetchFreshMandiPrices();
      await _dbService.cacheMandiPrices(freshPrices);

      final freshCalendar = await _cloudService.fetchCropCalendar();
      await _dbService.cacheCropCalendar(freshCalendar);
    } catch (e) {
      debugPrint('Error fetching weather and prices: $e');
    }
  }

  void dispose() {
    stopAutoSync();
    _listeners.clear();
  }
}
