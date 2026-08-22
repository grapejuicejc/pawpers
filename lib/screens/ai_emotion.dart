import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app_theme.dart';
import '../../widgets/image_placeholder.dart';
import '../../widgets/primary_btn.dart';
import '../../services/emotion_service.dart';
import 'ai_report_issue.dart';

class EmotionResource {
  final String title;
  final String description;
  final String url;

  const EmotionResource({
    required this.title,
    required this.description,
    required this.url,
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
  EmotionResult? _result;
  String? _selectedPetType;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(source: source, imageQuality: 85);

    if (picked == null) return;

    setState(() {
      _selectedImage = File(picked.path);
      _result = null;
      _isAnalyzing = false;
      _selectedPetType = null;
    });
  }

  Future<void> _analyzeEmotion() async {
    if (_selectedImage == null) return;

    if (_selectedPetType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select whether the pet is a cat or dog.'),
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _result = null;
    });

    try {
      final result = await EmotionService.analyzePetEmotion(
        image: _selectedImage!,
        petType: _selectedPetType!,
      );

      if (!mounted) return;

      setState(() {
        _result = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isAnalyzing = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to analyze image: $e')));
    }
  }

  void _reset() {
    setState(() {
      _selectedImage = null;
      _result = null;
      _selectedPetType = null;
      _isAnalyzing = false;
    });
  }

  List<Map<String, String>> _getEmotionResources(
    String petType,
    String emotion,
  ) {
    final pet = petType.toLowerCase();
    final mood = emotion.toLowerCase();

    if (pet == 'cat') {
      switch (mood) {
        case 'happy':
          return [
            {
              'title': 'Understanding a Happy Cat',
              'description':
                  'Learn how cats communicate happiness through their body language.',
              'url':
                  'https://www.cats.org.uk/help-and-advice/cat-behaviour/cat-body-language',
            },
            {
              'title': 'Cat Body Language',
              'description':
                  'Learn how your cat uses its ears, eyes, whiskers, tail and posture to communicate.',
              'url': 'https://www.petmd.com/cat/behavior/cat-body-language',
            },
          ];

        case 'relaxed':
          return [
            {
              'title': 'Signs Your Cat Is Relaxed',
              'description':
                  'Learn how relaxed posture and body language can indicate that your cat is comfortable.',
              'url':
                  'https://www.cats.org.uk/help-and-advice/cat-behaviour/cat-body-language',
            },
            {
              'title': 'Understanding Cat Body Language',
              'description':
                  'Learn more about how cats communicate their emotions through body language.',
              'url': 'https://www.petmd.com/cat/behavior/cat-body-language',
            },
          ];

        case 'aggressive':
        case 'angry':
          return [
            {
              'title': 'Understanding Cat Aggression',
              'description':
                  'Learn about common signs of feline aggression and how to respond safely.',
              'url':
                  'https://www.aspca.org/pet-care/cat-care/common-cat-behavior-issues/aggression-cats',
            },
            {
              'title': 'Cat Body Language',
              'description':
                  'Learn how cats communicate fear, stress and aggression through their body language.',
              'url':
                  'https://www.cats.org.uk/help-and-advice/cat-behaviour/cat-body-language',
            },
          ];

        case 'sad':
          return [
            {
              'title': 'Understanding Your Cat’s Body Language',
              'description':
                  'Learn how changes in posture, eyes, ears and behaviour may provide clues about your cat’s mood.',
              'url':
                  'https://www.cats.org.uk/help-and-advice/cat-behaviour/cat-body-language',
            },
            {
              'title': 'Cat Behaviour and Emotions',
              'description':
                  'Learn more about understanding changes in your cat’s behaviour.',
              'url': 'https://www.petmd.com/cat/behavior',
            },
            {
              'title': 'How To Make Your Cat Happy',
              'description':
                  'Learn more about reasons why your cat is sad and how to make them happy.',
              'url': 'https://www.webmd.com/pets/cats/why-is-my-cat-sad',
            },
          ];
      }
    }

    //=============DOG====================

    if (pet == 'dog') {
      switch (mood) {
        case 'happy':
          return [
            {
              'title': 'Understanding a Happy Dog',
              'description':
                  'Learn how dogs communicate happiness through their eyes, ears, mouth, tail and posture.',
              'url':
                  'https://www.aspcapro.org/resource/canine-body-language-tips',
            },
            {
              'title': 'How to Read Dog Body Language',
              'description':
                  'Learn how different parts of a dog’s body communicate its emotional state.',
              'url':
                  'https://www.petmd.com/dog/behavior/how-to-read-dog-body-language',
            },
          ];

        case 'relaxed':
          return [
            {
              'title': 'Signs Your Dog Is Relaxed',
              'description':
                  'Learn how relaxed posture, eyes, ears, mouth and tail can indicate that your dog is comfortable.',
              'url':
                  'https://www.aspcapro.org/resource/canine-body-language-tips',
            },
            {
              'title': 'Understanding Dog Body Language',
              'description':
                  'Learn more about how dogs communicate through their body language.',
              'url':
                  'https://www.petmd.com/dog/behavior/how-to-read-dog-body-language',
            },
          ];

        case 'angry':
        case 'aggressive':
          return [
            {
              'title': 'Understanding Dog Aggression',
              'description':
                  'Learn how to recognize signs of tension and aggression and how to respond safely.',
              'url':
                  'https://www.aspca.org/pet-care/dog-care/common-dog-behavior-issues/aggression',
            },
            {
              'title': 'Canine Body Language',
              'description':
                  'Learn how dogs communicate discomfort, fear and aggression through body language.',
              'url':
                  'https://www.aspcapro.org/resource/canine-body-language-tips',
            },
          ];

        case 'sad':
          return [
            {
              'title': 'Understanding Dog Body Language',
              'description':
                  'Learn how dogs communicate their emotional state through their eyes, ears, mouth, tail and posture.',
              'url':
                  'https://www.aspcapro.org/resource/canine-body-language-tips',
            },
            {
              'title': 'How to Read Dog Body Language',
              'description':
                  'Learn more about interpreting changes in your dog’s body language and behaviour.',
              'url':
                  'https://www.petmd.com/dog/behavior/how-to-read-dog-body-language',
            },
          ];
      }
    }

    // Fallback resource
    return [
      {
        'title': 'Understanding Pet Body Language',
        'description':
            'Learn more about how pets communicate through body language and behaviour.',
        'url': 'https://www.petmd.com/',
      },
    ];
  }

  Future<void> _openResource(String url) async {
    final uri = Uri.parse(url);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open the resource.')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the resource.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 25, 20, 8),
              child: Text(
                'AI Pet Emotion Analysis',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child:
                    _selectedImage == null
                        ? _buildUploadPrompt()
                        : _buildResultArea(),
              ),
            ),
          ],
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
          child: Center(
            child: Container(
              height: 160,
              width: 300,
              decoration: BoxDecoration(
                color: AppColors.placeholder,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 32,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Take a Photo',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'or Upload from gallery',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        Center(
          child: SizedBox(
            width: 300,
            height: 50,
            child: PrimaryButton(
              label: 'Upload Image',
              onPressed: () => _pickImage(ImageSource.gallery),
            ),
          ),
        ),

        const SizedBox(height: 70),

        //GIF
        Center(
          child: Image.asset(
            //'assets/catdogmorph.gif',
            'assets/woman.png',
            height: 200,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  Widget _buildResultArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ImagePlaceholderBox(height: 180, imageFile: _selectedImage),

        const SizedBox(height: 18),

        const Text(
          'What type of pet is in the image?',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Text('🐱'), SizedBox(width: 6), Text('Cat')],
                ),
                selected: _selectedPetType == 'cat',
                onSelected: (selected) {
                  setState(() {
                    _selectedPetType = selected ? 'cat' : null;
                    _result = null;
                  });
                },
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: ChoiceChip(
                label: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Text('🐶'), SizedBox(width: 6), Text('Dog')],
                ),
                selected: _selectedPetType == 'dog',
                onSelected: (selected) {
                  setState(() {
                    _selectedPetType = selected ? 'dog' : null;
                    _result = null;
                  });
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        PrimaryButton(
          label: 'Analyze Emotion',
          onPressed: _isAnalyzing ? null : _analyzeEmotion,
        ),

        if (_isAnalyzing) ...[
          const SizedBox(height: 20),

          const Center(child: CircularProgressIndicator()),

          const SizedBox(height: 10),

          const Center(
            child: Text(
              'Analyzing your pet...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],

        if (!_isAnalyzing && _result != null) ...[
          const SizedBox(height: 24),

          const Text(
            'Detected emotion',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),

          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _result!.emotion.toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(_result!.confidence * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 6),
              Text(
                'Why this result?',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),

          const SizedBox(height: 10),

          _buildResourceCard(),

          const SizedBox(height: 20),

          PrimaryButton(label: 'Analyze Another Image', onPressed: _reset),

          const SizedBox(height: 10),

          TextButton(
            onPressed: () => showReportIssueDialog(context),
            child: const Text(
              'Report Issue',
              style: TextStyle(color: Color.fromARGB(255, 241, 9, 9)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResourceCard() {
    final resources = _getEmotionResources(_result!.petType, _result!.emotion);

    return Column(
      children:
          resources.map((resource) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
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
                          Text(
                            resource['title']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            resource['description']!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    OutlinedButton(
                      onPressed: () => _openResource(resource['url']!),
                      child: const Text('Read More'),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
}
