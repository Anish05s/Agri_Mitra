import 'package:flutter/material.dart';

/// App-wide constants for Agri Mitra.
/// Contains confidence thresholds, routing labels, database table names,
/// SMS mock configurations, routes, and shared preferences keys.
class AppConstants {
  AppConstants._();

  // App Identity
  static const String appName = 'Agri Mitra';
  static const String appVersion = '1.0.0';

  // Confidence Thresholds
  static const double confidenceHigh = 0.75;
  static const double confidenceMedium = 0.50;
  static const double confidenceLow = 0.50; // Anything strictly below 0.50

  // Routing Path Labels
  static const String pathLabelOnDevice = 'On-device Answer';
  static const String pathLabelOnDeviceAI = 'On-device AI';
  static const String pathLabelCloud = 'Cloud AI';
  static const String pathLabelQueued = 'Queued';

  // Database Constants
  static const String databaseName = 'agri_mitra.db';
  static const int databaseVersion = 1;

  static const String tableAnswerBank = 'answer_bank';
  static const String tableQueryQueue = 'query_queue';
  static const String tableWeatherCache = 'weather_cache';
  static const String tableMandiPrices = 'mandi_prices';
  static const String tableCropCalendar = 'crop_calendar';

  // SMS & Helpline Constants
  static const String smsMockNumber = '18001801551'; // KVK Kisan Call Center Helpline
  static const String kisanHelplineDisplay = '1800-180-1551';
  static const String smsEmergencyUssd = '*99*99#';

  // Sync Constants
  static const Duration syncInterval = Duration(seconds: 30);
  static const String cloudMockEndpoint = 'https://api.agrimitra.mock/v1/query';
  static const String defaultModelPath = 'models/gemma-2b-it-q4.gguf';

  // Supported Locales
  static const String langEn = 'en';
  static const String langHi = 'hi';
  static const String langBn = 'bn';

  static const List<Locale> supportedLocales = [
    Locale(langEn),
    Locale(langHi),
    Locale(langBn),
  ];

  static const Map<String, String> languageNames = {
    langEn: 'English',
    langHi: 'हिंदी (Hindi)',
    langBn: 'বাংলা (Bengali)',
  };

  // Supported Priority Crops
  static const String cropRice = 'rice';
  static const String cropPotato = 'potato';
  static const String cropJute = 'jute';

  static const List<String> supportedCrops = [
    cropRice,
    cropPotato,
    cropJute,
  ];

  // SharedPreferences Keys
  static const String prefConsentKey = 'farmer_consent_given';
  static const String prefLocaleKey = 'app_locale';
  static const String prefOnlineModeKey = 'online_mode_toggle';

  // Route Names
  static const String routeConsent = '/consent';
  static const String routeHome = '/';
  static const String routeVoice = '/voice';
  static const String routeDiagnosis = '/diagnosis';
  static const String routeCache = '/cache';
  static const String routeQueue = '/queue';
}
