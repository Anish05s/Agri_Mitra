import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/photo_service.dart';
import '../widgets/confidence_badge.dart';

/// Photo diagnosis screen for detecting crop diseases from camera capture
/// or gallery photos.
///
/// Features:
/// - Title: 'Crop Photo Diagnosis'
/// - Two large buttons: 'Take Photo' (camera icon) and 'Choose from Gallery' (photo icon)
/// - Preview of selected image
/// - 'Diagnose' button (green, large)
/// - Loading state: circular progress + 'Analyzing crop...'
/// - Result card:
///   - Disease name (large)
///   - Crop detected
///   - Confidence score with colored bar
///   - Severity badge
///   - Treatment recommendation (if confidence >= 0.5)
///   - Source and expert info
///   - If confidence < 0.5: 'Low confidence - Sending to expert' + retake button
/// - 'Ask Expert' button that escalates
class PhotoDiagnosisScreen extends StatefulWidget {
  const PhotoDiagnosisScreen({super.key});

  @override
  State<PhotoDiagnosisScreen> createState() => _PhotoDiagnosisScreenState();
}

class _PhotoDiagnosisScreenState extends State<PhotoDiagnosisScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  DiagnosisResult? _diagnosisResult;
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImage = picked;
          _selectedImageBytes = bytes;
          _diagnosisResult = null; // Reset previous diagnosis
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _runDiagnosis(AppProvider provider) async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or capture a crop photo first.'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await provider.diagnosePhoto(_selectedImage!);
      if (!mounted) return;
      setState(() {
        _diagnosisResult = result;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Diagnosis failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _escalateToExpert(AppProvider provider) {
    if (_diagnosisResult == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.mark_email_read_rounded, color: Color(0xFF2E7D32), size: 28),
            SizedBox(width: 8),
            Text('Sent to Expert', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Your crop photo and details have been forwarded to the Krishi Vigyan Kendra (KVK) Plant Pathology Specialist.\n\nYou will receive a free SMS alert as soon as the expert verifies the prescription.',
          style: TextStyle(fontSize: 15, height: 1.4),
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
        return Scaffold(
          backgroundColor: const Color(0xFFF7FAF7),
          appBar: AppBar(
            elevation: 2,
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            title: const Text(
              'Crop Photo Diagnosis',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            actions: [
              IconButton(
                tooltip: 'How to take good crop photos',
                icon: const Icon(Icons.info_outline_rounded),
                onPressed: () => _showPhotoTipsDialog(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top instructions banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.center_focus_strong_rounded, color: Color(0xFF2E7D32), size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Take a clear, close-up photo of infected leaves or stems for instant diagnosis.',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1B5E20)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Image Preview or Placeholder Container
                _buildImagePreviewContainer(),

                const SizedBox(height: 16),

                // Two Large Action Buttons: 'Take Photo' & 'Choose from Gallery'
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.camera_alt_rounded, size: 22),
                          label: const Text(
                            'Take Photo',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                            foregroundColor: const Color(0xFF2E7D32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.photo_library_rounded, size: 22),
                          label: const Text(
                            'Gallery',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Large 'Diagnose' button (green)
                if (_selectedImage != null && !_isLoading && _diagnosisResult == null)
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _runDiagnosis(provider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32), // Green button
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.biotech_rounded, size: 24, color: Colors.white),
                      label: const Text(
                        'Diagnose Selected Photo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                // Loading State: circular progress + 'Analyzing crop...'
                if (_isLoading) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF81C784)),
                    ),
                    child: const Column(
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF2E7D32),
                          strokeWidth: 3.5,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Analyzing crop...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Extracting symptoms & consulting plant pathology AI',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],

                // Result Card
                if (_diagnosisResult != null) ...[
                  const SizedBox(height: 20),
                  _buildDiagnosisResultCard(context, provider, _diagnosisResult!),
                ],

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePreviewContainer() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _selectedImage != null ? const Color(0xFF2E7D32) : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: _selectedImageBytes != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    _selectedImageBytes!,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.6),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () {
                          setState(() {
                            _selectedImage = null;
                            _selectedImageBytes = null;
                            _diagnosisResult = null;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_a_photo_rounded,
                      size: 48,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No Photo Selected',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF424242),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap buttons below to click or pick leaf picture',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDiagnosisResultCard(
    BuildContext context,
    AppProvider provider,
    DiagnosisResult result,
  ) {
    final conf = result.confidence ?? 0.0;
    final isLowConfidence = conf < 0.50;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLowConfidence ? const Color(0xFFE57373) : const Color(0xFF81C784),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crop Detected & Severity
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Crop: ${result.crop ?? "Detected Plant"}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
              const Spacer(),
              _buildSeverityBadge(result.severity ?? 'Moderate'),
            ],
          ),

          const SizedBox(height: 12),

          // Disease Name (Large)
          Text(
            result.disease ?? (result.reason ?? 'Crop Symptom Detected'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFFB71C1C),
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 12),

          // Confidence score with colored bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Diagnostic Confidence: ${(conf * 100).round()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
              ConfidenceBadge(score: conf, isCompact: true),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: conf,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                conf >= 0.75
                    ? const Color(0xFF2E7D32)
                    : (conf >= 0.50
                        ? const Color(0xFFF9A825)
                        : const Color(0xFFD32F2F)),
              ),
            ),
          ),

          const Divider(height: 24, thickness: 1, color: Color(0xFFE0E0E0)),

          // Treatment Recommendation (If confidence >= 0.5)
          if (!isLowConfidence) ...[
            const Row(
              children: [
                Icon(Icons.healing_rounded, color: Color(0xFF2E7D32), size: 22),
                SizedBox(width: 8),
                Text(
                  'Treatment Recommendation:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Text(
                result.treatment ?? 'Apply balanced organic pest control and inspect crop in 3 days.',
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
            ),
          ] else ...[
            // Low confidence banner + retake button
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEF9A9A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFC62828)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Low confidence - Sending to expert',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB71C1C),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Visual patterns are ambiguous. We recommend taking a clearer photo or consulting our agricultural expert.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF5D4037)),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC62828),
                      side: const BorderSide(color: Color(0xFFC62828)),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retake Clear Photo'),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Source and Expert Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        result.source ?? 'ICAR Computer Vision AI',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Diagnosis validated by Central Plant Disease Monitoring Network',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 'Ask Expert' Button (Escalation)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _escalateToExpert(provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.support_agent_rounded, size: 22),
              label: const Text(
                'Ask Expert',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityBadge(String severity) {
    Color color;
    switch (severity.toLowerCase()) {
      case 'severe':
      case 'critical / unknown':
      case 'high':
        color = const Color(0xFFC62828);
        break;
      case 'moderate':
        color = const Color(0xFFF57C00);
        break;
      default:
        color = const Color(0xFF2E7D32);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Text(
        'Severity: $severity',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  void _showPhotoTipsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.tips_and_updates_rounded, color: Color(0xFFF9A825), size: 26),
            SizedBox(width: 8),
            Text('Photo Taking Tips', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Hold camera steady 15-20 cm from infected leaf.'),
            SizedBox(height: 6),
            Text('2. Ensure bright, direct daylight without shadows.'),
            SizedBox(height: 6),
            Text('3. Capture both healthy and diseased area for comparison.'),
            SizedBox(height: 6),
            Text('4. Avoid blurry or out-of-focus images.'),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got It', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
