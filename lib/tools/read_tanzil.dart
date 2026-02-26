import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:my_quran/app/search/processor.dart';

/// Standard Arabic diacritics
const List<String> diacritics = [
  '\u0640', // Tatweel (Kashida)
  '\u064B', // Fathatan
  '\u064C', // Dammatan
  '\u064D', // Kasratan
  '\u064E', // Fatha
  '\u064F', // Damma
  '\u0650', // Kasra
  '\u0651', // Shadda
  '\u0652', // Sukun
  '\u0653', // Maddah
  '\u0654', // Hamza Above
  '\u0655', // Hamza Below
  '\u0656', // Subscript Alef
  '\u0657', // Inverted Damma
  '\u0658', // Mark Noon Ghunna
  '\u0659', // Zwarakay
  '\u065A', // Vowel Sign Small V Above
  '\u065B', // Vowel Sign Inverted Small V Above
  '\u065C', // Vowel Sign Dot Below
  '\u065D', // Reversed Damma
  '\u065E', // Fatha with Two Dots
  '\u065F', // Wavy Hamza Below
  '\u0670', // Superscript Alef
];

/// Quranic annotation marks (pause/recitation marks)
const List<String> quranicMarks = [
  '\u0610', // Arabic Sign Sallallahou Alayhe Wassallam
  '\u0611', // Arabic Sign Alayhe Assallam
  '\u0612', // Arabic Sign Rahmatullah Alayhe
  '\u0613', // Arabic Sign Radi Allahou Anhu
  '\u0614', // Arabic Sign Takhallus
  '\u0615', // Arabic Small High Tah
  '\u0616', // Arabic Small High Ligature Alef with Lam with Yeh
  '\u0617', // Arabic Small High Zain
  '\u0618', // Arabic Small Fatha
  '\u0619', // Arabic Small Damma
  '\u061A', // Arabic Small Kasra
  '\u06D6', // Small High Ligature Sad with Lam with Alef Maksura
  '\u06D7', // Small High Ligature Qaf with Lam with Alef Maksura
  '\u06D8', // Small High Meem Initial Form
  '\u06D9', // Small High Lam Alef
  '\u06DA', // Small High Jeem
  '\u06DB', // Small High Three Dots
  '\u06DC', // Small High Seen
  '\u06DD', // End of Ayah
  '\u06DE', // Start of Rub El Hizb
  '\u06DF', // Small High Rounded Zero
  '\u06E0', // Small High Upright Rectangular Zero
  '\u06E1', // Small High Dotless Head of Khah
  '\u06E2', // Small High Meem Isolated Form
  '\u06E3', // Small Low Seen
  '\u06E4', // Small High Madda
  '\u06E5', // Small Waw
  '\u06E6', // Small Yeh
  '\u06E7', // Small High Yeh
  '\u06E8', // Small High Noon
  '\u06E9', // Place of Sajdah
  '\u06EA', // Empty Centre Low Stop
  '\u06EB', // Empty Centre High Stop
  '\u06EC', // Rounded High Stop with Filled Centre
  '\u06ED', // Small Low Meem
];

// Other standalone chars
// \u0622 → آ (Alef with Madda)
// \u0623 → أ (Alef with Hamza Above)
// \u0624 → ؤ (Waw with Hamza)
// \u0625 → إ (Alef with Hamza Below)
// \u0626 → ئ (Yeh with Hamza)
// \u0671   Alef Wasla
// pattern = r'[\u0622-\u0627]'

// \u200e-\u200f: LRM/RLM (bidirectional formatting)
// \u0660-\u0669: Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩)
// \u06F0-\u06F9: Extended Arabic-Indic digits (۰۱۲۳۴۵۶۷۸۹)

