import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/csv_file_data.dart';

/// Exception thrown when file picking or reading fails.
class FilePickerException implements Exception {
  final String message;
  const FilePickerException(this.message);

  @override
  String toString() => message;
}

/// Service interface for file selection.
abstract class FilePickerService {
  Future<CsvFileData?> pickCsvFile();
}

/// Implementation of [FilePickerService] using the file_picker package.
class FilePickerServiceImpl implements FilePickerService {
  @override
  Future<CsvFileData?> pickCsvFile() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return null; // User canceled the picker
      }

      final PlatformFile file = result.files.first;
      String content = '';

      if (file.bytes != null) {
        try {
          content = utf8.decode(file.bytes!);
        } catch (e) {
          if (e is FormatException) {
            content = utf8.decode(file.bytes!, allowMalformed: true);
          } else {
            rethrow;
          }
        }
      } else if (!kIsWeb && file.path != null) {
        final ioFile = File(file.path!);
        content = await ioFile.readAsString();
      } else {
        throw const FilePickerException(
          'Could not read the selected CSV file content.',
        );
      }

      if (content.trim().isEmpty) {
        throw const FilePickerException('The selected file is empty.');
      }

      return CsvFileData(name: file.name, content: content);
    } catch (e) {
      if (e is FilePickerException) rethrow;
      throw FilePickerException('Failed to select file: ${e.toString()}');
    }
  }
}
