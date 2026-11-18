import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../providers/app_provider.dart';
import 'home_screen.dart';

/// DPDP Act (Digital Personal Data Protection) compliant consent screen.
/// Presented on first launch with large icons, multi-language support,
/// and clear explanations tailored for low-literacy farmers.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _hasAgreed = false;
  bool _isSaving = false;

  // Multi-lingual consent copy
  final Map<String, Map<String, dynamic>> _localizedContent = {
    'en': {
      'title': 'Agri Mitra',
      'subtitle': 'Your AI Farming Companion (Online + Offline)',
      'bullet1_title': 'Voice & Photo Advisory',
      'bullet1_desc': 'Your voice queries and crop photos are used strictly to provide pest, crop, and disease diagnosis.',
      'bullet2_title': 'Location & Offline Storage',
      'bullet2_desc': 'Mandi prices and local weather forecasts are cached securely on your phone for offline use.',
      'bullet3_title': 'Privacy & DPDP Compliance',
      'bullet3_desc': 'Your personal details are protected under India\'s DPDP Act 2023. We never sell or share your data.',
      'checkbox': 'I agree to data usage for agricultural advisory',
      'button': 'Agree & Continue',
      'privacy_link': 'Read Full Privacy Policy (DPDP Act)',
      'policy_title': 'Privacy Policy & Data Notice',
      'policy_body': '''Agri Mitra operates under strict adherence to the Digital Personal Data Protection Act (DPDP), 2023.

1. Purpose of Data:
- Crop photos are analyzed by on-device and secure cloud agronomy AI.
- Voice recordings are transcribed locally or securely in cloud for query resolution.
- Geo-location is used strictly to fetch relevant APMC mandi rates and IMD block weather.

2. Data Storage & Retention:
- Offline data remains stored in your device's encrypted SQLite database.
- You may clear cached queries and photo history at any time from Settings.

3. Your Rights:
- Right to access, rectify, and withdraw consent at any time.
- For grievances, contact Kisan Call Centre at 1800-180-1551.''',
    },
    'hi': {
      'title': 'कृषि सलाहकार',
      'subtitle': 'आपका अपना डिजिटल खेती साथी (ऑनलाइन + ऑफलाइन)',
      'bullet1_title': 'आवाज और फसल फोटो सलाह',
      'bullet1_desc': 'आपकी आवाज और फसल की फोटो का उपयोग केवल रोग निदान और फसल सलाह के लिए किया जाता है।',
      'bullet2_title': 'स्थान और ऑफलाइन डेटा',
      'bullet2_desc': 'मंडी भाव और मौसम की जानकारी आपके फोन पर सुरक्षित रहती है ताकि बिना इंटरनेट भी दिखे।',
      'bullet3_title': 'गोपनीयता और डेटा सुरक्षा',
      'bullet3_desc': 'आपका डेटा डीपीडीपी कानून 2023 के तहत सुरक्षित है। जानकारी किसी के साथ साझा नहीं की जाती।',
      'checkbox': 'मैं कृषि सलाह के लिए डेटा उपयोग की सहमति देता हूँ',
      'button': 'स्वीकार करें और आगे बढ़ें',
      'privacy_link': 'पूरी गोपनीयता नीति पढ़ें (DPDP कानून)',
      'policy_title': 'गोपनीयता नीति एवं डेटा सुरक्षा',
      'policy_body': '''कृषि सलाहकार डिजिटल व्यक्तिगत डेटा संरक्षण अधिनियम (DPDP) 2023 का पूर्ण पालन करता है।

१. डेटा का उपयोग:
- केवल फसल सुरक्षा, मौसम और मंडी भाव की जानकारी के लिए।
- आपकी व्यक्तिगत जानकारी कभी बेची या साझा नहीं की जाती।

२. ऑफलाइन सुरक्षा:
- आपका डेटा आपके मोबाइल में ही सुरक्षित रहता है।

३. सहायता:
- किसी भी प्रश्न के लिए किसान कॉल सेंटर 1800-180-1551 पर संपर्क करें।''',
    },
    'bn': {
      'title': 'কৃষি উপদেষ্টা',
      'subtitle': 'আপনার ডিজিটাল কৃষি সহায়ক (অনলাইন + অফলাইন)',
      'bullet1_title': 'কণ্ঠ ও ফসলের ছবি পরামর্শ',
      'bullet1_desc': 'আপনার ভয়েস এবং ফসলের ছবি শুধুমাত্র রোগ নির্ণয় ও কৃষি পরামর্শের জন্য ব্যবহার করা হয়।',
      'bullet2_title': 'লোকেশন ও অফলাইন তথ্য',
      'bullet2_desc': 'মান্ডির দর এবং আবহাওয়ার তথ্য ইন্টারনেট ছাড়াই দেখার জন্য ফোনে সংরক্ষিত থাকে।',
      'bullet3_title': 'গোপনীয়তা ও ডেটা সুরক্ষা',
      'bullet3_desc': 'আপনার তথ্য ভারতের ডিপিডিপি আইন ২০২৩ অনুযায়ী সম্পূর্ণ সুরক্ষিত ও নিরাপদ।',
      'checkbox': 'আমি কৃষি পরামর্শের জন্য ডেটা ব্যবহারে সম্মতি দিচ্ছি',
      'button': 'সম্মত হয়ে এগিয়ে যান',
      'privacy_link': 'সম্পূর্ণ গোপনীয়তা নীতি পড়ুন',
      'policy_title': 'গোপনীয়তা নীতি ও শর্তাবলী',
      'policy_body': '''কৃষি উপদেষ্টা ডিজিটাল ব্যক্তিগত ডেটা সুরক্ষা আইন (DPDP) ২০২৩ সম্পূর্ণরূপে মেনে চলে।

১. তথ্যের উদ্দেশ্য: ফসলের রোগবালাই নিরাময় ও সঠিক পরামর্শ প্রদান।
২. অফলাইন স্টোরেজ: তথ্য আপনার ফোনেই সুরক্ষিত থাকে।
৩. কিষাণ কল সেন্টার: ১৮০০-১৮০-১৫৫১।''',
    },
  };

  Future<void> _handleAgree(AppProvider provider) async {
    if (!_hasAgreed || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      // Store consent in key 'consent_given' as requested in specifications
      await prefs.setBool('consent_given', true);
      await prefs.setBool(AppConstants.prefConsentKey, true);

      // Notify AppProvider
      await provider.setConsent(true);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving consent: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showPrivacyPolicyDialog(BuildContext context, Map<String, dynamic> content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.shield_rounded, color: Color(0xFF2E7D32), size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                content['policy_title'] as String,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            content['policy_body'] as String,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final currentLang = provider.locale;
        final content = _localizedContent[currentLang] ?? _localizedContent['en']!;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Language Selector Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.language_rounded, size: 18, color: Color(0xFF2E7D32)),
                            SizedBox(width: 6),
                            Text(
                              'Language / भाषा',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownButton<String>(
                        value: currentLang,
                        underline: const SizedBox.shrink(),
                        icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF2E7D32)),
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English (EN)', style: TextStyle(fontWeight: FontWeight.w600))),
                          DropdownMenuItem(value: 'hi', child: Text('हिन्दी (HI)', style: TextStyle(fontWeight: FontWeight.w600))),
                          DropdownMenuItem(value: 'bn', child: Text('বাংলা (BN)', style: TextStyle(fontWeight: FontWeight.w600))),
                        ],
                        onChanged: (lang) {
                          if (lang != null) provider.setLocale(lang);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // App Logo
                  Center(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF2E7D32), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E7D32).withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.agriculture,
                          size: 80,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    content['title'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B5E20),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle
                  Text(
                    content['subtitle'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // DPDP Consent Cards
                  _buildConsentBullet(
                    icon: Icons.mic_rounded,
                    title: content['bullet1_title'] as String,
                    desc: content['bullet1_desc'] as String,
                  ),
                  const SizedBox(height: 14),
                  _buildConsentBullet(
                    icon: Icons.cloud_off_rounded,
                    title: content['bullet2_title'] as String,
                    desc: content['bullet2_desc'] as String,
                  ),
                  const SizedBox(height: 14),
                  _buildConsentBullet(
                    icon: Icons.security_rounded,
                    title: content['bullet3_title'] as String,
                    desc: content['bullet3_desc'] as String,
                  ),
                  const SizedBox(height: 28),

                  // Checkbox Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _hasAgreed ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _hasAgreed ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                        width: 1.8,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() => _hasAgreed = !_hasAgreed);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _hasAgreed,
                            activeColor: const Color(0xFF2E7D32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            onChanged: (val) {
                              setState(() => _hasAgreed = val ?? false);
                            },
                          ),
                          Expanded(
                            child: Text(
                              content['checkbox'] as String,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: _hasAgreed ? const Color(0xFF1B5E20) : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Agree & Continue Button (Disabled until checked)
                  SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _hasAgreed && !_isSaving ? () => _handleAgree(provider) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        disabledBackgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.grey.shade600,
                        elevation: _hasAgreed ? 4 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  content['button'] as String,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.arrow_forward_rounded, size: 24),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Privacy Policy Link
                  Center(
                    child: TextButton(
                      onPressed: () => _showPrivacyPolicyDialog(context, content),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.policy_outlined, size: 18, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 6),
                          Text(
                            content['privacy_link'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E7D32),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConsentBullet({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: const Color(0xFF2E7D32)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
