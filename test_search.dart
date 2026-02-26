import 'dart:io';

// Import search service
import 'lib/app/services/search_service.dart';

// Mock Flutter dependencies for standalone Dart execution
void debugPrint(String message) => print(message);

T compute<T>(T Function(dynamic) fn, dynamic arg) => fn(arg);

class RootBundle {
  Future<String> loadString(String path) async {
    final file = File(path);
    return await file.readAsString();
  }
}

final rootBundle = RootBundle();

void main() async {
  print('🧪 Testing SearchService...\n');

  // Initialize search service
  await SearchService.init();

  if (!SearchService.isReady) {
    print('❌ SearchService failed to initialize');
    exit(1);
  }

  print('✅ SearchService initialized\n');

  // Test queries
  final testQueries = [
    'الكتاب ذلك',
    'ذلك',
    'بإثمى',
    'جزاء',
  ];

  for (final query in testQueries) {
    print('━' * 50);
    print('🔍 Query: "$query"');

    final results = SearchService.search(query);
    print('📊 Found ${results.length} results');

    if (results.isNotEmpty) {
      print('📖 First 5 results:');
      for (final result in results.take(5)) {
        print('   - Surah ${result.surah}, Verse ${result.verse}');
      }
    }
    print('');
  }

  print('✅ All tests completed!');
}