/// Read CSV file and parse Quran data
Map<String, Map<int, String>> readQuranCsv(String filePath) {
  final file = File(filePath);
  final lines = file.readAsLinesSync();

  // Skip last 30 lines (skipfooter=30 in Python)
  final dataLines = lines.take(lines.length - 30).toList();

  final Map<String, Map<int, String>> quran = {};

  for (final line in dataLines) {
    final parts = line.split('|');
    if (parts.length >= 3) {
      final surah = int.tryParse(parts[0]);
      final aya = int.tryParse(parts[1]);
      final verse = parts[2];

      if (surah != null && aya != null) {
        final surahKey = '$surah';
        quran.putIfAbsent(surahKey, () => {});
        quran[surahKey]![aya] = verse;
      }
    }
  }

  return quran;
}

/// Process Quran data and remove basmalah from beginning of verses
void processQuranAndSave(String csvPath, String outputPath) {
  final quran = readQuranCsv(csvPath);

  // Get basmalah (first 40 chars of verse 1 in surah 114)
  final basmalah = quran['114']?[1]?.substring(0, 40) ?? '';

  // Remove basmalah from the beginning of first verse of each surah
  for (var i = 1; i <= 114; i++) {
    final surahKey = '$i';
    if (quran.containsKey(surahKey) && quran[surahKey]!.containsKey(1)) {
      quran[surahKey]![1] = quran[surahKey]![1]!.replaceFirst(basmalah, '');
    }
  }

  // Convert to JSON-compatible format (string keys for aya numbers)
  final jsonQuran = <String, Map<String, String>>{};
  for (final entry in quran.entries) {
    jsonQuran[entry.key] = entry.value.map(
      (aya, verse) => MapEntry('$aya', verse),
    );
  }

  final jsonOutput = const JsonEncoder.withIndent(null).convert(jsonQuran);
  File(outputPath).writeAsStringSync(jsonOutput);
  print('Saved Quran data to $outputPath');
}

/// Read JSON from a zip file
Map<String, dynamic> readJsonFromZip(String zipPath, String jsonFileName) {
  final bytes = File(zipPath).readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);

  for (final file in archive) {
    if (file.name == jsonFileName) {
      final content = utf8.decode(file.content as List<int>);
      return json.decode(content) as Map<String, dynamic>;
    }
  }

  throw Exception('File $jsonFileName not found in $zipPath');
}

