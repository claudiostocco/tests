import 'dart:convert';
import 'package:csv/csv.dart';

/// Exception thrown when CSV parsing or JSON conversion fails.
class CsvConversionException implements Exception {
  final String message;
  const CsvConversionException(this.message);

  @override
  String toString() => message;
}

/// Service interface for converting CSV content into JSON.
abstract class CsvConverterService {
  String convertCsvToJson(String csvContent);
}

/// Implementation of [CsvConverterService] using `package:csv` and `dart:convert`.
class CsvConverterServiceImpl implements CsvConverterService {
  @override
  String convertCsvToJson(String csvContent) {
    try {
      if (csvContent.trim().isEmpty) {
        throw const CsvConversionException('CSV content is empty.');
      }

      // Step 1: Clean UTF-8 BOM if present
      String cleanContent = csvContent;
      if (cleanContent.startsWith('\ufeff')) {
        cleanContent = cleanContent.substring(1);
      }

      // Step 2: Auto-detect field delimiter (;, ,, \t, |)
      final String delimiter = _detectDelimiter(cleanContent);

      // Step 3: Decode CSV into rows without forcing auto-types (so zero padding is preserved)
      final decoder = CsvDecoder(
        fieldDelimiter: delimiter,
        dynamicTyping: false,
        skipEmptyLines: true,
      );

      final List<List<dynamic>> rawRows = decoder.convert(cleanContent);

      if (rawRows.isEmpty) {
        throw const CsvConversionException('CSV content is empty.');
      }

      // Step 4: Find column header row (row with maximum columns in top lines)
      final int headerRowIndex = _findHeaderRowIndex(rawRows);

      final List<dynamic> headerRow = rawRows[headerRowIndex];
      final List<String> rawHeaders = headerRow.map((header) {
        return header
            .toString()
            .replaceAll('\ufeff', '')
            .replaceAll('"', '')
            .trim();
      }).toList();

      // Find last index of non-empty header to avoid trailing empty columns
      int lastValidHeaderIndex = rawHeaders.length - 1;
      while (lastValidHeaderIndex >= 0 &&
          rawHeaders[lastValidHeaderIndex].isEmpty) {
        lastValidHeaderIndex--;
      }

      if (lastValidHeaderIndex < 0) {
        throw const CsvConversionException(
          'CSV content has no valid column headers.',
        );
      }

      final List<String> activeRawHeaders = rawHeaders.sublist(
        0,
        lastValidHeaderIndex + 1,
      );

      // Sanitize header keys (lowercase, remove prepositions/pronouns, remove spaces & accents)
      final List<String> sanitizedKeys = activeRawHeaders.map((header) {
        return _sanitizeKey(header);
      }).toList();

      // Step 5: Convert data rows (rows after headerRowIndex) to JSON objects
      final List<Map<String, dynamic>> jsonList = [];

      for (int i = headerRowIndex + 1; i < rawRows.length; i++) {
        final List<dynamic> row = rawRows[i];

        // Skip empty rows
        final nonEmptyCells = row
            .where((cell) => cell != null && cell.toString().trim().isNotEmpty)
            .toList();
        if (nonEmptyCells.isEmpty) {
          continue;
        }

        // Skip report summary / total footer rows
        final firstCellValue = row.first.toString().trim().toLowerCase();
        if (firstCellValue.startsWith('total')) {
          continue;
        }

        final Map<String, dynamic> rowMap = {};
        for (int j = 0; j < sanitizedKeys.length; j++) {
          final String key = sanitizedKeys[j].isNotEmpty
              ? sanitizedKeys[j]
              : 'column_${j + 1}';
          final dynamic rawCell = j < row.length ? row[j] : null;

          rowMap[key] = _parseCellValue(rawCell);
        }

        jsonList.add(rowMap);
      }

      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(jsonList);
    } catch (e) {
      if (e is CsvConversionException) rethrow;
      throw CsvConversionException(
        'Failed to convert CSV to JSON: ${e.toString()}',
      );
    }
  }

  /// Sanitizes object keys: converts to lowercase, removes accents, prepositions/pronouns, and spaces.
  String _sanitizeKey(String rawKey) {
    if (rawKey.trim().isEmpty) return '';

    // Clean special characters and lowercase
    String clean = rawKey
        .replaceAll('\ufeff', '')
        .replaceAll('"', '')
        .replaceAll('º', '')
        .replaceAll('ª', '')
        .replaceAll('°', '')
        .trim()
        .toLowerCase();

    // Replace accents
    clean = clean
        .replaceAll(RegExp(r'[áàãâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòõôö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c');

    // Split words
    final words = clean
        .split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.isNotEmpty)
        .toList();

    // Prepositions/pronouns to strip (de, do, da, dos, das, e, o, a, os, as, em, por, para, com)
    const prepositions = {
      'de',
      'do',
      'da',
      'dos',
      'das',
      'e',
      'o',
      'a',
      'os',
      'as',
      'em',
      'por',
      'para',
      'com',
    };

    final filteredWords = words
        .where((word) => !prepositions.contains(word))
        .toList();

    if (filteredWords.isEmpty) {
      return words.join();
    }

    return filteredWords.join();
  }

