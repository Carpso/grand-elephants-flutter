import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/providers/config_provider.dart';
import 'package:sell_on_app/services/storage_service.dart';
import 'package:sell_on_app/widgets/logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const _SpringCurve(),
      ),
    );
    _controller.forward();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    final hasOnboarded =
        await StorageService.get<bool>('hasOnboarded');
    if (!mounted) return;
    if (hasOnboarded == true) {
      Navigator.of(context).pushReplacementNamed('/login');
    } else {
      Navigator.of(context).pushReplacementNamed('/onboarding');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.read<ConfigProvider>();
    final appNameParts = config.appName.split(' ');
    final firstName = appNameParts.isNotEmpty ? appNameParts.first : 'Sell';
    final lastName =
        appNameParts.length > 1 ? appNameParts.sublist(1).join(' ') : 'On App';

    return Scaffold(
      backgroundColor: AppColors.brandDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: AnimatedBuilder(
              animation: _scaleAnim,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnim.value,
                  child: child,
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.brandDark,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: AppColors.brandPrimary.withValues(alpha: 0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandPrimary.withValues(alpha: 0.2),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: config.appLogo.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: Image.network(
                              config.appLogo,
                              width: 96,
                              height: 96,
                              fit: BoxFit.contain,
                            ),
                          )
                        : const Logo(size: 80),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    firstName,
                    style: const TextStyle(
                      color: AppColors.brandPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 48,
                      letterSpacing: 10,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    lastName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                      fontSize: 30,
                      letterSpacing: 15,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: 96,
                    height: 1,
                    color: AppColors.brandPrimary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      config.appSlogan,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.brandMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: 48),
          child: Text(
            'Loading Experience...',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF4B5563), fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class _SpringCurve extends Curve {
  const _SpringCurve();
  @override
  double transformInternal(double t) {
    const b = 0.1;
    const c = 0.1;
    return 1 -
        (t - 1) * (t - 1) * (t - 1) * (t - 1) +
        b * (t - 1) * (t - 1) * (c - t);
  }
}
