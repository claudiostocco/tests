import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:csv_to_json/data/models/csv_file_data.dart';
import 'package:csv_to_json/data/repositories/csv_repository.dart';
import 'package:csv_to_json/ui/features/csv_converter/view_models/csv_converter_view_model.dart';
import 'package:csv_to_json/ui/features/csv_converter/views/csv_converter_view.dart';

class MockCsvRepository implements CsvRepository {
  @override
  Future<CsvFileData?> selectCsvFile() async => null;

  @override
  String convertCsvToJson(String csvContent) => '[]';

  @override
  Future<void> sendJsonToApi(String jsonPayload) async {}
}

void main() {
  testWidgets('CsvConverterView renders main UI components', (WidgetTester tester) async {
    final repository = MockCsvRepository();
    final viewModel = CsvConverterViewModel(csvRepository: repository);

    await tester.pumpWidget(
      MaterialApp(
        home: CsvConverterView(viewModel: viewModel),
      ),
    );

    expect(find.text('CSV to JSON Converter'), findsOneWidget);
    expect(find.text('Importador e Conversor CSV'), findsOneWidget);
    expect(find.text('Selecionar arquivo CSV'), findsOneWidget);
    expect(find.text('Importar CSV'), findsOneWidget);
    expect(find.text('Nenhum arquivo selecionado'), findsOneWidget);
  });
}
