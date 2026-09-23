import 'package:flutter/material.dart';
import 'package:sell_on_app/constants/app_theme.dart';

/// Renders a product image that may be a bundled asset (`assets/...`) or a
/// network URL (`http(s)://...`).
class ProductImage extends StatelessWidget {
  final String src;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const ProductImage({
    super.key,
    required this.src,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
  });

  bool get _isNetwork => src.startsWith('http://') || src.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final fallback = _fallback;
    if (_isNetwork) {
      return Image.network(
        src,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder ?? fallback,
      );
    }
    return Image.asset(
      src,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) =>
          (errorBuilder ?? fallback)(context, error, stackTrace),
    );
  }

  Widget _fallback(BuildContext context, Object error, StackTrace? stack) {
    return Container(
      color: AppColors.softSurface,
      child: const Icon(Icons.image, color: AppColors.brandMuted, size: 48),
    );
  }
}
