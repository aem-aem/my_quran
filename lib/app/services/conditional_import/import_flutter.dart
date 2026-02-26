import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Load asset using Flutter's rootBundle
Future<String> loadAsset(String path) async {
  return await rootBundle.loadString(path);
}

/// Debug print using Flutter's debugPrint
void debugLog(String? message) {
  debugPrint(message);
}

/// Decode JSON in a separate isolate to avoid blocking UI
Future<dynamic> decodeJson(String jsonString) async {
  return await compute(_decodeJson, jsonString);
}

dynamic _decodeJson(String jsonString) {
  return jsonDecode(jsonString);
}
