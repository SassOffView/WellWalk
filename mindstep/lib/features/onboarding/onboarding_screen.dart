import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _slides = AppStrings.onboardingSlides;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go('/setup'),
                child: Text(
                  AppStrings.onboardingSkip,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _OnboardingSlide(slide: _slides[i], index: i),
              ),
            ),

            // Dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppColors.cyan
                              : AppColors.lightBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Next / Start button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _slides.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          context.go('/setup');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: AppColors.cyan,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _currentPage < _slides.length - 1
                            ? AppStrings.onboardingNext
                            : AppStrings.onboardingGetStarted,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// Maps onboarding slide index → Phosphor icon factory
final _onboardingIcons = <PhosphorIconData Function()>[
  () => PhosphorIcons.waves(PhosphorIconsStyle.fill),
  () => PhosphorIcons.footprints(PhosphorIconsStyle.fill),
  () => PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
  () => PhosphorIcons.brain(PhosphorIconsStyle.fill),
  () => PhosphorIcons.target(PhosphorIconsStyle.fill),
];

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.slide, required this.index});
  final Map<String, String> slide;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconData = index < _onboardingIcons.length
        ? _onboardingIcons[index]()
        : PhosphorIcons.star(PhosphorIconsStyle.fill);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Phosphor icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.cyan.withOpacity(0.15),
                  AppColors.cyanLight.withOpacity(0.1),
                ],
              ),
            ),
            child: Center(
              child: PhosphorIcon(
                iconData,
                size: 56,
                color: AppColors.cyan,
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            slide['title']!,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Body
          Text(
            slide['body']!,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
