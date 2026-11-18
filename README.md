# Agri Mitra 🌾
### Hybrid Online + Offline Farmer Advisory System

A demo Android app for small and marginal farmers that works **online and offline**, featuring voice-first UI, multilingual support (English/Hindi/Bengali), expert-verified agricultural advice, photo diagnosis, and intelligent routing between on-device, AI, and cloud channels.

---

## 📋 Table of Contents
- [What's Real vs. Mocked](#whats-real-vs-mocked)
- [Architecture](#architecture)
- [Setup Instructions](#setup-instructions)
- [Project Structure](#project-structure)
- [5-Step Demo Script](#5-step-demo-script)
- [On-Device LLM Integration](#on-device-llm-integration)
- [Adding New Languages](#adding-new-languages)
- [Seed Data](#seed-data)

---

## ✅ What's Real vs. Mocked

| Feature | Status | Notes |
|---|---|---|
| Flutter UI (all screens) | ✅ **Real** | Runs on Android 8.0+ (API 26+) |
| SQLite local database | ✅ **Real** | sqflite — persists across sessions |
| Speech-to-Text (STT) | ✅ **Real** | Android speech_to_text — uses device STT engine |
| Text-to-Speech (TTS) | ✅ **Real** | flutter_tts — uses Android TTS engine |
| Image picker (camera/gallery) | ✅ **Real** | image_picker with permissions |
| Connectivity detection | ✅ **Real** | connectivity_plus monitors actual network state |
| Local keyword search | ✅ **Real** | Scores 42 Q&A entries against query words |
| Confidence-based routing | ✅ **Real** | Decision tree with HIGH/MEDIUM/LOW thresholds |
| SQLite query queue | ✅ **Real** | Queued queries persist and sync when online |
| Consent screen (DPDP-style) | ✅ **Real** | SharedPreferences-persisted consent |
| Multilingual UI (EN/HI/BN) | ✅ **Real** | Flutter l10n with ARB files |
| Cloud AI endpoint | 🔶 **Mocked** | Returns templated responses; swap URL for real LLM |
| On-device AI (Gemma) | 🔶 **Mocked** | Interface defined; MockOnDeviceLLM used in demo |
| Photo crop diagnosis | 🔶 **Mocked** | Quality check is real; diagnosis from pre-set list |
| SMS send/receive | 🔶 **Mocked** | Simulates send + mock reply; no real SMS sent |
| Weather data (IMD) | 🔶 **Mocked** | Static JSON + refreshed on sync with mock values |
| Mandi prices (Agmarknet) | 🔶 **Mocked** | Static JSON + refreshed on sync |
| Expert answers via sync | 🔶 **Mocked** | Cloud service returns templated expert replies |
| IVR helpline | 🔶 **Mocked** | Shows number; no actual phone call |

---

## 🏗️ Architecture

```
lib/
├── main.dart                    # Entry point, MultiProvider setup
├── core/
│   ├── app_theme.dart           # Complete Material3 theme
│   └── constants.dart           # Thresholds, DB names, locale codes
├── models/
│   └── models.dart              # All data models (AnswerEntry, QueryModel, ...)
├── services/
│   ├── database_service.dart    # SQLite CRUD + keyword search
│   ├── router_service.dart      # Routing decision tree
│   ├── on_device_llm_service.dart  # OnDeviceLLM interface + MockOnDeviceLLM
│   ├── cloud_service.dart       # Mock cloud AI + expert sync
│   ├── sync_service.dart        # Auto-sync with connectivity monitoring
│   ├── speech_service.dart      # STT + TTS wrapper
│   ├── photo_service.dart       # Image pick + mock diagnosis
│   └── sms_service.dart         # Mock SMS/IVR
├── providers/
│   └── app_provider.dart        # Central state (ChangeNotifier)
├── screens/
│   ├── consent_screen.dart      # First-launch DPDP consent
│   ├── home_screen.dart         # Main: mic, text query, history
│   ├── answer_screen.dart       # Answer with routing/confidence/source
│   ├── photo_diagnosis_screen.dart  # Camera + diagnosis result
│   ├── data_cache_screen.dart   # Weather/prices/calendar tabs
│   ├── query_queue_screen.dart  # Queue management + sync
│   └── sms_fallback_screen.dart # SMS/IVR simulation
└── widgets/
    └── widgets.dart             # Shared: MicButton, ConfidenceBadge, ...
```

### Routing Decision Tree

```
User Query
    │
    ▼
Search local answer bank (keyword + confidence scoring)
    │
    ├─ confidence ≥ 0.75 (HIGH)
    │       └─→ ✅ On-device Answer  [path label: "On-device Answer"]
    │
    ├─ confidence ≥ 0.50 (MEDIUM)
    │       ├─ Offline → 🤖 On-device AI (MockOnDeviceLLM)  ["On-device AI"]
    │       └─ Online  → ☁️ Cloud AI endpoint               ["Cloud AI"]
    │
    └─ confidence < 0.50 (LOW)
            ├─ Online  → ☁️ Cloud AI endpoint               ["Cloud AI"]
            └─ Offline → 📋 Queue + ask follow-up           ["Queued"]
```

---

## 🛠️ Setup Instructions

### Prerequisites

1. **Flutter SDK** ≥ 3.0.0 — [Install Flutter](https://docs.flutter.dev/get-started/install/windows)
2. **Android Studio** with Android SDK (API 34, build tools)
3. **Android device or emulator** with API ≥ 26 (Android 8.0 Oreo)
4. **Google TTS** installed on device (most Android devices have it)

### Quick Start

```bash
# 1. Navigate to project
cd "d:\Agri Mitra\agri_mitra"

# 2. Install dependencies
flutter pub get

# 3. Generate localizations
flutter gen-l10n

# 4. Run on connected Android device
flutter run

# 5. Build release APK
flutter build apk --release
```

### First-Time Android Setup

If targeting a physical device:
- Enable Developer Options on device
- Enable USB Debugging
- Connect via USB and accept the trust prompt
- Verify: `flutter devices`

### Fonts (Optional but recommended)

Download NotoSans font files and place in `assets/fonts/`:
- `NotoSans-Regular.ttf` — from [Google Fonts](https://fonts.google.com/noto)
- `NotoSans-Bold.ttf`

> The app works without the fonts (falls back to system default).

---

## 📁 Project Structure (Key Files)

| File | Purpose |
|---|---|
| [`pubspec.yaml`](pubspec.yaml) | Dependencies and asset declarations |
| [`assets/data/answer_bank.json`](assets/data/answer_bank.json) | 42 Q&A entries (Rice/Potato/Jute) |
| [`assets/data/weather_mock.json`](assets/data/weather_mock.json) | Mock IMD weather data |
| [`assets/data/mandi_prices_mock.json`](assets/data/mandi_prices_mock.json) | Mock Agmarknet prices |
| [`assets/data/crop_calendar_mock.json`](assets/data/crop_calendar_mock.json) | Crop stage calendar |
| [`lib/l10n/app_en.arb`](lib/l10n/app_en.arb) | English strings |
| [`lib/l10n/app_hi.arb`](lib/l10n/app_hi.arb) | Hindi strings |
| [`lib/l10n/app_bn.arb`](lib/l10n/app_bn.arb) | Bengali strings |
| [`android/app/src/main/AndroidManifest.xml`](android/app/src/main/AndroidManifest.xml) | Permissions + package |

---

## 🎬 5-Step Demo Script

### Step 1 — Ask by Voice (Offline Mode)

1. Toggle **"Go Offline (Demo)"** switch → banner turns red "Offline (Demo)"
2. Tap the **big green mic button**
3. Say: *"Rice leaves are turning yellow, there are insects on the stem"*
4. Watch transcription appear below the mic
5. Tap **"Ask"**
6. ✅ **Expected**: Answer screen shows routing chip **"On-device Answer"** (blue) or **"On-device AI"** (purple), with ICAR source and date

> **What to show**: The app works fully offline. The routing path shows "On-device" confirming no cloud call was made.

---

### Step 2 — Ask a Complex Question Online

1. Toggle offline mode **OFF** → banner turns green "Online"
2. Type: *"My rice field has blast disease spreading rapidly after the recent rain, what emergency treatment should I apply?"*
3. Tap **"Ask"**
4. ✅ **Expected**: Answer screen shows **"Cloud AI"** (green chip), HIGH confidence badge, with Dr. expert name and elaborated treatment plan

> **What to show**: Complex/low-confidence queries escalate to cloud, returning richer expert-verified answers.

---

### Step 3 — Go Offline and Queue a Query

1. Toggle **"Go Offline (Demo)"** ON
2. Type a very unusual query: *"My jute field has a strange purple fungal growth near the roots that I've never seen before"*
3. Tap **"Ask"**
4. ✅ **Expected**: Answer screen shows **"Queued"** (orange), status tracker shows "Queued" state, and a follow-up question appears asking for more details

5. Tap **"Queue"** tab in bottom nav → see the queued query listed

> **What to show**: The app gracefully handles no-connectivity by queuing and asking clarifying questions.

---

### Step 4 — Sync and Receive Expert Answer

1. While on the Queue screen, toggle offline mode **OFF** (go online)
2. Tap **"Simulate Sync (Demo)"** button
3. Watch the sync status update: "Syncing..." → "Sending 1 queries..." → "Synced at HH:MM"
4. ✅ **Expected**: The queued query card updates to **"Answered by Expert"** (green), and an expert answer from "Dr. Priya Sharma, KVK Nadia" appears

5. Tap the query to open it → see the full expert answer with verified-by details

> **What to show**: The complete query lifecycle — queue → sync → expert answer delivery.

---

### Step 5 — Photo Diagnosis

1. Tap **"Diagnose"** in the bottom nav
2. Tap **"Take Photo"** (or "Choose from Gallery" for demo)
3. Select or capture a photo of a plant leaf
4. Tap **"Diagnose Crop"**
5. Wait 2 seconds for "Analyzing crop image..."
6. ✅ **Expected**: Result shows disease name (e.g., "Blast Disease"), crop detected, confidence score with color bar, treatment recommendation, ICAR source
   - If confidence < 0.5: Shows "Low Confidence — Escalating to Expert" with retake option

> **What to show**: Photo-based diagnosis with confidence scoring and expert escalation path.

---

## 🤖 On-Device LLM Integration

The `OnDeviceLLM` interface in [`lib/services/on_device_llm_service.dart`](lib/services/on_device_llm_service.dart) is designed for Gemma-class model integration.

### To plug in real Gemma 2B:

```dart
// 1. Add to pubspec.yaml:
//    llama_cpp_dart: ^x.x.x  (or flutter_gemma, mediapipe_genai)

// 2. Create GemmaOnDeviceLLM:
class GemmaOnDeviceLLM implements OnDeviceLLM {
  LlamaCpp? _model;
  
  @override
  Future<void> load(String modelPath) async {
    _model = await LlamaCpp.load(modelPath);
  }
  
  @override
  Future<String> generate(String prompt, List<AnswerEntry> context) async {
    final contextText = context.map((e) => e.answerFor('en')).join('\n');
    return await _model!.generate(
      'Context:\n$contextText\n\nFarmer question: $prompt\nAnswer:',
      maxTokens: 256,
    );
  }
  
  @override
  bool isReady() => _model != null;
  
  @override
  Future<void> dispose() async => _model?.dispose();
}

// 3. In main.dart, replace:
//    final onDeviceLLM = MockOnDeviceLLM();
// With:
//    final onDeviceLLM = GemmaOnDeviceLLM();
//    await onDeviceLLM.load(MockConfig.onDeviceModelPath);
```

**Recommended model**: `gemma-2b-it-q4_k_m.gguf` (~1.5 GB) — place in device storage and set path in `MockConfig.onDeviceModelPath`.

---

## 🌐 Adding New Languages

The language layer is designed for easy expansion:

1. Create `lib/l10n/app_<code>.arb` (copy `app_en.arb`, translate all values)
2. Add to `supportedLocales` in `main.dart`:
   ```dart
   Locale('or'),  // Odia
   ```
3. Add to `AppLocales.supported` in `constants.dart`
4. Add locale-specific answer translations to `answer_bank.json`
5. Add STT locale code to `SpeechService._sttLocaleMap`
6. Run `flutter gen-l10n`

**Languages ready to add**: Odia (`or`), Tamil (`ta`), Telugu (`te`), Marathi (`mr`), Punjabi (`pa`) — template entries are in the locale maps with comments.

---

## 🌱 Seed Data

| File | Contents |
|---|---|
| `answer_bank.json` | 42 Q&As: 14 Rice, 14 Potato, 14 Jute; sources: ICAR-CRRI, ICAR-CPRI, ICAR-NIRJAFT, CRIJAF, KVK Nadia, BCKV |
| `weather_mock.json` | Nadia District weather with IMD source, 3-day forecast, farm advisory |
| `mandi_prices_mock.json` | 12 entries: Rice (Swarna, Gobindobhog), Potato (Jyoti, Chandramukhi), Jute (TD-5, JRO-524) at West Bengal mandis |
| `crop_calendar_mock.json` | 18 entries: Kharif Rice, Rabi Potato, Kharif Jute — 6 stages each |

All seed data is loaded into SQLite on first launch. Subsequent syncs refresh weather and prices from the mock cloud service.

---

## 📞 Support

- **ICAR Helpline**: 1800-180-1551 (Toll-free)
- **KVK Network**: [icar.gov.in/kvk](https://icar.gov.in/kvk)
- **Agmarknet**: [agmarknet.gov.in](https://agmarknet.gov.in)

---

*Built for hackathon demonstration. All external service calls are mocked. The app architecture is production-ready for real API integration.*
