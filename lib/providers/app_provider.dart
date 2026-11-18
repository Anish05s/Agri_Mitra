import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/constants.dart';
import '../models/answer_entry.dart';
import '../models/crop_calendar.dart';
import '../models/mandi_price.dart';
import '../models/query_model.dart';
import '../models/weather_cache.dart';
import '../services/cloud_service.dart';
import '../services/database_service.dart';
import '../services/on_device_llm_service.dart';
import '../services/photo_service.dart';
import '../services/router_service.dart';
import '../services/sms_service.dart';
import '../services/sync_service.dart';

/// Central state management Provider for Agri Mitra.
/// Manages user consent, offline/online switching, query history,
/// weather and mandi cache, and coordinates all background services.
class AppProvider extends ChangeNotifier {
  // Service Dependencies
  final DatabaseService _dbService;
  final RouterService _routerService;
  final CloudService _cloudService;
  final SyncService _syncService;
  final PhotoService _photoService;
  final SmsService _smsService;
  final OnDeviceLLM _llmService;
  final Uuid _uuid;

  // App State Variables
  String _locale = AppConstants.langEn;
  bool _isOnline = true; // Demo toggle: farmers/evaluators can toggle off internet
  bool _isConnected = true; // Hardware connectivity status
  List<QueryModel> _queryHistory = [];
  WeatherCache? _weather;
  List<MandiPrice> _mandiPrices = [];
  List<CropCalendarEntry> _cropCalendar = [];
  bool _consentGiven = false;
  bool _isSyncing = false;
  bool _isLoading = false;
  QueryResult? _currentQueryResult;
  DiagnosisResult? _latestDiagnosis;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  AppProvider({
    DatabaseService? dbService,
    RouterService? routerService,
    CloudService? cloudService,
    SyncService? syncService,
    PhotoService? photoService,
    SmsService? smsService,
    OnDeviceLLM? llmService,
  })  : _dbService = dbService ?? DatabaseService(),
        _cloudService = cloudService ?? CloudService(),
        _llmService = llmService ?? MockOnDeviceLLM(),
        _photoService = photoService ?? PhotoService(),
        _smsService = smsService ?? SmsService(),
        _routerService = routerService ??
            RouterService(
              dbService: dbService ?? DatabaseService(),
              onDeviceLLM: llmService ?? MockOnDeviceLLM(),
              cloudService: cloudService ?? CloudService(),
            ),
        _syncService = syncService ??
            SyncService(
              dbService: dbService ?? DatabaseService(),
              cloudService: cloudService ?? CloudService(),
            ),
        _uuid = const Uuid();

  // Getters
  String get locale => _locale;
  bool get isOnline => _isOnline;
  bool get isConnected => _isConnected;
  bool get effectiveOnline => _isOnline && _isConnected;
  List<QueryModel> get queryHistory => List.unmodifiable(_queryHistory);
  WeatherCache? get weather => _weather;
  List<MandiPrice> get mandiPrices => List.unmodifiable(_mandiPrices);
  List<CropCalendarEntry> get cropCalendar => List.unmodifiable(_cropCalendar);
  bool get consentGiven => _consentGiven;
  bool get isSyncing => _isSyncing;
  bool get isLoading => _isLoading;
  QueryResult? get currentQueryResult => _currentQueryResult;
  DiagnosisResult? get latestDiagnosis => _latestDiagnosis;

  int get pendingQueriesCount => _queryHistory
      .where((q) => q.status == QueryStatus.queued || q.status == QueryStatus.sent)
      .length;

  /// Initializes the provider, loads preferences, boots SQLite, and hydrates state.
  Future<void> init() async {
    try {
      // 1. SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _consentGiven = prefs.getBool(AppConstants.prefConsentKey) ?? false;
      _locale = prefs.getString(AppConstants.prefLocaleKey) ?? AppConstants.langEn;
      _isOnline = prefs.getBool(AppConstants.prefOnlineModeKey) ?? true;

      // 2. Database & Data Hydration
      if (kIsWeb) {
        await _dbService.initInMemory();
      } else {
        await _dbService.initDatabase();
      }
      _queryHistory = await _dbService.getAllQueries();
      _weather = await _dbService.getWeather();
      _mandiPrices = await _dbService.getMandiPrices();
      _cropCalendar = await _dbService.getCropCalendar();

      // 3. Initialize on-device SLM
      _llmService.load(AppConstants.defaultModelPath).catchError((e) {
        debugPrint('SLM preload warning: $e');
      });

      // 4. Set up Auto-sync callbacks
      _syncService.addListener(_handleSyncUpdate);
      _syncService.startAutoSync(isOnlineCheck: () => effectiveOnline);

      // 5. Monitor hardware network connectivity
      _initConnectivityMonitoring();

      notifyListeners();
    } catch (e) {
      debugPrint('Error during AppProvider.init(): $e');
    }
  }

