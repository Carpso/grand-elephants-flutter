import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';

/// Converts [source] into a base64 `data:` URI that the API can store as a
/// plain string and that `ProductImage` renders back.
///
/// Accepted sources:
///  * an [XFile] (from `image_picker` or the `camera` plugin),
///  * a filesystem path,
///  * an existing `data:` URI (returned unchanged),
///  * an `http(s)` URL (returned unchanged — already hosted).
///
/// Call sites pick images with `maxWidth: maxDimension` and
/// `imageQuality: quality` so the platform encoder already hands back a JPEG
/// at the requested size; those bytes are packaged as-is. Anything that is
/// still oversized (a raw camera capture, an untouched photo) is downscaled
/// with the platform decoder before upload.
///
/// Returns `null` when the source cannot be read or is not a recognised image.
Future<String?> imageToDataUri(
  Object? source, {
  int maxDimension = 900,
  int quality = 70,
}) async {
  if (source is String) {
    final value = source.trim();
    if (value.startsWith('data:') || value.startsWith('http')) return value;
  }
  final bytes = await _readBytes(source);
  if (bytes == null || bytes.isEmpty) return null;

  final mime = sniffImageMime(bytes);
  if (mime == null) return null;

  // A maxDimension² JPEG at `quality`% should comfortably fit this budget, so
  // already-compressed picker output passes through untouched.
  final budget = maxDimension * maxDimension * quality ~/ 100;
  if (bytes.length <= budget) return _toDataUri(mime, bytes);

  final shrunk = await downscaleImage(bytes, maxDimension);
  if (shrunk != null && shrunk.length < bytes.length) {
    return _toDataUri('image/png', shrunk);
  }
  return _toDataUri(mime, bytes);
}

/// Returns the media type of [bytes] when it is a known image format.
String? sniffImageMime(Uint8List bytes) {
  if (bytes.length > 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return 'image/jpeg';
  }
  if (bytes.length > 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return 'image/png';
  }
  if (bytes.length > 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'image/webp';
  }
  if (bytes.length > 6 &&
      bytes[0] == 0x47 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x38) {
    return 'image/gif';
  }
  return null;
}

/// Decodes [bytes] and returns a PNG whose longest side is at most
/// [maxDimension], or `null` when the image cannot be decoded.
Future<Uint8List?> downscaleImage(Uint8List bytes, int maxDimension) async {
  ui.Codec? codec;
  ui.Codec? resized;
  int fit(int value) => value < 1 ? 1 : (value > maxDimension ? maxDimension : value);
  try {
    codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final width = image.width;
    final height = image.height;
    image.dispose();
    if (width <= maxDimension && height <= maxDimension) return null;

    final scale = maxDimension / (width > height ? width : height);
    resized = await ui.instantiateImageCodec(
      bytes,
      targetWidth: fit((width * scale).round()),
      targetHeight: fit((height * scale).round()),
    );
    final resizedFrame = await resized.getNextFrame();
    final png =
        await resizedFrame.image.toByteData(format: ui.ImageByteFormat.png);
    resizedFrame.image.dispose();
    if (png == null) return null;
    return Uint8List.view(png.buffer, png.offsetInBytes, png.lengthInBytes);
  } catch (_) {
    return null;
  } finally {
    codec?.dispose();
    resized?.dispose();
  }
}

Future<Uint8List?> _readBytes(Object? source) async {
  if (source == null) return null;
  if (source is Uint8List) return source;
  if (source is XFile) {
    try {
      return await source.readAsBytes();
    } catch (_) {
      return null;
    }
  }
  if (source is String) {
    final value = source.trim();
    if (value.isEmpty || value.startsWith('data:') || value.startsWith('http')) {
      return null;
    }
    try {
      return await XFile(value).readAsBytes();
    } catch (_) {
      return null;
    }
  }
  return null;
}

String _toDataUri(String mime, Uint8List bytes) =>
    'data:$mime;base64,${base64Encode(bytes)}';
