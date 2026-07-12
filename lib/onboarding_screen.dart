import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../widgets/image_placeholder.dart';
import '../widgets/primary_btn.dart';
import 'login.dart';

class _OnboardingPageData {
  final String title;
  final String feature;
  final String description;
  final String imagePath;

  const _OnboardingPageData({
    required this.title,
    required this.feature,
    required this.description,
    required this.imagePath,
  });
}

const _pages = [
  _OnboardingPageData(
    title: 'Welcome',
    feature: 'Community Pet Care',
    description:
        'Join a friendly network of dog and cat owners sharing experiences and advice.',
    imagePath: 'assets/onboarding1.jpg',
  ),
  _OnboardingPageData(
    title: 'Welcome',
    feature: 'Report Strays',
    description: 'Help pets in need get rescued.',
    imagePath: 'assets/onboarding2.jpg',
  ),
  _OnboardingPageData(
    title: 'Welcome',
    feature: 'Find Nearby Vets',
    description:
        'Easily locate verified emergency clinics and house-call veterinarians.',
    imagePath: 'assets/onboarding3.jpg',
  ),
  _OnboardingPageData(
    title: 'Welcome',
    feature: 'AI Pet Emotion Recognition',
    description: "Use AI to understand your pet's current mood.",
    imagePath: 'assets/onboarding4.png',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  void _onNext() {
    if (_index == _pages.length - 1) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          page.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ImagePlaceholderBox(height: 160, assetImage: page.imagePath),
                        const SizedBox(height: 24),
                        Text(
                          page.feature,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Dot indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final selected = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: selected ? 18 : 6,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.divider,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
              child: PrimaryButton(
                label: isLast ? 'GET STARTED' : 'NEXT',
                isAccent: isLast,
                onPressed: _onNext,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
