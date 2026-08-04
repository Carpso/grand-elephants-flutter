import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/providers/config_provider.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';
import 'package:sell_on_app/widgets/toast.dart';

class TryOnScreen extends StatefulWidget {
  const TryOnScreen({super.key});

  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _linkController = TextEditingController();
  bool _isProcessing = false;
  bool _showAR = false;
  bool _isCameraMode = false;

  late final AnimationController _contentController;
  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _contentOffset;

  late final AnimationController _arItemController;
  late final Animation<double> _arItemOpacity;
  late final Animation<double> _arItemScale;

  @override
  void initState() {
    super.initState();
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _contentOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeInOut),
    );
    _contentOffset = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _contentController, curve: Curves.easeInOut));
    _contentController.forward();

    _arItemController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _arItemOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _arItemController, curve: Curves.easeInOut),
    );
    _arItemScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _arItemController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _linkController.dispose();
    _contentController.dispose();
    _arItemController.dispose();
    super.dispose();
  }

  void _handleFetchLink() {
    if (_linkController.text.trim().isEmpty) return;
    setState(() {
      _isProcessing = true;
      _isCameraMode = false;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _showAR = true;
      });
      _arItemController.forward();
    });
  }

  void _handleStartCamera() {
    setState(() {
      _isCameraMode = true;
      _showAR = true;
    });
    _arItemController.forward();
  }

  final List<Map<String, dynamic>> _socialPlatforms = [
    {'name': 'Instagram', 'icon': Icons.camera_alt, 'color': const Color(0xFFE1306C)},
    {'name': 'TikTok', 'icon': Icons.music_note, 'color': Colors.black},
    {'name': 'Shopify', 'icon': Icons.shopping_cart, 'color': const Color(0xFF96BF48)},
    {'name': 'Facebook', 'icon': Icons.facebook, 'color': const Color(0xFF1877F2)},
  ];

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();

    return Scaffold(
      backgroundColor: AppColors.brandDark,
      body: SafeArea(
        child: _showAR ? _buildARView(config) : _buildInputView(config),
      ),
    );
  }

  Widget _buildInputView(ConfigProvider config) {
    return FadeTransition(
      opacity: _contentOpacity,
      child: SlideTransition(
        position: _contentOffset,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'OMNI-CHANNEL TRY-ON',
                style: TextStyle(
                  color: AppColors.brandPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Virtual Fitting Room',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Paste a product link from your favorite store or social media, or use your camera to try items properly.',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              SoftCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LIVE EXPERIENCE',
                      style: TextStyle(
                        color: AppColors.brandPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SoftButton(
                      title: 'Open Camera',
                      variant: SoftButtonVariant.primary,
                      icon: const Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Colors.black,
                      ),
                      onPressed: _handleStartCamera,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Or Paste Link',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SoftCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PASTE PRODUCT URL',
                      style: TextStyle(
                        color: AppColors.brandPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.link,
                            size: 20,
                            color: AppColors.brandPrimary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _linkController,
                              decoration: const InputDecoration(
                                hintText: 'https://instagram.com/p/...',
                                hintStyle: TextStyle(color: Color(0xFF555555)),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              autocorrect: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _socialPlatforms.map((p) {
                        return Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Icon(
                                p['icon'] as IconData,
                                size: 20,
                                color: p['color'] as Color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              p['name'] as String,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    SoftButton(
                      title: _isProcessing
                          ? 'Extracting item...'
                          : 'Start Virtual Try-On',
                      variant: SoftButtonVariant.secondary,
                      onPressed:
                          _isProcessing || _linkController.text.trim().isEmpty
                              ? null
                              : _handleFetchLink,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.security,
                      size: 20,
                      color: AppColors.brandPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Secured by ${config.appName} AI',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildARView(ConfigProvider config) {
    return Stack(
      children: [
        if (_isCameraMode)
          Container(color: Colors.black)
        else
          Image.network(
            'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=1000&auto=format&fit=crop',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: Colors.black),
          ),
        Container(color: Colors.black.withValues(alpha: 0.2)),
        AnimatedBuilder(
          animation: _arItemController,
          builder: (context, child) {
            return Opacity(
              opacity: _arItemOpacity.value,
              child: Transform.scale(
                scale: _arItemScale.value,
                child: child,
              ),
            );
          },
          child: Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  width: 256,
                  height: 256,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      'https://placehold.co/400x400/F3F4F6/D4AF37?text=Simulated+Item',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                        color: AppColors.softSurface,
                        child: const Icon(
                          Icons.image,
                          size: 80,
                          color: AppColors.brandMuted,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Perfect Fit',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 56,
          left: 32,
          child: GestureDetector(
            onTap: () => setState(() => _showAR = false),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
        Positioned(
          left: 32,
          right: 32,
          bottom: 56,
          child: SoftCard(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Extracted Product',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ready for Checkout',
                      style: TextStyle(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SoftButton(
                  title: 'Add to Cart',
                  variant: SoftButtonVariant.primary,
                  onPressed: () {
                    ToastProvider.of(context).show('Extracted item added to cart!', ToastType.success);
                    Navigator.of(context).pushNamed('/cart/checkout');
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
