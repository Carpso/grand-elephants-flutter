import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:grand_elephants/constants/app_theme.dart';

/// Renders a product (or any API supplied) image that may be:
///  * a base64 `data:` URI produced by `imageToDataUri`,
///  * an absolute device path (`/storage/...`, `C:\...`),
///  * a network URL (`http(s)://...`),
///  * a bundled asset (`assets/...`).
///
/// Anything that cannot be decoded falls back to a neutral placeholder.
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

  bool get _isData => src.startsWith('data:');

  bool get _isFile =>
      src.startsWith('/') ||
      src.startsWith(r'\\') ||
      RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(src);

  @override
  Widget build(BuildContext context) {
    final fallback = errorBuilder ?? _fallback;

    if (src.trim().isEmpty) {
      return fallback(context, 'Empty image source', null);
    }
    if (_isData) {
      final bytes = _decodeDataUri(src);
      if (bytes == null) {
        return fallback(context, 'Malformed data URI', null);
      }
      return Image.memory(
        bytes,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: fallback,
      );
    }
    if (_isNetwork) {
      return Image.network(
        src,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: fallback,
      );
    }
    if (_isFile) {
      return Image.file(
        File(src),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: fallback,
      );
    }
    return Image.asset(
      src,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) =>
          fallback(context, error, stackTrace),
    );
  }

  static Uint8List? _decodeDataUri(String value) {
    try {
      final comma = value.indexOf(',');
      if (comma < 0) return null;
      final metadata = value.substring(0, comma);
      final payload = value.substring(comma + 1);
      if (!metadata.contains(';base64')) return null;
      return base64Decode(payload.trim());
    } catch (_) {
      return null;
    }
  }

  Widget _fallback(BuildContext context, Object error, StackTrace? stack) {
    return Container(
      color: AppColors.softSurface,
      width: width,
      height: height,
      child: const Icon(Icons.image, color: AppColors.brandMuted, size: 48),
    );
  }
}