  /// Finds the column header row index by picking the row with the maximum number of non-empty columns among top lines.
  int _findHeaderRowIndex(List<List<dynamic>> rows) {
    int maxColumns = 0;
    int bestHeaderIndex = 0;
    final int limit = rows.length < 20 ? rows.length : 20;

    for (int i = 0; i < limit; i++) {
      final row = rows[i];
      final nonEmtpyCount = row
          .where((cell) => cell != null && cell.toString().trim().isNotEmpty)
          .length;

      if (nonEmtpyCount > maxColumns) {
        maxColumns = nonEmtpyCount;
        bestHeaderIndex = i;
      }
    }

    return bestHeaderIndex;
  }

  /// Detects whether the CSV uses semicolon (;), comma (,), tab (\t), or pipe (|) as delimiter.
  String _detectDelimiter(String content) {
    final lines = content
        .split(RegExp(r'\r\n|\r|\n'))
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) return ',';

    final sampleLines = lines.take(15).toList();

    int semicolons = 0;
    int commas = 0;
    int tabs = 0;
    int pipes = 0;

    for (final line in sampleLines) {
      semicolons += ';'.allMatches(line).length;
      commas += ','.allMatches(line).length;
      tabs += '\t'.allMatches(line).length;
      pipes += '|'.allMatches(line).length;
    }

    if (semicolons > commas && semicolons >= tabs && semicolons >= pipes) {
      return ';';
    }
    if (tabs > commas && tabs >= semicolons && tabs >= pipes) {
      return '\t';
    }
    if (pipes > commas && pipes >= semicolons && pipes >= tabs) {
      return '|';
    }
    return ',';
  }

  /// Parses individual cell values (formatting currency, ISO dates, booleans, numbers, and strings).
  dynamic _parseCellValue(dynamic rawValue) {
    if (rawValue == null) return null;
    final str = rawValue.toString().trim();
    if (str.isEmpty) return null;

    // 1. Parse Monetary Values (e.g. "R$ 68,30", "R$ 1.250,50") -> Double
    if (str.toUpperCase().contains('R\$') ||
        str.contains(RegExp(r'^\d+(,\d+)?$'))) {
      final numericStr = str
          .replaceAll('R\$', '')
          .replaceAll('.', '') // Remove thousands separator dot
          .replaceAll(',', '.') // Convert decimal comma to dot
          .trim();
      final val = double.tryParse(numericStr);
      if (val != null) return val;
    }

    // 2. Parse Date & Time to ISO format ("DD/MM/YYYY HH:mm:ss" -> "YYYY-MM-DDTHH:mm:ss")
    final dateTimeRegex = RegExp(
      r'^(\d{2})/(\d{2})/(\d{4})\s+(\d{2}):(\d{2}):(\d{2})$',
    );
    final dateTimeMatch = dateTimeRegex.firstMatch(str);
    if (dateTimeMatch != null) {
      final day = dateTimeMatch.group(1)!;
      final month = dateTimeMatch.group(2)!;
      final year = dateTimeMatch.group(3)!;
      final hour = dateTimeMatch.group(4)!;
      final minute = dateTimeMatch.group(5)!;
      final second = dateTimeMatch.group(6)!;
      return '$year-$month-${day}T$hour:$minute:$second';
    }

    // 3. Parse Date to ISO format ("DD/MM/YYYY" -> "YYYY-MM-DD")
    final dateRegex = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');
    final dateMatch = dateRegex.firstMatch(str);
    if (dateMatch != null) {
      final day = dateMatch.group(1)!;
      final month = dateMatch.group(2)!;
      final year = dateMatch.group(3)!;
      return '$year-$month-$day';
    }

    // 4. Parse Booleans
    if (str.toLowerCase() == 'true') return true;
    if (str.toLowerCase() == 'false') return false;

    // 5. Parse Integers (only if no leading zero except '0' itself, e.g. "123", "0")
    if (RegExp(r'^[1-9]\d*$').hasMatch(str)) {
      final parsed = int.tryParse(str);
      if (parsed != null) return parsed;
    }
    if (str == '0') return 0;

    // 6. Parse Doubles (standard dot notation e.g. "123.45")
    if (RegExp(r'^\d+\.\d+$').hasMatch(str)) {
      final parsed = double.tryParse(str);
      if (parsed != null) return parsed;
    }

    // Return trimmed string (preserves codes like "032562", "000", card numbers, etc.)
    return str;
  }
}
