// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'एग्री मित्र';

  @override
  String get tagline => 'किसानों के लिए ऑफ़लाइन कृषि ज्ञान';

  @override
  String get consentTitle => 'किसान सहमति एवं सेवा शर्तें';

  @override
  String get consentBody =>
      'एग्री मित्र ICAR और कृषि विज्ञान केंद्र (KVK) द्वारा सत्यापित वैज्ञानिक सलाह प्रदान करता है। कीटनाशक व उर्वरक के उपयोग में सुरक्षा नियमों का पालन करें।';

  @override
  String get agreeAndContinue => 'मैं सहमत हूँ और आगे बढ़ें';

  @override
  String get home => 'मुख्य पृष्ठ';

  @override
  String get voiceAdvisory => 'बोलकर पूछें';

  @override
  String get askQuestion => 'फसल संबंधी सवाल पूछें';

  @override
  String get tapToSpeak => 'बोलने के लिए माइक दबाएं';

  @override
  String get photoDiagnosis => 'फोटो से रोग पहचान';

  @override
  String get offlineCache => 'ऑफ़लाइन ज्ञान भंडार';

  @override
  String get syncQueue => 'सिंक कतार';

  @override
  String get onlineMode => 'ऑनलाइन मोड';

  @override
  String get offlineMode => 'ऑफ़लाइन मोड';

  @override
  String get syncNow => 'अभी सिंक करें';

  @override
  String get weatherAdvisory => 'मौसम एवं कृषि सलाह';

  @override
  String get mandiPrices => 'मंडी भाव (ताज़ा दरें)';

  @override
  String get cropCalendar => 'फसल कैलेंडर';

  @override
  String get confidenceHigh => 'सत्यापित उत्तर (उच्च विश्वास)';

  @override
  String get confidenceMedium => 'डिवाइस AI (मध्यम विश्वास)';

  @override
  String get confidenceLow => 'KVK विशेषज्ञ को भेजा गया';

  @override
  String get callHelpline => 'किसान हेल्पलाइन पर कॉल करें (1800-180-1551)';

  @override
  String get smsFallback => 'मुफ़्त SMS से भेजें';

  @override
  String get kisanHelpline => 'किसान कॉल सेंटर: 1800-180-1551';
}
