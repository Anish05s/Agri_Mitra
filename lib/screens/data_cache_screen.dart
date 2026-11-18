import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/crop_calendar.dart';
import '../models/mandi_price.dart';
import '../models/weather_cache.dart';
import '../providers/app_provider.dart';
import '../widgets/answer_source_card.dart';

/// Offline Data Cache Screen presenting cached Weather, Mandi Prices,
/// and Crop Calendar datasets available without active network connection.
///
/// Features:
/// - 3 Tab views: Weather | Mandi Prices | Crop Calendar
/// - High-contrast metrics and icons for quick comprehension
/// - Expandable tiles for calendar stages
/// - Refresh Floating Action Button with sync feedback
class DataCacheScreen extends StatefulWidget {
  const DataCacheScreen({super.key});

  @override
  State<DataCacheScreen> createState() => _DataCacheScreenState();
}

class _DataCacheScreenState extends State<DataCacheScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7FAF7),
          appBar: AppBar(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            elevation: 2,
            title: const Text(
              'Offline Data Cache',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFF9A825),
              indicatorWeight: 4,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(icon: Icon(Icons.cloud_outlined), text: 'Weather'),
                Tab(icon: Icon(Icons.currency_rupee_rounded), text: 'Mandi Prices'),
                Tab(icon: Icon(Icons.calendar_month_rounded), text: 'Crop Calendar'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildWeatherTab(context, provider),
              _buildMandiPricesTab(context, provider),
              _buildCropCalendarTab(context, provider),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            icon: provider.isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Icon(Icons.refresh_rounded),
            label: Text(
              provider.isSyncing ? 'Syncing...' : 'Sync Cache',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: provider.isSyncing
                ? null
                : () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Updating weather, mandi prices & calendar...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                    await provider.refreshWeatherAndPrices();
                  },
          ),
        );
      },
    );
  }

  // ================= TAB 1: WEATHER =================
  Widget _buildWeatherTab(BuildContext context, AppProvider provider) {
    final weather = provider.weather;

    if (weather == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Loading weather cache...'),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
              onPressed: () => provider.refreshWeatherAndPrices(),
              child: const Text('Fetch Weather', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main Weather Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location row
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFFF9A825), size: 22),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        weather.location,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Large Temperature and Condition Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${weather.tempCelsius.toStringAsFixed(1)}°C',
                          style: const TextStyle(
                            fontSize: 54,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          weather.condition,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFFF9C4),
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.wb_sunny_rounded,
                      size: 74,
                      color: Color(0xFFF9A825),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Weather Metrics Grid (Humidity, Wind, Rainfall)
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.water_drop_rounded,
                  label: 'Humidity',
                  value: '${weather.humidity}%',
                  color: Colors.blue.shade700,
                  bgColor: Colors.blue.shade50,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.air_rounded,
                  label: 'Wind Speed',
                  value: '${weather.windKmh} km/h',
                  color: Colors.teal.shade700,
                  bgColor: Colors.teal.shade50,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.grain_rounded,
                  label: 'Rainfall',
                  value: weather.rainfall,
                  color: Colors.indigo.shade700,
                  bgColor: Colors.indigo.shade50,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Agricultural Impact Advisory
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.eco_rounded, color: Color(0xFF2E7D32), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Farmer Advisory for Weather',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Favorable weather for field preparation and fertilizer broadcasting. Sowing and herbicide application recommended in the clear morning window.',
                  style: TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF37474F)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Source and Sync info
          AnswerSourceCard(
            source: weather.source,
            lastUpdated: DateFormat('dd MMM yyyy').format(weather.fetchedAt),
            lastSynced: DateFormat('dd MMM yyyy, hh:mm a').format(weather.lastSyncedAt),
            isOffline: true,
          ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAB 2: MANDI PRICES =================
  Widget _buildMandiPricesTab(BuildContext context, AppProvider provider) {
    final prices = provider.mandiPrices;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header description
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD54F)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFFE65100), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Daily APMC rates from Agmarknet. Green highlight indicates modal price is good / trending high.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF5D4037), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (prices.isEmpty)
            Container(
              padding: const EdgeInsets.all(30),
              alignment: Alignment.center,
              child: const Text('No mandi price data cached yet.'),
            )
          else
            // Mandi Price Cards List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: prices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) {
                final item = prices[index];
                final isGoodPrice = item.modalPrice >= (item.minPrice * 1.05);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isGoodPrice ? const Color(0xFF81C784) : Colors.grey.shade300,
                      width: isGoodPrice ? 1.8 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Crop name & Mandi
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.crop} (${item.variety})',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF212121),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.storefront_rounded, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.market,
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Good Price Tag
                          if (isGoodPrice)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF2E7D32)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.trending_up, size: 14, color: Color(0xFF2E7D32)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Good Rate',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B5E20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const Divider(height: 18, thickness: 1, color: Color(0xFFEEEEEE)),

                      // Min / Modal / Max Price Grid
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildPriceColumn('Min Price', '₹${item.minPrice.toInt()}', Colors.grey.shade700),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isGoodPrice ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isGoodPrice ? const Color(0xFF2E7D32) : const Color(0xFFFFA000),
                              ),
                            ),
                            child: _buildPriceColumn(
                              'Modal Price',
                              '₹${item.modalPrice.toInt()}',
                              isGoodPrice ? const Color(0xFF1B5E20) : const Color(0xFFE65100),
                              isBold: true,
                            ),
                          ),
                          _buildPriceColumn('Max Price', '₹${item.maxPrice.toInt()}', Colors.grey.shade700),
                        ],
                      ),

                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            'Unit: ${item.unit} • ${DateFormat("dd MMM").format(item.date)}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          const Spacer(),
                          Text(
                            'Source: ${item.source}',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildPriceColumn(String label, String value, Color color, {bool isBold = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 15,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  // ================= TAB 3: CROP CALENDAR =================
  Widget _buildCropCalendarTab(BuildContext context, AppProvider provider) {
    final calendar = provider.cropCalendar;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: const Row(
              children: [
                Icon(Icons.event_note_rounded, color: Color(0xFF2E7D32), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'State Agricultural University Regional Advisory Schedule',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          if (calendar.isEmpty)
            Container(
              padding: const EdgeInsets.all(30),
              alignment: Alignment.center,
              child: const Text('No crop calendar data cached yet.'),
            )
          else
            // Expandable Calendar Tiles
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: calendar.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) {
                final item = calendar[index];
                final localizedAdvice = item.getLocalizedAdvice(provider.locale);

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: ExpansionTile(
                      initiallyExpanded: index == 0,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE8F5E9),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        item.crop,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            'Stage: ${item.stage}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF424242)),
                          ),
                          Text(
                            'Months: ${item.months}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              const Text(
                                'Advisory Guidance:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                localizedAdvice,
                                style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF212121)),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Source: ${item.source}',
                                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }
}
