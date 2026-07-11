import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../widgets/image_placeholder.dart';
import '../widgets/primary_btn.dart';
import 'login.dart';

class _OnboardingPageData {
  final String title;
  final String feature;
  final String description;

  const _OnboardingPageData({
    required this.title,
    required this.feature,
    required this.description,
  });
}

const _pages = [
  _OnboardingPageData(
    title: 'Welcome',
    feature: 'Feature #1',
    description: 'Connect with a community of pet lovers near you.',
  ),
  _OnboardingPageData(
    title: 'Welcome',
    feature: 'Feature #2',
    description: 'Report strays and help pets in need get rescued.',
  ),
  _OnboardingPageData(
    title: 'Welcome',
    feature: 'Feature #3',
    description: "Use AI to understand your pet's current mood.",
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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
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
                        const ImagePlaceholderBox(height: 160),
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