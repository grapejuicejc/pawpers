import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../app_theme.dart';
import '../../widgets/image_placeholder.dart';
import '../../widgets/primary_btn.dart';
import 'ai_report_issue.dart';

/// Result returned from the emotion-analysis call.
/// DB (Supabase): this shape should match whatever the `analyze-pet-emotion`
/// edge function / model returns.
class _EmotionResult {
  final String label; // e.g. "Happy"
  final int confidencePercent; // e.g. 93
  final String resourceTitle;
  final String resourceDescription;

  const _EmotionResult({
    required this.label,
    required this.confidencePercent,
    required this.resourceTitle,
    required this.resourceDescription,
  });
}

class AiEmotionScreen extends StatefulWidget {
  const AiEmotionScreen({super.key});

  @override
  State<AiEmotionScreen> createState() => _AiEmotionScreenState();
}

class _AiEmotionScreenState extends State<AiEmotionScreen> {
  File? _selectedImage;
  bool _isAnalyzing = false;
  _EmotionResult? _result;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    setState(() {
      _selectedImage = File(picked.path);
      _result = null;
      _isAnalyzing = true;
    });

    // DB (Supabase):
    // final data = await SupabaseService.instance.analyzePetEmotion(picked.path);
    // final result = _EmotionResult(
    //   label: data['label'] as String,
    //   confidencePercent: ((data['confidence'] as num) * 100).round(),
    //   resourceTitle: data['resource_title'] as String? ?? 'Resource',
    //   resourceDescription: data['resource_description'] as String? ?? '',
    // );

    await Future.delayed(const Duration(seconds: 1)); // placeholder "analysis" delay
    const result = _EmotionResult(
      label: 'Happy 😊',
      confidencePercent: 93,
      resourceTitle: 'Resource #1',
      resourceDescription: 'Learn what makes a happy, relaxed dog or cat.',
    );

    if (!mounted) return;
    setState(() {
      _isAnalyzing = false;
      _result = result;
    });
  }

  void _reset() {
    setState(() {
      _selectedImage = null;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Pet Emotion Analysis')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _selectedImage == null ? _buildUploadPrompt() : _buildResultArea(),
        ),
      ),
    );
  }

  Widget _buildUploadPrompt() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Upload a clear photo of your pet's face to analyze their current emotional state.",
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: () => _pickImage(ImageSource.camera),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.placeholder,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined, size: 32, color: AppColors.textSecondary),
                SizedBox(height: 8),
                Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w700)),
                Text('or Upload from gallery', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        PrimaryButton(label: 'Upload Image', onPressed: () => _pickImage(ImageSource.gallery)),
      ],
    );
  }

  Widget _buildResultArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ImagePlaceholderBox(height: 180, imageFile: _selectedImage),
        const SizedBox(height: 18),
        if (_isAnalyzing)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_result != null) ...[
          Row(
            children: [
              const Text('Your pet is ...', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_result!.label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
                child: Text('${_result!.confidencePercent}%', style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Text('Why this result?', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.chipGrey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_result!.resourceTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(_result!.resourceDescription, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () {
                    // TODO: open full resource/article detail
                  },
                  child: const Text('Read More'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Analyze Another Image', onPressed: _reset),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => showReportIssueDialog(context),
            child: const Text('Report Issue', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ],
    );
  }
}