/// Conditional debug print:
/// - Uses debugPrint in Flutter (dart.library.ui is available)
/// - Uses print in standalone Dart scripts (falls back to dart:io)
export 'import_stub.dart'
    if (dart.library.ui) 'import_flutter.dart'
    if (dart.library.io) 'import_io.dart';
