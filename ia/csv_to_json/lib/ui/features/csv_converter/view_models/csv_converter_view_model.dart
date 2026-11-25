import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/csv_file_data.dart';
import '../../../../data/repositories/csv_repository.dart';

/// ViewModel managing UI state and business logic for CSV to JSON conversion.
class CsvConverterViewModel extends ChangeNotifier {
  final CsvRepository _csvRepository;

  CsvConverterViewModel({required CsvRepository csvRepository})
      : _csvRepository = csvRepository;

  CsvFileData? _selectedFile;
  CsvFileData? get selectedFile => _selectedFile;
  String? get selectedFileName => _selectedFile?.name;

  String? _jsonOutput;
  String? get jsonOutput => _jsonOutput;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _loadingMessage;
  String? get loadingMessage => _loadingMessage;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  bool get canImport => _selectedFile != null && !_isLoading;
  bool get canCopy => _jsonOutput != null && _jsonOutput!.isNotEmpty && !_isLoading;

  /// Prompts the user to select a CSV file.
  Future<void> pickFile() async {
    _clearMessages();
    _setLoading(true, 'Selecting CSV file...');

    try {
      final fileData = await _csvRepository.selectCsvFile();
      if (fileData != null) {
        _selectedFile = fileData;
        _jsonOutput = null; // Clear previous conversion result
        _successMessage = 'File "${fileData.name}" selected successfully.';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Converts the selected CSV file to JSON and simulates sending it to a REST API.
  Future<void> convertAndSendCsv() async {
    if (_selectedFile == null) {
      _errorMessage = 'Please select a CSV file first.';
      notifyListeners();
      return;
    }

    _clearMessages();

    try {
      // Step 1: Convert CSV to JSON
      _setLoading(true, 'Converting CSV to JSON...');
      await Future.delayed(const Duration(milliseconds: 300)); // UI smoothness delay

      final jsonResult = _csvRepository.convertCsvToJson(_selectedFile!.content);
      _jsonOutput = jsonResult;
      notifyListeners();

      // Step 2: Send JSON to REST API (Simulated)
      _setLoading(true, 'Sending JSON to REST API...');
      await _csvRepository.sendJsonToApi(jsonResult);

      _successMessage = 'CSV converted and successfully sent to API!';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Copies the generated JSON payload to the system clipboard.
  Future<void> copyJsonToClipboard() async {
    if (_jsonOutput == null || _jsonOutput!.isEmpty) {
      _errorMessage = 'No JSON available to copy.';
      notifyListeners();
      return;
    }

    try {
      await Clipboard.setData(ClipboardData(text: _jsonOutput!));
      _successMessage = 'JSON copied to clipboard!';
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to copy JSON to clipboard: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Resets the current file and JSON output.
  void reset() {
    _selectedFile = null;
    _jsonOutput = null;
    _clearMessages();
    notifyListeners();
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSuccessMessage() {
    _successMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value, [String? message]) {
    _isLoading = value;
    _loadingMessage = value ? message : null;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }
}
