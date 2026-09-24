import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Writes PNG bytes into the app documents directory and returns the path.
Future<String> exportImage(List<int> bytes, String fileName) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