  void _initConnectivityMonitoring() {
    try {
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
        final connected = result != ConnectivityResult.none;
        if (_isConnected != connected) {
          _isConnected = connected;
          notifyListeners();
          if (effectiveOnline) {
            syncNow(); // Auto-sync pending queries when connectivity returns
          }
        }
      });
    } catch (e) {
      debugPrint('Connectivity monitoring fallback: $e');
    }
  }

  void _handleSyncUpdate() {
    if (_isSyncing != _syncService.isSyncing) {
      _isSyncing = _syncService.isSyncing;
      notifyListeners();
    }
  }

  /// Toggles demo online mode (allows testing offline behavior without Airplane mode).
  void toggleOnlineMode() async {
    _isOnline = !_isOnline;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnlineModeKey, _isOnline);
    notifyListeners();

    if (effectiveOnline) {
      syncNow();
    }
  }

  /// Sets the farmer's preferred language ('en', 'hi', or 'bn').
  void setLocale(String newLocale) async {
    if (!AppConstants.supportedLocales.any((l) => l.languageCode == newLocale)) {
      return;
    }
    _locale = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefLocaleKey, newLocale);
    notifyListeners();
  }

  /// Saves farmer's informed consent.
  Future<void> setConsent(bool given) async {
    _consentGiven = given;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefConsentKey, given);
    notifyListeners();
  }

  /// Submits an advisory query (from voice speech-to-text or typed input).
  /// Routes through RouterService and stores in SQLite.
  Future<QueryResult> submitQuery(String text) async {
    final queryClean = text.trim();
    if (queryClean.isEmpty) {
      throw ArgumentError('Query text cannot be empty');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final queryId = _uuid.v4();

      // Execute intelligent routing
      final result = await _routerService.route(
        queryClean,
        _locale,
        effectiveOnline,
      );

      // Determine initial query status
      QueryStatus status;
      if (result.path == RoutingPath.queued) {
        status = QueryStatus.queued;
      } else if (result.path == RoutingPath.cloud) {
        status = QueryStatus.cloud;
      } else {
        status = QueryStatus.local;
      }

      final queryModel = QueryModel(
        id: queryId,
        queryText: queryClean,
        locale: _locale,
        createdAt: DateTime.now(),
        status: status,
        path: result.path,
        answerText: result.answer,
        source: result.source,
        verifiedBy: result.verifiedBy,
        lastUpdated: result.lastUpdated,
        confidence: result.confidence,
        isHighConfidence: result.isHighConfidence,
        lastSyncedAt: result.lastSyncedAt,
      );

      // Persist to local database
      await _dbService.insertQuery(queryModel);

      // Update state
      _queryHistory.insert(0, queryModel);
      _currentQueryResult = result;
      _isLoading = false;
      notifyListeners();

      // Trigger automatic sync if online and queued
      if (effectiveOnline && status == QueryStatus.queued) {
        syncNow();
      }

      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Diagnoses plant pathology from a photographed leaf or crop symptom.
  Future<DiagnosisResult> diagnosePhoto(XFile imageFile) async {
    _isLoading = true;
    notifyListeners();

    try {
      final diagnosis = await _photoService.diagnose(imageFile);
      _latestDiagnosis = diagnosis;

      if (diagnosis.success) {
        // Automatically create a query history item for tracking
        final diseaseText = diagnosis.disease ?? 'Crop issue';
        final queryId = _uuid.v4();

        final queryModel = QueryModel(
          id: queryId,
          queryText: 'Photo Diagnosis: ${diagnosis.crop ?? 'Plant'} - $diseaseText',
          locale: _locale,
          createdAt: DateTime.now(),
          status: diagnosis.isEscalated ? QueryStatus.queued : QueryStatus.local,
          path: diagnosis.isEscalated ? RoutingPath.queued : RoutingPath.onDevice,
          answerText: diagnosis.treatment ?? 'Consult local KVK for treatment details.',
          source: diagnosis.source ?? 'ICAR Computer Vision',
          verifiedBy: diagnosis.isEscalated ? 'Escalated to KVK Agronomist' : 'ICAR Automated Plant Doctor',
          lastUpdated: DateTime.now().toIso8601String().substring(0, 10),
          confidence: diagnosis.confidence,
          isHighConfidence: diagnosis.isHighConfidence,
        );

        await _dbService.insertQuery(queryModel);
        _queryHistory.insert(0, queryModel);
      }

      _isLoading = false;
      notifyListeners();
      return diagnosis;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Sends query via SMS fallback if device has zero internet.
  Future<SmsResult> sendViaSms(String queryText, [String? phoneNumber]) async {
    _isLoading = true;
    notifyListeners();

    try {
      final smsResult = await _smsService.sendQuery(
        queryText,
        phoneNumber ?? AppConstants.smsMockNumber,
      );

      // Log in query history as sent
      final queryModel = QueryModel(
        id: _uuid.v4(),
        queryText: 'SMS Query: $queryText',
        locale: _locale,
        createdAt: DateTime.now(),
        status: QueryStatus.sent,
        path: RoutingPath.queued,
        answerText: smsResult.mockReply,
        source: 'SMS / Kisan Call Center Gateway',
        verifiedBy: 'Kisan Call Center Operator',
        lastUpdated: DateTime.now().toIso8601String().substring(0, 10),
        confidence: 0.80,
      );

      await _dbService.insertQuery(queryModel);
      _queryHistory.insert(0, queryModel);

      _isLoading = false;
      notifyListeners();
      return smsResult;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Triggers immediate on-demand synchronization.
  Future<SyncResult> syncNow() async {
    _isSyncing = true;
    notifyListeners();

    final result = await _syncService.sync(isOnline: effectiveOnline);

    // Refresh state from DB
    _queryHistory = await _dbService.getAllQueries();
    _weather = await _dbService.getWeather();
    _mandiPrices = await _dbService.getMandiPrices();
    _cropCalendar = await _dbService.getCropCalendar();

    _isSyncing = false;
    notifyListeners();
    return result;
  }

  /// Refreshes weather and mandi prices explicitly.
  Future<void> refreshWeatherAndPrices() async {
    await _syncService.fetchWeatherAndPrices();
    _weather = await _dbService.getWeather();
    _mandiPrices = await _dbService.getMandiPrices();
    _cropCalendar = await _dbService.getCropCalendar();
    notifyListeners();
  }

  /// Clears local query history.
  Future<void> clearHistory() async {
    for (final q in _queryHistory) {
      await _dbService.deleteQuery(q.id);
    }
    _queryHistory.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncService.removeListener(_handleSyncUpdate);
    _syncService.dispose();
    super.dispose();
  }
}
