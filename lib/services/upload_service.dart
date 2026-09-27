import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Folders accepted by `POST /api/upload`.
class UploadFolder {
  static const String products = 'products';
  static const String riders = 'riders';
  static const String profiles = 'profiles';
  static const String banners = 'banners';
  static const String deliveries = 'deliveries';
  static const String misc = 'misc';

  const UploadFolder._();
}

/// Uploads picked images to the media host so payloads carry a hosted URL
/// instead of a base64 `data:` URI.
class UploadService {
  const UploadService._();

  /// Sends [dataUri] to `POST /api/upload` and returns the hosted URL, or
  /// `null` when the upload fails (offline, 401, 413, 415, 500, bad shape).
  ///
  /// Callers must fall back to the data URI itself — the API still accepts
  /// base64 data URIs on the legacy endpoints.
  static Future<String?> uploadDataUri(
    String dataUri, {
    required String folder,
  }) async {
    try {
      final res = await ApiClient.instance.post(
        '/api/upload',
        body: {'dataUri': dataUri, 'folder': folder},
      );
      if (res is Map && res['url'] is String) {
        final url = (res['url'] as String).trim();
        if (url.isNotEmpty) return url;
      }
      debugPrint('Upload returned no url for folder "$folder"');
      return null;
    } on ApiException catch (e) {
      debugPrint('Upload failed (${e.statusCode}): ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Upload failed: $e');
      return null;
    }
  }

  /// Uploads [dataUri] and returns the hosted URL, or [dataUri] unchanged
  /// when the upload cannot be completed.
  static Future<String> uploadOrFallback(
    String dataUri, {
    required String folder,
  }) async {
    return await uploadDataUri(dataUri, folder: folder) ?? dataUri;
  }
}
