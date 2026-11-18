import 'package:image_picker/image_picker.dart';
import '../core/constants.dart';

/// Encapsulates visual crop disease diagnosis result.
class DiagnosisResult {
  final bool success;
  final String? disease;
  final String? crop;
  final double? confidence;
  final String? treatment;
  final String? source;
  final String? severity;
  final String? reason;
  final bool isEscalated;
  final DateTime? diagnosedAt;

  DiagnosisResult({
    required this.success,
    this.disease,
    this.crop,
    this.confidence,
    this.treatment,
    this.source,
    this.severity,
    this.reason,
    bool? isEscalated,
    DateTime? diagnosedAt,
  })  : isEscalated = isEscalated ?? (confidence != null && confidence < AppConstants.confidenceMedium),
        diagnosedAt = diagnosedAt ?? DateTime.now();

  bool get isHighConfidence => (confidence ?? 0.0) >= AppConstants.confidenceHigh;

  @override
  String toString() =>
      'DiagnosisResult(success: $success, crop: $crop, disease: $disease, confidence: $confidence, severity: $severity)';
}

/// Service simulating offline on-device computer vision plant disease diagnosis.
/// Inspects input photo quality, runs edge vision inference, and returns actionable remedies.
class PhotoService {
  /// Diagnoses plant pathology from a captured image file.
  Future<DiagnosisResult> diagnose(XFile imageFile) async {
    // 1. Check image quality (blur / size check - mock: check file size > 10KB)
    final bytes = await imageFile.readAsBytes();
    final isGoodQuality = bytes.length > 10000;

    if (!isGoodQuality) {
      return DiagnosisResult(
        success: false,
        reason: 'Image quality is too low or blurry. Please hold camera steady in good daylight and retake.',
        diagnosedAt: DateTime.now(),
      );
    }

    // 2. Simulate edge on-device neural network processing (2 seconds)
    await Future.delayed(const Duration(seconds: 2));

    // 3. Return one of several mock verified diagnoses based on deterministic cycle
    final diagnoses = [
      DiagnosisResult(
        success: true,
        disease: 'Blast Disease (Pyricularia oryzae)',
        crop: 'Rice',
        confidence: 0.84,
        treatment: 'Apply Tricyclazole 75% WP at 0.6g/L water. Remove infected plants from field edges.',
        source: 'ICAR-CRRI Cuttack',
        severity: 'Moderate',
        isEscalated: false,
        diagnosedAt: DateTime.now(),
      ),
      DiagnosisResult(
        success: true,
        disease: 'Late Blight (Phytophthora infestans)',
        crop: 'Potato',
        confidence: 0.71,
        treatment: 'Spray Mancozeb 75% WP at 2.5g/L. Improve field drainage immediately.',
        source: 'ICAR-CPRI Shimla',
        severity: 'High',
        isEscalated: false,
        diagnosedAt: DateTime.now(),
      ),
      DiagnosisResult(
        success: true,
        disease: 'Stem Rot (Sclerotium rolfsii)',
        crop: 'Jute',
        confidence: 0.45, // Low confidence -> automatically escalated
        treatment: 'Low diagnostic confidence. Visual pattern is ambiguous. Automatically escalated to KVK Pathologist.',
        source: 'ICAR-NIRJAFT & KVK',
        severity: 'Critical / Unknown',
        isEscalated: true,
        diagnosedAt: DateTime.now(),
      ),
    ];

    final index = DateTime.now().second % diagnoses.length;
    return diagnoses[index];
  }
}
