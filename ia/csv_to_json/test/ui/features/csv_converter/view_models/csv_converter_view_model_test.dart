import 'package:flutter_test/flutter_test.dart';
import 'package:csv_to_json/data/models/csv_file_data.dart';
import 'package:csv_to_json/data/repositories/csv_repository.dart';
import 'package:csv_to_json/ui/features/csv_converter/view_models/csv_converter_view_model.dart';

class FakeCsvRepository implements CsvRepository {
  CsvFileData? fakeFile;
  String fakeJson = '[\n  {\n    "id": 1\n  }\n]';
  bool shouldThrowError = false;

  @override
  Future<CsvFileData?> selectCsvFile() async {
    if (shouldThrowError) throw Exception('File selection failed');
    return fakeFile;
  }

  @override
  String convertCsvToJson(String csvContent) {
    if (shouldThrowError) throw Exception('Conversion failed');
    return fakeJson;
  }

  @override
  Future<void> sendJsonToApi(String jsonPayload) async {
    if (shouldThrowError) throw Exception('API submission failed');
  }
}

void main() {
  group('CsvConverterViewModel', () {
    late FakeCsvRepository fakeRepository;
    late CsvConverterViewModel viewModel;

    setUp(() {
      fakeRepository = FakeCsvRepository();
      viewModel = CsvConverterViewModel(csvRepository: fakeRepository);
    });

    test('initial state should be empty and idle', () {
      expect(viewModel.selectedFile, isNull);
      expect(viewModel.selectedFileName, isNull);
      expect(viewModel.jsonOutput, isNull);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.canImport, isFalse);
      expect(viewModel.canCopy, isFalse);
    });

    test('pickFile updates selected file state when successful', () async {
      fakeRepository.fakeFile = const CsvFileData(
        name: 'sample.csv',
        content: 'header1,header2\nval1,val2',
      );

      await viewModel.pickFile();

      expect(viewModel.selectedFileName, equals('sample.csv'));
      expect(viewModel.canImport, isTrue);
      expect(viewModel.isLoading, isFalse);
    });

    test('convertAndSendCsv sets jsonOutput and notifies listeners', () async {
      fakeRepository.fakeFile = const CsvFileData(
        name: 'sample.csv',
        content: 'header1,header2\nval1,val2',
      );

      await viewModel.pickFile();
      await viewModel.convertAndSendCsv();

      expect(viewModel.jsonOutput, isNotNull);
      expect(viewModel.canCopy, isTrue);
      expect(viewModel.successMessage, contains('successfully sent to API'));
      expect(viewModel.isLoading, isFalse);
    });

    test('handles errors cleanly when repository throws exception', () async {
      fakeRepository.shouldThrowError = true;

      await viewModel.pickFile();

      expect(viewModel.errorMessage, isNotNull);
      expect(viewModel.selectedFile, isNull);
      expect(viewModel.isLoading, isFalse);
    });
  });
}
