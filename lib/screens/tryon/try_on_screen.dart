import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/models/product.dart';
import 'package:grand_elephants/providers/cart_provider.dart';
import 'package:grand_elephants/providers/config_provider.dart';
import 'package:grand_elephants/widgets/product_image.dart';
import 'package:grand_elephants/widgets/soft_button.dart';
import 'package:grand_elephants/widgets/soft_card.dart';
import 'package:grand_elephants/widgets/toast.dart';

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

  /// Product passed in via `Navigator.pushNamed('/try-on', arguments: product)`.
  Product? _product;
  bool _argsResolved = false;

  String? _productImageUrl;
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  double _scaleAtGestureStart = 1.0;

  CameraController? _cameraController;
  bool _cameraReady = false;
  Uint8List? _capturedBytes;
  bool _capturing = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsResolved) return;
    _argsResolved = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Product) {
      _product = args;
      if (args.image.isNotEmpty) {
        _productImageUrl = args.image;
        _showAR = true;
        _arItemController.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _linkController.dispose();
    _contentController.dispose();
    _arItemController.dispose();
    _stopCamera();
    super.dispose();
  }

  /// Releases the camera on every exit path (close button, navigation, dispose).
  Future<void> _stopCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    _cameraReady = false;
    if (controller == null) return;
    try {
      await controller.dispose();
    } catch (_) {
      // Camera was never fully initialised or already released.
    }
  }

  Future<void> _initCamera() async {
    await _stopCamera();
    CameraController? controller;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _cameraReady = false);
        return;
      }
      controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _cameraController = controller;
      await controller.initialize();
      if (!mounted) {
        await _disposeController(controller);
        return;
      }
      setState(() => _cameraReady = true);
    } catch (_) {
      if (controller != null) await _disposeController(controller);
      if (mounted) setState(() => _cameraReady = false);
    }
  }

  Future<void> _disposeController(CameraController controller) async {
    try {
      await controller.dispose();
    } catch (_) {}
    if (identical(_cameraController, controller)) _cameraController = null;
  }

  Future<void> _handleStartCamera() async {
    setState(() {
      _isCameraMode = true;
      _showAR = true;
      _isProcessing = false;
      _capturedBytes = null;
    });
    _arItemController.forward(from: 0);
    await _initCamera();
  }

  Future<void> _handleExitAR() async {
    await _stopCamera();
    if (!mounted) return;
    setState(() {
      _showAR = false;
      _isCameraMode = false;
      _capturedBytes = null;
    });
  }

  Future<void> _handleCapture() async {
    final controller = _cameraController;
    if (controller == null || !_cameraReady || _capturing) return;
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _capturedBytes = bytes;
        _capturing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _capturing = false);
      ToastProvider.of(context).show('Could not capture a photo', ToastType.error);
    }
  }

  void _handleResumePreview() {
    setState(() => _capturedBytes = null);
  }

  void _handleResetOverlay() {
    setState(() {
      _scale = 1.0;
      _offset = Offset.zero;
    });
  }

  Future<void> _handleStartTryOn() async {
    final typedUrl = _linkController.text.trim();
    final fallbackImage = _product?.image ?? '';
    final url = typedUrl.isNotEmpty ? typedUrl : fallbackImage;
    if (url.isEmpty) return;
    if (typedUrl.isNotEmpty) {
      final uri = Uri.tryParse(typedUrl);
      if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
        ToastProvider.of(context).show('Enter a valid http(s) image URL', ToastType.error);
        return;
      }
    }
    final isNetworkUrl = url.startsWith('http://') || url.startsWith('https://');
    setState(() {
      _isProcessing = true;
      _isCameraMode = false;
      _capturedBytes = null;
    });
    try {
      if (isNetworkUrl) await precacheImage(NetworkImage(url), context);
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

  Future<void> _handleAddToCart() async {
    final product = _product;
    if (product == null) return;
    final cart = context.read<CartProvider>();
    try {
      await cart.addToCart(product);
    } catch (e) {
      if (!mounted) return;
      ToastProvider.of(context)
          .show('Could not add ${product.name} to cart', ToastType.error);
      return;
    }
    await _stopCamera();
    if (!mounted) return;
    setState(() {
      _isCameraMode = false;
      _capturedBytes = null;
    });
    ToastProvider.of(context).show('${product.name} added to cart', ToastType.success);
    Navigator.of(context).pushNamed('/cart/checkout');
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

  Widget _buildSelectedProductCard(ConfigProvider config) {
    final product = _product;
    if (product == null) return const SizedBox.shrink();
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 56,
              height: 56,
              color: AppColors.softSurface,
              child: ProductImage(src: product.image, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.brandDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'TRY-ON ITEM  ·  ${config.formatPrice(product.price)}',
                  style: const TextStyle(
                    color: AppColors.brandMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.check_circle,
            color: AppColors.brandPrimary,
            size: 22,
          ),
        ],
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
              Text(
                _product != null
                    ? '${_product!.name} is ready to try on. Use your camera or paste an image link to preview it against your feed.'
                    : 'Paste a product image link or use your camera to preview an item against your camera feed.',
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              if (_product == null) ...[
                const SizedBox(height: 12),
                Text(
                  'Open a product to try it on and buy.',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              if (_product != null) ...[
                _buildSelectedProductCard(config),
                const SizedBox(height: 24),
              ],
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
                      onPressed: _isProcessing ||
                              (_linkController.text.trim().isEmpty &&
                                  (_product?.image.isEmpty ?? true))
                          ? null
                          : _handleStartTryOn,
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
                  onScaleStart: (_) => _scaleAtGestureStart = _scale,
                  onScaleUpdate: (details) {
                    setState(() {
                      _offset += details.focalPointDelta;
                      _scale = (_scaleAtGestureStart * details.scale)
                          .clamp(0.3, 2.0)
                          .toDouble();
                    });
                  },
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
                      child: ProductImage(
                        src: _productImageUrl!,
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
          right: 24,
          child: Row(
            children: [
              _roundAction(Icons.close, () => _handleExitAR(), tooltip: 'Close'),
              if (!_isCameraMode) ...[
                const SizedBox(width: 12),
                _roundAction(Icons.camera_alt, () => _handleStartCamera(),
                    tooltip: 'Open camera'),
              ],
            ],
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _product?.name ?? 'Try-On Preview',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.brandDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    if (_product != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        config.formatPrice(_product!.price),
                        style: const TextStyle(
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                if (_productImageUrl != null)
                  _buildHintChip('Drag to position • Pinch to scale')
                else
                  const Text(
                    'Open a product to try it on and buy.',
                    style: TextStyle(
                      color: AppColors.brandMuted,
                      fontSize: 12,
                    ),
                  ),
                if (_productImageUrl != null && _product == null) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Open a product to try it on and buy.',
                    style: TextStyle(
                      color: AppColors.brandMuted,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
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
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Reset',
                      child: IconButton(
                        onPressed: _handleResetOverlay,
                        icon: const Icon(
                          Icons.restart_alt,
                          size: 22,
                          color: AppColors.brandDark,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (_isCameraMode && _cameraReady) ...[
                      Expanded(
                        child: SoftButton(
                          title: _capturedBytes != null
                              ? 'Resume'
                              : (_capturing ? 'Saving…' : 'Capture'),
                          variant: SoftButtonVariant.secondary,
                          isLoading: _capturing,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          icon: _capturedBytes == null && !_capturing
                              ? const Icon(Icons.camera_alt, size: 18)
                              : null,
                          onPressed: _capturedBytes != null
                              ? _handleResumePreview
                              : _handleCapture,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: SoftButton(
                        title: 'Add to Cart',
                        variant: SoftButtonVariant.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        onPressed:
                            _product == null ? null : () => _handleAddToCart(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHintChip(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.brandPrimary.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.touch_app,
            size: 14,
            color: AppColors.brandDark,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              message,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.brandDark,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundAction(IconData icon, VoidCallback onTap, {String? tooltip}) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip, child: button);
  }

  Widget _buildARBackground() {
    final captured = _capturedBytes;
    if (captured != null) {
      return Image.memory(
        captured,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
      );
    }
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
