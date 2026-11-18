// Agri Mitra - Speech Service
// Wraps speech_to_text (STT) and flutter_tts (TTS)
// Supports English, Hindi, and Bengali with Android locale codes

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SpeechService extends ChangeNotifier {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  bool _isSpeaking = false;
  String _lastWords = '';
  bool _sttAvailable = false;
  bool _initialized = false;

  // Public getters
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String get lastWords => _lastWords;
  bool get isAvailable => _sttAvailable;

  /// Map from app locale codes to Android STT locale IDs
  static const Map<String, String> _sttLocaleMap = {
    'en': 'en_IN',
    'hi': 'hi_IN',
    'bn': 'bn_IN',
    // Future languages:
    // 'or': 'or_IN',
    // 'ta': 'ta_IN',
    // 'te': 'te_IN',
    // 'mr': 'mr_IN',
    // 'pa': 'pa_IN',
  };

  /// Map from app locale codes to TTS BCP-47 language tags
  static const Map<String, String> _ttsLangMap = {
    'en': 'en-IN',
    'hi': 'hi-IN',
    'bn': 'bn-IN',
    // Future languages:
    // 'or': 'or-IN',
    // 'ta': 'ta-IN',
    // 'te': 'te-IN',
    // 'mr': 'mr-IN',
    // 'pa': 'pa-IN',
  };

  /// Initialize both STT and TTS engines
  Future<void> initSpeech() async {
    if (_initialized) return;

    // Initialize STT
    _sttAvailable = await _stt.initialize(
      onError: (errorNotification) {
        debugPrint('[STT] Error: ${errorNotification.errorMsg}');
        _isListening = false;
        notifyListeners();
      },
      onStatus: (status) {
        debugPrint('[STT] Status: $status');
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
          notifyListeners();
        }
      },
    );

    // Initialize TTS
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.5);  // Slower for better comprehension
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    // Listen for TTS completion
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });

    _tts.setStartHandler(() {
      _isSpeaking = true;
      notifyListeners();
    });

    _initialized = true;
    debugPrint('[Speech] Initialized — STT available: $_sttAvailable');
    notifyListeners();
  }

  /// Start listening for speech input
  Future<void> startListening({
    required Function(String words) onResult,
    required String locale,
  }) async {
    if (!_sttAvailable) {
      debugPrint('[STT] Not available — microphone permission may be denied');
      return;
    }
    if (_isListening) return;

    _lastWords = '';
    _isListening = true;
    notifyListeners();

    final localeId = _sttLocaleMap[locale] ?? 'en_IN';

    await _stt.listen(
      onResult: (result) {
        _lastWords = result.recognizedWords;
        onResult(_lastWords);
        if (result.finalResult) {
          _isListening = false;
        }
        notifyListeners();
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: localeId,
      cancelOnError: true,
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;
    await _stt.stop();
    _isListening = false;
    notifyListeners();
  }

  /// Cancel listening (discard result)
  Future<void> cancelListening() async {
    await _stt.cancel();
    _isListening = false;
    _lastWords = '';
    notifyListeners();
  }

  /// Speak text aloud using TTS
  Future<void> speak(String text, String locale) async {
    if (_isSpeaking) {
      await stop(); // Stop current speech first
    }

    final lang = _ttsLangMap[locale] ?? 'en-IN';
    await _tts.setLanguage(lang);

    _isSpeaking = true;
    notifyListeners();

    await _tts.speak(text);
    // _isSpeaking = false is set in completion handler
  }

  /// Stop TTS playback
  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _stt.cancel();
    _tts.stop();
    super.dispose();
  }
}
