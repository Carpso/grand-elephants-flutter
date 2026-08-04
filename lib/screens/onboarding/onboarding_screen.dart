import 'package:flutter/material.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/services/storage_service.dart';

class Slide {
  final String id;
  final String title;
  final String description;
  final String image;
  final String icon;

  const Slide({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.icon,
  });
}

const List<Slide> slides = [
  Slide(
    id: '1',
    title: 'Curated Heritage',
    description:
        'Discover an exclusive collection of digital luxury pieces, selected for their unparalleled craftsmanship.',
    image: 'assets/branding/onboarding_welcome.png',
    icon: 'security',
  ),
  Slide(
    id: '2',
    title: 'Bespoke Quality',
    description:
        'Every item in our collection is verified for authenticity and crafted from the world\'s finest materials.',
    image: 'assets/branding/onboarding_quality.png',
    icon: 'verified',
  ),
  Slide(
    id: '3',
    title: 'Global Concierge',
    description:
        'Experience white-glove delivery service, reaching you wherever you are in the world.',
    image: 'assets/branding/onboarding_delivery.png',
    icon: 'public',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  void _handleNext() {
    if (_currentIndex < slides.length - 1) {
      _pageController.animateToPage(
        _currentIndex + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    try {
      await StorageService.save('hasOnboarded', true);
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandDark,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: slides.length,
            itemBuilder: (context, index) {
              final slide = slides[index];
              return Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      slide.image,
                      fit: BoxFit.cover,
                      opacity: const AlwaysStoppedAnimation(0.4),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(0.5, 0.1),
                          end: Alignment(0.5, 0.9),
                          colors: [Colors.transparent, Color(0xFF0A0A0A)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 40,
                    right: 40,
                    bottom: 192,
                    child: _SlideContent(slide: slide, index: index),
                  ),
                ],
              );
            },
          ),
          Positioned(
            left: 40,
            right: 40,
            bottom: 48,
            child: Row(
              children: [
                Row(
                  children: List.generate(slides.length, (i) {
                    final isActive = i == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      margin: const EdgeInsets.only(right: 12),
                      width: isActive ? 40 : 16,
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: isActive
                            ? AppColors.brandPrimary
                            : AppColors.brandMuted.withValues(alpha: 0.3),
                      ),
                    );
                  }),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _handleNext,
                  child: Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandPrimary.withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _currentIndex == slides.length - 1
                          ? 'Enter Archive'
                          : 'Next Exhibit',
                      style: const TextStyle(
                        color: AppColors.brandDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
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

class _SlideContent extends StatefulWidget {
  final Slide slide;
  final int index;

  const _SlideContent({required this.slide, required this.index});

  @override
  State<_SlideContent> createState() => _SlideContentState();
}

class _SlideContentState extends State<_SlideContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _opacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const _SpringCurve(damping: 15),
      ),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _SlideContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 2,
                  color: AppColors.brandPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Exhibition ${widget.slide.id}',
                  style: const TextStyle(
                    color: AppColors.brandPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 48,
                  height: 2,
                  color: AppColors.brandPrimary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              widget.slide.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w900,
                height: 1.1,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                widget.slide.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.brandMuted,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpringCurve extends Curve {
  final double damping;
  const _SpringCurve({this.damping = 15});
  @override
  double transformInternal(double t) {
    const b = 0.1;
    const c = 0.1;
    return 1 -
        (t - 1) * (t - 1) * (t - 1) * (t - 1) +
        b * (t - 1) * (t - 1) * (c - t);
  }
}