/// Process Uthmani and Imlaei data to create mapping files
void processUthmaniImlaei({
  required String uthmaniZipPath,
  required String imlaeiZipPath,
  required String uthmaniWithDiacriticsZipPath,
  required String outputDir,
}) {
  // Read from zip files
  final uthmani = readJsonFromZip(uthmaniZipPath, 'uthmani-simple.json');
  final imlaei = readJsonFromZip(imlaeiZipPath, 'imlaei-simple.json');

  // Create uthmani to imlaei mapping
  final uthmaniImlaei = <String, String>{};
  for (final key in uthmani.keys) {
    final value = ArabicTextProcessor.normalize(imlaei[key]['text'] as String);
    final normalizedKey = ArabicTextProcessor.normalize(uthmani[key]['text'] as String);
    if (normalizedKey != value && normalizedKey.isNotEmpty) {
      uthmaniImlaei[normalizedKey] = value;
    }
  }

  /*
  // Save uthmani_to_simple.json
  final jsonOutput1 = const JsonEncoder.withIndent(
    '    ',
  ).convert(uthmaniImlaei);
  File('$outputDir/uthmani_to_simple.json').writeAsStringSync(jsonOutput1);
  */

  // Get unique chars
  final uthmaniImlaeiUniqueChars =
      uthmaniImlaei.values.expand((word) => word.split('')).toSet().toList()
        ..sort();
  print(
    '${uthmaniImlaeiUniqueChars.length} chars:\n_${uthmaniImlaeiUniqueChars.join('_\n_')}_',
  );

  // Read uthmani_with_diacritics_to_simple.json from zip
  final uthmaniDImlaei = readJsonFromZip(
    uthmaniWithDiacriticsZipPath,
    'uthmani-with-diacritics-to-simple.json',
  );

  // Create uthmani to imlaei bis mapping
  final uthmaniImlaeiBis = <String, String>{};
  for (final entry in uthmaniDImlaei.entries) {
    final normalizedKey = ArabicTextProcessor.normalize(entry.key);
    final value = entry.value as String;
    if (normalizedKey != value && normalizedKey.isNotEmpty) {
      uthmaniImlaeiBis[normalizedKey] = ArabicTextProcessor.normalize(value);
    }
  }

  /*
  // Save uthmani_to_simple_bis.json
  final jsonOutput2 = const JsonEncoder.withIndent(
    '    ',
  ).convert(uthmaniImlaeiBis);
  File('$outputDir/uthmani_to_simple_bis.json').writeAsStringSync(jsonOutput2);
  */

  // Get unique chars for bis
  final uthmaniImlaeiBisUniqueChars =
      uthmaniImlaeiBis.values.expand((word) => word.split('')).toSet().toList()
        ..sort();
  print(
    '${uthmaniImlaeiBisUniqueChars.length} chars:\n_${uthmaniImlaeiBisUniqueChars.join('_\n_')}_',
  );

  // Create ter mapping (merged)
  final uthmaniImlaeiTer = Map<String, String>.from(uthmaniImlaei);
  for (final entry in uthmaniImlaeiBis.entries) {
    uthmaniImlaeiTer[entry.key] = entry.value;
  }

  /*
  // Save uthmani_to_simple_ter.json
  final jsonOutput3 = const JsonEncoder.withIndent(
    '    ',
  ).convert(uthmaniImlaeiTer);
  File('$outputDir/uthmani_to_simple_ter.json').writeAsStringSync(jsonOutput3);
  */

  // Create simple to uthmani mapping (reverse mapping with lists)
  final simpleToUthmani = <String, List<String>>{};

  // Initialize keys from both mappings
  for (final v in uthmaniImlaei.values) {
    simpleToUthmani[v] = [];
  }
  for (final v in uthmaniImlaeiBis.values) {
    simpleToUthmani[v] = [];
  }

  // Add values from bis first, then from original
  for (final entry in uthmaniImlaeiBis.entries) {
    simpleToUthmani[entry.value]!.add(entry.key);
  }
  for (final entry in uthmaniImlaei.entries) {
    // Add entry only if not already present from bis
    if (!simpleToUthmani[entry.value]!.contains(entry.key)) {
      simpleToUthmani[entry.value]!.add(entry.key);
    }
  }

  // Save simple_to_uthmani.json
  final jsonOutput4 = const JsonEncoder.withIndent(
    '    ',
  ).convert(simpleToUthmani);
  File('$outputDir/simple_to_uthmani.json').writeAsStringSync(jsonOutput4);

  print('All mapping files saved to $outputDir');
}

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage:');
    print('  dart read_tanzil.dart <csv_file>  - Process Tanzil CSV file');
    print(
      '  dart read_tanzil.dart --process-mappings - Process Uthmani/Imlaei mappings',
    );
    return;
  }

  if (args[0] == '--process-mappings') {
    // Process Uthmani and Imlaei data
    // Expected files in current directory:
    // - uthmani-simple.json.zip
    // - imlaei-simple.json.zip
    // - uthmani_with_diacritics_to_simple.json
    processUthmaniImlaei(
      uthmaniZipPath: 'lib/tools/uthmani-simple.json.zip',
      imlaeiZipPath: 'lib/tools/imlaei-simple.json.zip',
      uthmaniWithDiacriticsZipPath:
          'lib/tools/uthmani-with-diacritics-to-simple.json.zip',
      outputDir: 'assets',
    );
  } else {
    // Process Tanzil CSV file
    final csvPath = args[0];
    processQuranAndSave(csvPath, 'quran_tanzil.json');
  }
}
