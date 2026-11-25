import '../models/csv_file_data.dart';
import '../services/api_service.dart';
import '../services/csv_converter_service.dart';
import '../services/file_picker_service.dart';

abstract class CsvRepository {
  Future<CsvFileData?> selectCsvFile();
  String convertCsvToJson(String csvContent);
  Future<void> sendJsonToApi(String jsonPayload);
}

class CsvRepositoryImpl implements CsvRepository {
  final FilePickerService _filePickerService;
  final CsvConverterService _csvConverterService;
  final ApiService _apiService;

  CsvRepositoryImpl({
    required FilePickerService filePickerService,
    required CsvConverterService csvConverterService,
    required ApiService apiService,
  })  : _filePickerService = filePickerService,
        _csvConverterService = csvConverterService,
        _apiService = apiService;

  @override
  Future<CsvFileData?> selectCsvFile() async {
    return await _filePickerService.pickCsvFile();
  }

  @override
  String convertCsvToJson(String csvContent) {
    return _csvConverterService.convertCsvToJson(csvContent);
  }

  @override
  Future<void> sendJsonToApi(String jsonPayload) async {
    await _apiService.sendJsonPayload(jsonPayload);
  }
}
