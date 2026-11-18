// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Agri Mitra';

  @override
  String get tagline => 'Offline-First Agricultural Intelligence for Farmers';

  @override
  String get consentTitle => 'Farmer Consent & Advisory Terms';

  @override
  String get consentBody =>
      'Agri Mitra provides scientific agricultural recommendations verified by ICAR and Krishi Vigyan Kendra (KVK). By continuing, you agree to follow chemical safety guidelines and understand that AI advice supplements local agricultural officers.';

  @override
  String get agreeAndContinue => 'I Agree & Continue';

  @override
  String get home => 'Home';

  @override
  String get voiceAdvisory => 'Voice Advisory';

  @override
  String get askQuestion => 'Ask a Crop Question';

  @override
  String get tapToSpeak => 'Tap Microphone to Speak';

  @override
  String get photoDiagnosis => 'Photo Diagnosis';

  @override
  String get offlineCache => 'Offline Knowledge Cache';

  @override
  String get syncQueue => 'Sync Queue';

  @override
  String get onlineMode => 'Online Mode';

  @override
  String get offlineMode => 'Offline Mode';

  @override
  String get syncNow => 'Sync With KVK Now';

  @override
  String get weatherAdvisory => 'Weather & Crop Advisory';

  @override
  String get mandiPrices => 'Mandi Bhav (APMC Rates)';

  @override
  String get cropCalendar => 'Seasonal Crop Calendar';

  @override
  String get confidenceHigh => 'Verified Answer (High Confidence)';

  @override
  String get confidenceMedium => 'On-Device AI (Medium Confidence)';

  @override
  String get confidenceLow => 'Escalated to KVK Expert';

  @override
  String get callHelpline => 'Call Kisan Helpline (1800-180-1551)';

  @override
  String get smsFallback => 'Send via Free SMS';

  @override
  String get kisanHelpline => 'Kisan Call Center: 1800-180-1551';
}
