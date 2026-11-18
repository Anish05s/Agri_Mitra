import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_theme.dart';
import 'core/constants.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_provider.dart';
import 'screens/consent_screen.dart';
import 'screens/data_cache_screen.dart';
import 'screens/home_screen.dart';
import 'screens/photo_diagnosis_screen.dart';
import 'screens/query_queue_screen.dart';
import 'package:flutter/foundation.dart';
import 'screens/voice_query_screen.dart';
import 'services/cloud_service.dart';
import 'services/database_service.dart';
import 'services/on_device_llm_service.dart';
import 'services/photo_service.dart';
import 'services/router_service.dart';
import 'services/sms_service.dart';
import 'services/speech_service.dart';
import 'services/sync_service.dart';

/// Entry point for 'Agri Mitra' - Hybrid Online+Offline Agricultural Advisory App.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize SharedPreferences for initial consent and locale determination
  final prefs = await SharedPreferences.getInstance();
  final hasConsented = prefs.getBool(AppConstants.prefConsentKey) ?? false;

  // 2. Initialize Core Services (skips SQLite on web - uses in-memory fallback)
  final dbService = DatabaseService();
  if (!kIsWeb) {
    await dbService.initDatabase();
  } else {
    await dbService.initInMemory(); // loads answer bank from JSON assets in-memory
  }

  final cloudService = CloudService();
  final llmService = MockOnDeviceLLM();
  await llmService.load(AppConstants.defaultModelPath);

  final routerService = RouterService(
    dbService: dbService,
    onDeviceLLM: llmService,
    cloudService: cloudService,
  );

  final syncService = SyncService(
    dbService: dbService,
    cloudService: cloudService,
  );

  final photoService = PhotoService();
  final smsService = SmsService();
  final speechService = SpeechService();
  await speechService.initSpeech();

  // 3. Initialize Provider
  final appProvider = AppProvider(
    dbService: dbService,
    routerService: routerService,
    cloudService: cloudService,
    syncService: syncService,
    photoService: photoService,
    smsService: smsService,
    llmService: llmService,
  );
  await appProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppProvider>.value(value: appProvider),
        ChangeNotifierProvider<SpeechService>.value(value: speechService),
        Provider<DatabaseService>.value(value: dbService),
        Provider<RouterService>.value(value: routerService),
        Provider<CloudService>.value(value: cloudService),
        Provider<SyncService>.value(value: syncService),
        Provider<PhotoService>.value(value: photoService),
        Provider<SmsService>.value(value: smsService),
        Provider<OnDeviceLLM>.value(value: llmService),
      ],
      child: AgriMitraApp(initialHasConsent: hasConsented),
    ),
  );
}

/// Root application widget for Agri Mitra.
class AgriMitraApp extends StatelessWidget {
  final bool initialHasConsent;

  const AgriMitraApp({
    super.key,
    required this.initialHasConsent,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Multilingual Localization Configuration (English, Hindi, Bengali)
      locale: Locale(provider.locale),
      supportedLocales: AppConstants.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Initial route based on farmer consent status
      initialRoute: (provider.consentGiven || initialHasConsent)
          ? AppConstants.routeHome
          : AppConstants.routeConsent,

      // Complete App Routes
      routes: {
        AppConstants.routeConsent: (context) => const ConsentScreen(),
        AppConstants.routeHome: (context) => const HomeScreen(),
        AppConstants.routeVoice: (context) => const VoiceQueryScreen(),
        AppConstants.routeDiagnosis: (context) => const PhotoDiagnosisScreen(),
        AppConstants.routeCache: (context) => const DataCacheScreen(),
        AppConstants.routeQueue: (context) => const QueryQueueScreen(),
      },
    );
  }
}
