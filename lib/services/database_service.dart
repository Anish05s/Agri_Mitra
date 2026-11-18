import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../core/constants.dart';
import '../models/answer_entry.dart';
import '../models/crop_calendar.dart';
import '../models/mandi_price.dart';
import '../models/query_model.dart';
import '../models/weather_cache.dart';

/// Database service using SQLite (sqflite) for offline storage.
/// Manages verified answer bank, query queue, weather cache, mandi prices,
/// and crop calendar.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  // In-memory answer bank used on web (no SQLite available without service workers)
  List<AnswerEntry> _inMemoryAnswers = [];
  List<QueryModel> _inMemoryQueue = [];
  WeatherCache? _inMemoryWeather;
  List<MandiPrice> _inMemoryMandi = [];
  List<CropCalendarEntry> _inMemoryCalendar = [];
  bool _isWebMode = false;

  /// Returns active SQLite database instance, initializing if needed.
  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await initDatabase();
    return _db!;
  }

  /// Initializes an in-memory data store from JSON assets for web/Chrome.
  /// No SQLite service workers required. Data resets on page refresh.
  Future<void> initInMemory() async {
    _isWebMode = true;
    try {
      // Load answer bank
      final jsonStr = await rootBundle.loadString('assets/data/answer_bank.json');
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        _inMemoryAnswers = decoded
            .map((e) => AnswerEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      // Load weather
      final wJson = await rootBundle.loadString('assets/data/weather_mock.json');
      _inMemoryWeather = WeatherCache.fromJson(jsonDecode(wJson));
      // Load mandi prices
      final mJson = await rootBundle.loadString('assets/data/mandi_prices_mock.json');
      final mDecoded = jsonDecode(mJson);
      if (mDecoded is List) {
        _inMemoryMandi = mDecoded
            .map((e) => MandiPrice.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      // Load crop calendar
      final cJson = await rootBundle.loadString('assets/data/crop_calendar_mock.json');
      final cDecoded = jsonDecode(cJson);
      if (cDecoded is List) {
        _inMemoryCalendar = cDecoded
            .map((e) => CropCalendarEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('initInMemory error: $e');
    }
  }

  /// Initializes database, creates tables, and performs first-run data seeding.
  Future<Database> initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, AppConstants.databaseName);

    final db = await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
    );

    _db = db;
    await _checkAndSeedData(db);
    return db;
  }

  /// Creates all required database tables.
  Future<void> _onCreate(Database db, int version) async {
    // 1. Answer Bank Table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableAnswerBank} (
        id TEXT PRIMARY KEY,
        crop TEXT NOT NULL,
        category TEXT NOT NULL,
        keywords TEXT NOT NULL,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        source TEXT NOT NULL,
        verified_by TEXT NOT NULL,
        last_updated TEXT NOT NULL,
        confidence REAL NOT NULL
      )
    ''');

    // 2. Query Queue Table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableQueryQueue} (
        id TEXT PRIMARY KEY,
        query_text TEXT NOT NULL,
        locale TEXT NOT NULL,
        created_at TEXT NOT NULL,
        status TEXT NOT NULL,
        path TEXT,
        answer_text TEXT,
        source TEXT,
        verified_by TEXT,
        last_updated TEXT,
        confidence REAL,
        is_high_confidence INTEGER NOT NULL DEFAULT 0,
        expert_answer TEXT,
        last_synced_at TEXT
      )
    ''');

    // 3. Weather Cache Table (single row id=1)
    await db.execute('''
      CREATE TABLE ${AppConstants.tableWeatherCache} (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        location TEXT NOT NULL,
        temp_celsius REAL NOT NULL,
        condition TEXT NOT NULL,
        humidity INTEGER NOT NULL,
        wind_kmh REAL NOT NULL,
        rainfall TEXT NOT NULL,
        source TEXT NOT NULL,
        fetched_at TEXT NOT NULL,
        last_synced_at TEXT NOT NULL
      )
    ''');

    // 4. Mandi Prices Table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableMandiPrices} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        crop TEXT NOT NULL,
        variety TEXT NOT NULL,
        market TEXT NOT NULL,
        min_price REAL NOT NULL,
        max_price REAL NOT NULL,
        modal_price REAL NOT NULL,
        unit TEXT NOT NULL,
        date TEXT NOT NULL,
        source TEXT NOT NULL,
        last_synced_at TEXT NOT NULL
      )
    ''');

    // 5. Crop Calendar Table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableCropCalendar} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        crop TEXT NOT NULL,
        stage TEXT NOT NULL,
        months TEXT NOT NULL,
        advice TEXT NOT NULL,
        advice_locale TEXT NOT NULL,
        source TEXT NOT NULL,
        last_synced_at TEXT NOT NULL
      )
    ''');
  }

  /// Checks if tables are empty and seeds initial verified agronomic data.
  Future<void> _checkAndSeedData(Database db) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${AppConstants.tableAnswerBank}'),
    );

    if (count == null || count == 0) {
      List<AnswerEntry> entries = [];
      try {
        final jsonString = await rootBundle.loadString('assets/data/answer_bank.json');
        final dynamic decoded = jsonDecode(jsonString);
        if (decoded is List) {
          entries = decoded.map((e) => AnswerEntry.fromJson(e as Map<String, dynamic>)).toList();
        }
      } catch (_) {
        // Fall back to robust built-in verified agronomic seed data
        entries = _getBuiltInSeedAnswers();
      }

      if (entries.isNotEmpty) {
        await seedAnswerBank(entries);
      }

      // Seed initial weather cache if missing
      final weatherCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${AppConstants.tableWeatherCache}'),
      );
      if (weatherCount == null || weatherCount == 0) {
        await cacheWeather(WeatherCache(
          location: 'Hooghly & Murshidabad, West Bengal',
          tempCelsius: 29.5,
          condition: 'Partly Cloudy',
          humidity: 78,
          windKmh: 11.2,
          rainfall: '14mm expected next 48h',
          source: 'IMD Agro-Advisory',
          fetchedAt: DateTime.now(),
          lastSyncedAt: DateTime.now(),
        ));
      }

      // Seed initial mandi prices if missing
      final mandiCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${AppConstants.tableMandiPrices}'),
      );
      if (mandiCount == null || mandiCount == 0) {
        await cacheMandiPrices(_getBuiltInMandiPrices());
      }

      // Seed initial crop calendar if missing
      final calCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${AppConstants.tableCropCalendar}'),
      );
      if (calCount == null || calCount == 0) {
        await cacheCropCalendar(_getBuiltInCropCalendar());
      }
    }
  }

  // --------------------------------------------------------------------------
  // Answer Bank Operations
  // --------------------------------------------------------------------------

  /// Seeds answer bank entries in a fast batch transaction.
  Future<void> seedAnswerBank(List<AnswerEntry> answers) async {
    final db = await database;
    final batch = db.batch();
    for (final entry in answers) {
      batch.insert(
        AppConstants.tableAnswerBank,
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Searches the local answer bank using keyword matching.
  /// Evaluates query tokens against keywords, crop names, categories, and localized questions.
  Future<List<AnswerEntry>> searchAnswers(String query, String locale) async {
    // Web mode: search the in-memory list directly
    final List<AnswerEntry> allEntries;
    if (_isWebMode) {
      allEntries = _inMemoryAnswers;
    } else {
      final rows = await (await database).query(AppConstants.tableAnswerBank);
      allEntries = rows.map((r) => AnswerEntry.fromMap(r)).toList();
    }

    final queryClean = query.trim().toLowerCase();
    if (queryClean.isEmpty) return allEntries;

    final queryWords = queryClean
        .replaceAll(RegExp(r'[^\w\s\u0900-\u097F\u0980-\u09FF]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toSet();

    if (queryWords.isEmpty) return allEntries;

    // Score entries based on keyword and content matches
    final scoredEntries = <_ScoredEntry>[];

    for (final entry in allEntries) {
      double score = 0.0;
      int matchedKeywords = 0;

      final entryKeywords = entry.keywords.map((k) => k.toLowerCase()).toSet();
      final cropLower = entry.crop.toLowerCase();
      final catLower = entry.category.toLowerCase();
      final localizedQ = entry.getLocalizedQuestion(locale).toLowerCase();

      for (final word in queryWords) {
        if (entryKeywords.contains(word)) {
          matchedKeywords++;
          score += 0.35;
        } else if (entryKeywords.any((k) => k.contains(word) || word.contains(k))) {
          matchedKeywords++;
          score += 0.20;
        }

        if (cropLower.contains(word) || word.contains(cropLower)) {
          score += 0.30;
        }
        if (catLower.contains(word) || word.contains(catLower)) {
          score += 0.15;
        }
        if (localizedQ.contains(word)) {
          score += 0.20;
        }
      }

      if (matchedKeywords > 0 || score > 0.3) {
        final normalizedScore = (score / (queryWords.length * 0.6 + 0.4)).clamp(0.0, 1.0);
        scoredEntries.add(_ScoredEntry(entry: entry, score: normalizedScore));
      }
    }

    scoredEntries.sort((a, b) => b.score.compareTo(a.score));
    return scoredEntries.map((e) => e.entry).toList();
  }

  /// Returns all answer bank entries.
  Future<List<AnswerEntry>> getAllAnswers() async {
    if (_isWebMode) return List.from(_inMemoryAnswers);
    final db = await database;
    final rows = await db.query(AppConstants.tableAnswerBank);
    return rows.map((r) => AnswerEntry.fromMap(r)).toList();
  }

  // --------------------------------------------------------------------------
  // Query Queue Operations
  // --------------------------------------------------------------------------

  /// Inserts a query into the local query queue.
  Future<void> insertQuery(QueryModel query) async {
    if (_isWebMode) { _inMemoryQueue.add(query); return; }
    final db = await database;
    await db.insert(AppConstants.tableQueryQueue, query.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Updates an existing query in the query queue.
  Future<void> updateQuery(QueryModel query) async {
    if (_isWebMode) {
      final i = _inMemoryQueue.indexWhere((q) => q.id == query.id);
      if (i >= 0) _inMemoryQueue[i] = query;
      return;
    }
    final db = await database;
    await db.update(AppConstants.tableQueryQueue, query.toMap(),
        where: 'id = ?', whereArgs: [query.id]);
  }

  /// Retrieves queries that are queued or pending expert response.
  Future<List<QueryModel>> getPendingQueries() async {
    if (_isWebMode) {
      return _inMemoryQueue
          .where((q) =>
              q.status == QueryStatus.queued ||
              q.status == QueryStatus.sent ||
              q.path == RoutingPath.queued)
          .toList();
    }
    final db = await database;
    final rows = await db.query(AppConstants.tableQueryQueue,
        where: 'status = ? OR status = ? OR path = ?',
        whereArgs: [QueryStatus.queued.name, QueryStatus.sent.name, RoutingPath.queued.name],
        orderBy: 'created_at ASC');
    return rows.map((r) => QueryModel.fromMap(r)).toList();
  }

  /// Retrieves all historical queries.
  Future<List<QueryModel>> getAllQueries() async {
    if (_isWebMode) return List.from(_inMemoryQueue.reversed);
    final db = await database;
    final rows = await db.query(AppConstants.tableQueryQueue,
        orderBy: 'created_at DESC');
    return rows.map((r) => QueryModel.fromMap(r)).toList();
  }

  /// Deletes a query by ID.
  Future<int> deleteQuery(String id) async {
    if (_isWebMode) {
      final before = _inMemoryQueue.length;
      _inMemoryQueue.removeWhere((q) => q.id == id);
      return before - _inMemoryQueue.length;
    }
    final db = await database;
    return await db.delete(AppConstants.tableQueryQueue,
        where: 'id = ?', whereArgs: [id]);
  }

  // --------------------------------------------------------------------------
  // Weather Cache Operations
  // --------------------------------------------------------------------------

  /// Caches the latest weather data.
  Future<void> cacheWeather(WeatherCache weather) async {
    if (_isWebMode) { _inMemoryWeather = weather; return; }
    final db = await database;
    await db.insert(AppConstants.tableWeatherCache, weather.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Retrieves the latest cached weather data.
  Future<WeatherCache?> getWeather() async {
    if (_isWebMode) return _inMemoryWeather;
    final db = await database;
    final rows = await db.query(AppConstants.tableWeatherCache,
        where: 'id = 1', limit: 1);
    if (rows.isEmpty) return null;
    return WeatherCache.fromMap(rows.first);
  }

  // --------------------------------------------------------------------------
  // Mandi Prices Operations
  // --------------------------------------------------------------------------

  /// Caches fresh mandi prices.
  Future<void> cacheMandiPrices(List<MandiPrice> prices) async {
    if (_isWebMode) { _inMemoryMandi = prices; return; }
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(AppConstants.tableMandiPrices);
      final batch = txn.batch();
      for (final p in prices) { batch.insert(AppConstants.tableMandiPrices, p.toMap()); }
      await batch.commit(noResult: true);
    });
  }

  /// Retrieves all cached mandi prices.
  Future<List<MandiPrice>> getMandiPrices() async {
    if (_isWebMode) return _inMemoryMandi;
    final db = await database;
    final rows = await db.query(AppConstants.tableMandiPrices,
        orderBy: 'crop ASC, market ASC');
    return rows.map((r) => MandiPrice.fromMap(r)).toList();
  }

  // --------------------------------------------------------------------------
  // Crop Calendar Operations
  // --------------------------------------------------------------------------

  /// Saves fresh crop calendar entries.
  Future<void> cacheCropCalendar(List<CropCalendarEntry> entries) async {
    if (_isWebMode) { _inMemoryCalendar = entries; return; }
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(AppConstants.tableCropCalendar);
      final batch = txn.batch();
      for (final c in entries) { batch.insert(AppConstants.tableCropCalendar, c.toMap()); }
      await batch.commit(noResult: true);
    });
  }

  /// Retrieves all cached crop calendar entries.
  Future<List<CropCalendarEntry>> getCropCalendar() async {
    if (_isWebMode) return _inMemoryCalendar;
    final db = await database;
    final rows = await db.query(AppConstants.tableCropCalendar,
        orderBy: 'crop ASC, stage ASC');
    return rows.map((r) => CropCalendarEntry.fromMap(r)).toList();
  }

  /// Clears all tables.
  Future<void> clearAllData() async {
    if (_isWebMode) {
      _inMemoryAnswers.clear(); _inMemoryQueue.clear();
      _inMemoryWeather = null; _inMemoryMandi.clear(); _inMemoryCalendar.clear();
      return;
    }
    final db = await database;
    await db.delete(AppConstants.tableAnswerBank);
    await db.delete(AppConstants.tableQueryQueue);
    await db.delete(AppConstants.tableWeatherCache);
    await db.delete(AppConstants.tableMandiPrices);
    await db.delete(AppConstants.tableCropCalendar);
  }

  /// Closes database connection.
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }

  // --------------------------------------------------------------------------
  // Built-in Seed Data Fallbacks
  // --------------------------------------------------------------------------

  static List<AnswerEntry> _getBuiltInSeedAnswers() {
    return [
      const AnswerEntry(
        id: 'ans_rice_blast_01',
        crop: 'rice',
        category: 'disease',
        keywords: ['rice', 'blast', 'paddy', 'leaf', 'spindle', 'spots', 'fungus', 'jhulsa'],
        question: {
          'en': 'How do I control Blast disease in paddy/rice?',
          'hi': 'धान में झुलसा (ब्लास्ट) रोग का नियंत्रण कैसे करें?',
          'bn': 'ধানে ব্লাস্ট রোগ কীভাবে নিয়ন্ত্রণ করব?',
        },
        answer: {
          'en': 'Rice Blast shows spindle-shaped brown lesions. Spray Tricyclazole 75% WP @ 0.6g per litre of water or Kasugamycin 3% SL @ 2.5ml/L at early symptom appearance. Avoid excessive nitrogen fertilizer.',
          'hi': 'धान के झुलसा रोग में नाव के आकार के धब्बे बनते हैं। ट्राइसाइक्लाजोल 75% डब्लूपी 0.6 ग्राम प्रति लीटर पानी में मिलाकर छिड़काव करें। यूरिया का अत्यधिक उपयोग न करें।',
          'bn': 'ধানের ব্লাস্ট রোগে নৌকার মতো বাদামী দাগ দেখা যায়। প্রতি লিটার জলে ট্রাইসাইক্লাজোল ৭৫% ডব্লিউপি ০.৬ গ্রাম বা কাসুগামাইসিন ২.৫ মিলি গুলে স্প্রে করুন। অতিরিক্ত ইউরিয়া দেবেন না।',
        },
        source: 'ICAR-CRRI Cuttack',
        verifiedBy: 'Dr. S. K. Nayak, Principal Scientist (Plant Pathology)',
        lastUpdated: '2024-09-20',
        confidence: 0.94,
      ),
      const AnswerEntry(
        id: 'ans_rice_stem_borer_02',
        crop: 'rice',
        category: 'pest',
        keywords: ['rice', 'paddy', 'stem borer', 'dead heart', 'white earhead', 'keeda', 'majra'],
        question: {
          'en': 'How to control yellow stem borer in rice?',
          'hi': 'धान में तना छेदक (तना छेदक कीट) को कैसे रोकें?',
          'bn': 'ধানের মাজরা পোকা কীভাবে দমন করব?',
        },
        answer: {
          'en': 'For stem borer (causing dead heart at vegetative stage and white earhead at panicle stage), apply Chlorantraniliprole 0.4% G @ 4kg/acre or spray Cartap Hydrochloride 50% SP @ 2g/litre of water. Install pheromone traps @ 8 traps/acre.',
          'hi': 'धान में तना छेदक के लिए क्लोरेंट्रानिलिप्रोल 0.4% जी 4 किग्रा प्रति एकड़ डालें या कार्टाप हाइड्रोक्लोराइड 50% एसपी 2 ग्राम प्रति लीटर पानी में छिड़कें। फेरोमोन ट्रैप लगाएं।',
          'bn': 'ধানের মাজরা পোকা দমনে ক্লোরানট্রানিলিপ্রোল ০.৪% জি ৪ কেজি প্রতি একরে প্রয়োগ করুন অথবা কার্টাপ হাইড্রোক্লোরাইড ৫০% এসপি ২ গ্রাম প্রতি লিটার জলে স্প্রে করুন। ফেরোমোন ফাঁদ লাগান।',
        },
        source: 'KVK Murshidabad & ICAR-CRRI',
        verifiedBy: 'Dr. Amitav Ghosh, SMS Entomology',
        lastUpdated: '2024-10-01',
        confidence: 0.92,
      ),
      const AnswerEntry(
        id: 'ans_potato_late_blight_03',
        crop: 'potato',
        category: 'disease',
        keywords: ['potato', 'late blight', 'blight', 'water soaked', 'black leaves', 'aaloo', 'jhulsa'],
        question: {
          'en': 'How to treat Late Blight disease in potatoes?',
          'hi': 'आलू में पछेती झुलसा (लेट ब्लाइट) रोग का इलाज कैसे करें?',
          'bn': 'আলুর নাভি ধসা (লেট ব্লাইট) রোগের প্রতিকার কী?',
        },
        answer: {
          'en': 'Late Blight appears with water-soaked dark lesions and white fungal growth on undersides in humid, cool weather. Preventive: Spray Mancozeb 75% WP @ 2.5g/L. Curative: Spray Cymoxanil 8% + Mancozeb 64% WP @ 3g/L or Metalaxyl 8% + Mancozeb 64% @ 2.5g/L.',
          'hi': 'पछेती झुलसा के लिए मौसम नम होने पर मैंकोजेब 75% डब्लूपी 2.5 ग्राम/लीटर का छिड़काव करें। संक्रमण दिखने पर साइमोक्सानिल 8% + मैंकोजेब 64% 3 ग्राम/लीटर का छिड़काव करें।',
          'bn': 'লেট ব্লাইট বা নাভি ধসা রোগের জন্য ম্যানকোজেব ৭৫% ডব্লিউপি ২.৫ গ্রাম/লিটার জলে স্প্রে করুন। রোগ আক্রমণ করলে সাইমোক্সানিল ৮% + ম্যানকোজেব ৬৪% ৩ গ্রাম/লিটার স্প্রে করুন।',
        },
        source: 'ICAR-CPRI Shimla',
        verifiedBy: 'Dr. B. P. Singh, Director ICAR-CPRI',
        lastUpdated: '2024-10-10',
        confidence: 0.95,
      ),
      const AnswerEntry(
        id: 'ans_potato_fertilizer_04',
        crop: 'potato',
        category: 'irrigation',
        keywords: ['potato', 'fertilizer', 'npk', 'urea', 'dap', 'potash', 'aaloo', 'khad'],
        question: {
          'en': 'What is the fertilizer schedule for potato crop?',
          'hi': 'आलू की फसल में खाद और उर्वरक का सही अनुपात क्या है?',
          'bn': 'আলু চাষে সারের সঠিক মাত্রা ও প্রয়োগের নিয়ম কী?',
        },
        answer: {
          'en': 'Apply N:P:K @ 150:100:120 kg/ha. Apply all Phosphorus, Potash, and half Nitrogen at planting time as basal dose. Top-dress remaining Nitrogen during earthing up at 30-35 days after planting.',
          'hi': 'आलू के लिए प्रति हेक्टेयर एन:पी:के 150:100:120 किग्रा दें। फॉस्फोरस, पोटाश व आधी नाइट्रोजन बुवाई के समय दें। शेष नाइट्रोजन 30-35 दिन बाद मिट्टी चढ़ाते समय दें।',
          'bn': 'হেক্টর প্রতি এন:পি:কে ১৫০:১০০:১২০ কেজি প্রয়োগ করুন। সমস্ত ফসফেট ও পটাশ এবং অর্ধেক নাইট্রোজেন রোপণের সময় বেসাল হিসেবে দিন। বাকি নাইট্রোজেন ৩০-৩৫ দিনে মাটি তোলার সময় দিন।',
        },
        source: 'BCKV Kalyani',
        verifiedBy: 'Prof. R. C. Das, Agronomy Dept',
        lastUpdated: '2024-08-15',
        confidence: 0.89,
      ),
      const AnswerEntry(
        id: 'ans_jute_stem_rot_05',
        crop: 'jute',
        category: 'disease',
        keywords: ['jute', 'stem rot', 'sclerotium', 'pat', 'paat', 'gora pocha'],
        question: {
          'en': 'How do I prevent and control Stem Rot in jute?',
          'hi': 'पटसन (जूट) में तना सड़न रोग का प्रबंधन कैसे करें?',
          'bn': 'পাটের কাণ্ড পচা রোগ কীভাবে রোধ করব?',
        },
        answer: {
          'en': 'Stem rot (Macrophomina phaseolina) causes brown spots on stems and lodging. Treat seeds with Carbendazim 50% WP @ 2g/kg before sowing. If symptoms appear in standing crop, spray Carbendazim 1g/L or Mancozeb 2.5g/L water.',
          'hi': 'जूट के तना सड़न में कार्बेन्डाजिम 50% डब्लूपी 2 ग्राम/किग्रा बीज उपचार करें। खड़ी फसल में लक्षण दिखने पर कार्बेन्डाजिम 1 ग्राम प्रति लीटर पानी का छिड़काव करें। जल निकासी का ध्यान रखें।',
          'bn': 'পাটের কাণ্ড পচা রোধে কার্বেন্ডাজিম ৫০% ডব্লিউপি ২ গ্রাম প্রতি কেজি বীজে শোধন করুন। গাছে রোগ দেখা দিলে কার্বেন্ডাজিম ১ গ্রাম অথবা ম্যানকোজেব ২.৫ গ্রাম প্রতি লিটার জলে গুলে স্প্রে করুন।',
        },
        source: 'ICAR-CRIJAF Barrackpore',
        verifiedBy: 'Dr. Gouranga Kar, Director ICAR-CRIJAF',
        lastUpdated: '2024-09-05',
        confidence: 0.91,
      ),
      const AnswerEntry(
        id: 'ans_jute_retting_06',
        crop: 'jute',
        category: 'general',
        keywords: ['jute', 'retting', 'ribbon', 'criajaf sona', 'fiber', 'pat pachano'],
        question: {
          'en': 'How to improve jute fibre retting and quality?',
          'hi': 'पटसन की सड़ाई (रेट्टिंग) और रेशे की गुणवत्ता में सुधार कैसे करें?',
          'bn': 'উন্নত মানের পাট পচানোর জন্য ক্রাইজাফ সোনা কীভাবে ব্যবহার করব?',
        },
        answer: {
          'en': 'Use microbial retting formulation "CRIJAF Sona" @ 4-5 kg per bigha. It accelerates retting by 6-7 days, reduces water requirement, and improves fiber brightness and grade to TD-3/TD-4.',
          'hi': 'पटसन सड़ाई के लिए "क्राइजाफ सोना" माइक्रोबियल पाउडर का उपयोग करें। यह सड़ाई का समय 6-7 दिन कम करता है तथा रेशे की चमक व गुणवत्ता बढ़ाता है।',
          'bn': 'পাট পচানোর জন্য "ক্রাইজাফ সোনা" পাউডার বিঘা প্রতি ৪-৫ কেজি ব্যবহার করুন। এতে পাট ৬-৭ দিন আগে পচে এবং আঁশের রঙ সোনালী ও মান উন্নত (টিডি-৩/৪) হয়।',
        },
        source: 'ICAR-CRIJAF Barrackpore',
        verifiedBy: 'Dr. B. Majumdar, Head Crop Production',
        lastUpdated: '2024-09-12',
        confidence: 0.93,
      ),
    ];
  }

  static List<MandiPrice> _getBuiltInMandiPrices() {
    final now = DateTime.now();
    return [
      MandiPrice(
        crop: 'Paddy (Dhan)',
        variety: 'Swarna / Common',
        market: 'Burdwan Mandi',
        minPrice: 2180.0,
        maxPrice: 2350.0,
        modalPrice: 2280.0,
        unit: 'per quintal',
        date: now,
        source: 'Agmarknet',
        lastSyncedAt: now,
      ),
      MandiPrice(
        crop: 'Potato (Alu)',
        variety: 'Jyoti',
        market: 'Hooghly Mandi',
        minPrice: 1400.0,
        maxPrice: 1650.0,
        modalPrice: 1520.0,
        unit: 'per quintal',
        date: now,
        source: 'Agmarknet',
        lastSyncedAt: now,
      ),
      MandiPrice(
        crop: 'Potato (Alu)',
        variety: 'Chandramukhi',
        market: 'Singur Mandi',
        minPrice: 1800.0,
        maxPrice: 2100.0,
        modalPrice: 1950.0,
        unit: 'per quintal',
        date: now,
        source: 'Agmarknet',
        lastSyncedAt: now,
      ),
      MandiPrice(
        crop: 'Raw Jute (Pat)',
        variety: 'TD-5',
        market: 'Sheoraphuli Mandi',
        minPrice: 5200.0,
        maxPrice: 5650.0,
        modalPrice: 5450.0,
        unit: 'per quintal',
        date: now,
        source: 'Agmarknet',
        lastSyncedAt: now,
      ),
    ];
  }

  static List<CropCalendarEntry> _getBuiltInCropCalendar() {
    final now = DateTime.now();
    return [
      CropCalendarEntry(
        crop: 'Rice (Kharif / Aman)',
        stage: 'Transplanting & Nursery',
        months: 'June - July',
        advice: 'Transplant 21-25 days old seedlings with 2-3 seedlings per hill at 20x15cm spacing. Maintain 2-3cm water layer.',
        adviceLocale: {
          'en': 'Transplant 21-25 days old seedlings with 2-3 seedlings per hill at 20x15cm spacing. Maintain 2-3cm water layer.',
          'hi': '21-25 दिन की पौध को 2-3 पौधे प्रति थान 20x15 सेमी दूरी पर रोपें। खेत में 2-3 सेमी पानी बनाए रखें।',
          'bn': '২১-২৫ দিনের চারা গোছা প্রতি ২-৩ টি করে ২০x১৫ সেমি দূরত্বে রোপণ করুন। জমিতে ২-৩ সেমি জল ধরে রাখুন।',
        },
        source: 'ICAR-CRRI / BCKV',
        lastSyncedAt: now,
      ),
      CropCalendarEntry(
        crop: 'Potato (Rabi)',
        stage: 'Land Preparation & Sowing',
        months: 'October - November',
        advice: 'Plant well-sprouted whole tubers of 35-45g at 60x20cm spacing. Treat tubers with Mancozeb @ 2.5g/L before planting.',
        adviceLocale: {
          'en': 'Plant well-sprouted whole tubers of 35-45g at 60x20cm spacing. Treat tubers with Mancozeb @ 2.5g/L before planting.',
          'hi': '35-45 ग्राम के अंकुरित कंद 60x20 सेमी दूरी पर लगाएं। बुवाई से पूर्व मैंकोजेब 2.5 ग्राम/लीटर से बीज उपचार करें।',
          'bn': '৩৫-৪৫ গ্রাম ওজনের চোখ-বেরোনো গোটা আলু ৬০x২০ সেমি দূরত্বে লাগান। রোপণের আগে ম্যানকোজেব দিয়ে শোধন করুন।',
        },
        source: 'ICAR-CPRI / State Agri Dept',
        lastSyncedAt: now,
      ),
      CropCalendarEntry(
        crop: 'Jute (Pre-Kharif)',
        stage: 'Sowing & Weeding',
        months: 'March - May',
        advice: 'Line sow certified seed @ 5kg/ha with seed drill. Perform first wheel hoeing at 15-20 days and maintain plant-to-plant distance 5-7cm.',
        adviceLocale: {
          'en': 'Line sow certified seed @ 5kg/ha with seed drill. Perform first wheel hoeing at 15-20 days and maintain plant-to-plant distance 5-7cm.',
          'hi': 'प्रमाणित बीज 5 किग्रा प्रति हेक्टेयर कतारों में बोएं। 15-20 दिन पर पहली निराई-गुड़ाई करें।',
          'bn': 'সারিতে প্রতি হেক্টরে ৫ কেজি শোধিত বীজ বপন করুন। ১৫-২০ দিনে প্রথম নিড়ানি দিন এবং চারা ৫-৭ সেমি দূরত্বে রাখুন।',
        },
        source: 'ICAR-CRIJAF Barrackpore',
        lastSyncedAt: now,
      ),
    ];
  }
}

class _ScoredEntry {
  final AnswerEntry entry;
  final double score;
  _ScoredEntry({required this.entry, required this.score});
}
