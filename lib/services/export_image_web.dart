// package:web is not a dependency of this project, so the browser download
// path uses dart:html behind the conditional export in export_image.dart.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

/// Triggers a browser download of the PNG and returns the file name.
Future<String> exportImage(List<int> bytes, String fileName) async {
  final blob = html.Blob([bytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';
  html.document.body!.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return fileName;
}
