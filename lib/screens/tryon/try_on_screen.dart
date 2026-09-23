import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/models/product.dart';
import 'package:sell_on_app/providers/cart_provider.dart';
import 'package:sell_on_app/providers/config_provider.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';
import 'package:sell_on_app/widgets/soft_input.dart';
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

  String? _productImageUrl;
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  CameraController? _cameraController;
  bool _cameraReady = false;

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
      CurvedAnimation(parent: _arItemController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _linkController.dispose();
    _contentController.dispose();
    _arItemController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _cameraController = controller;
      await controller.initialize();
      if (mounted) setState(() => _cameraReady = true);
    } catch (_) {
      if (mounted) setState(() => _cameraReady = false);
    }
  }

  Future<void> _handleStartCamera() async {
    setState(() {
      _isCameraMode = true;
      _showAR = true;
      _isProcessing = false;
    });
    _arItemController.forward(from: 0);
    await _initCamera();
  }

  Future<void> _handleFetchLink() async {
    final url = _linkController.text.trim();
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      ToastProvider.of(context).show('Enter a valid http(s) image URL', ToastType.error);
      return;
    }
    setState(() {
      _isProcessing = true;
      _isCameraMode = false;
    });
    try {
      await precacheImage(NetworkImage(url), context);
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _showAR = true;
        _productImageUrl = url;
        _scale = 1.0;
        _offset = Offset.zero;
      });
      _arItemController.forward(from: 0);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ToastProvider.of(context).show('Could not load that image URL', ToastType.error);
    }
  }

  String _deriveName(String source) {
    if (source.isEmpty) return 'Try-On Item';
    final uri = Uri.tryParse(source);
    final segment = (uri?.pathSegments.isNotEmpty ?? false)
        ? uri!.pathSegments.last
        : source.split('/').last;
    final cleaned = segment.split('.').first.replaceAll(RegExp(r'[-_]+'), ' ').trim();
    return cleaned.isEmpty ? 'Try-On Item' : cleaned;
  }

  Future<void> _handleAddToCart() async {
    final cart = context.read<CartProvider>();
    final nameCtrl = TextEditingController(
      text: _deriveName(_productImageUrl ?? _linkController.text),
    );
    final priceCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add to Cart'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SoftInput(
              label: 'Product Name',
              controller: nameCtrl,
              hint: 'Item name',
            ),
            SoftInput(
              label: 'Price',
              controller: priceCtrl,
              hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      final name = nameCtrl.text.trim();
      final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
      if (name.isEmpty || price <= 0) {
        if (mounted) {
          ToastProvider.of(context)
              .show('Provide a name and a valid price', ToastType.error);
        }
      } else {
        final product = Product(
          id: 'tryon-${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          price: price,
          priceCents: (price * 100).round(),
          image: _productImageUrl ?? '',
          description: 'Added via Virtual Try-On',
          category: 'Try-On',
        );
        await cart.addToCart(product);
        if (!mounted) return;
        ToastProvider.of(context).show('$name added to cart', ToastType.success);
        Navigator.of(context).pushNamed('/cart/checkout');
      }
    }
    nameCtrl.dispose();
    priceCtrl.dispose();
  }

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
                'Paste a product image link or use your camera to preview an item against your camera feed.',
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
                      'Or Paste Image URL',
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
                                hintText: 'https://store.com/item.jpg',
                                hintStyle: TextStyle(color: Color(0xFF555555)),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              autocorrect: false,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SoftButton(
                      title: _isProcessing ? 'Loading image...' : 'Start Virtual Try-On',
                      variant: SoftButtonVariant.secondary,
                      isLoading: _isProcessing,
                      onPressed: _isProcessing || _linkController.text.trim().isEmpty
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
        Positioned.fill(child: _buildARBackground()),
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.15)),
        ),
        if (_productImageUrl != null)
          Center(
            child: AnimatedBuilder(
              animation: _arItemController,
              builder: (context, child) {
                return Opacity(
                  opacity: _arItemOpacity.value,
                  child: Transform.scale(
                    scale: _arItemScale.value * _scale,
                    child: child,
                  ),
                );
              },
              child: Transform.translate(
                offset: _offset,
                child: GestureDetector(
                  onPanUpdate: (details) =>
                      setState(() => _offset += details.delta),
                  child: Container(
                    width: 240,
                    height: 240,
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
                        _productImageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.softSurface,
                          child: const Icon(
                            Icons.broken_image,
                            size: 64,
                            color: AppColors.brandMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          top: 24,
          left: 24,
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
        if (_productImageUrl != null)
          Positioned(
            top: 32,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Text(
                'Drag to move',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 32,
          child: SoftCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Try-On Preview',
                  style: TextStyle(
                    color: AppColors.brandDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Drag the item to position it, then resize.',
                  style: TextStyle(
                    color: AppColors.brandMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.zoom_out, size: 18, color: AppColors.brandMuted),
                    Expanded(
                      child: Slider(
                        value: _scale,
                        min: 0.3,
                        max: 2.0,
                        activeColor: AppColors.brandPrimary,
                        onChanged: (v) => setState(() => _scale = v),
                      ),
                    ),
                    const Icon(Icons.zoom_in, size: 18, color: AppColors.brandMuted),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SoftButton(
                    title: 'Add to Cart',
                    variant: SoftButtonVariant.primary,
                    onPressed: _handleAddToCart,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildARBackground() {
    final controller = _cameraController;
    if (_isCameraMode && _cameraReady && controller != null) {
      return Center(child: CameraPreview(controller));
    }
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.view_in_ar,
              size: 64,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              _isCameraMode ? 'Camera unavailable' : 'Preview mode',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
