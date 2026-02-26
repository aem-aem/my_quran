import 'dart:convert';
import 'dart:io';

/// Load asset using dart:io File (for standalone Dart scripts)
Future<String> loadAsset(String path) async {
  return await File(path).readAsString();
}

/// Debug print using standard print (for standalone Dart scripts)
void debugLog(String? message) {
  print(message);
}

/// Decode JSON synchronously (standalone scripts don't need isolate)
Future<dynamic> decodeJson(String jsonString) async {
  return jsonDecode(jsonString);
}
