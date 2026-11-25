import 'package:flutter/material.dart';
import 'data/repositories/csv_repository.dart';
import 'data/services/api_service.dart';
import 'data/services/csv_converter_service.dart';
import 'data/services/file_picker_service.dart';
import 'ui/features/csv_converter/view_models/csv_converter_view_model.dart';
import 'ui/features/csv_converter/views/csv_converter_view.dart';
import 'ui/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Instantiate dependencies (Clean Architecture / Dependency Injection setup)
  final FilePickerService filePickerService = FilePickerServiceImpl();
  final CsvConverterService csvConverterService = CsvConverterServiceImpl();
  final ApiService apiService = const ApiServiceImpl();

  final CsvRepository csvRepository = CsvRepositoryImpl(
    filePickerService: filePickerService,
    csvConverterService: csvConverterService,
    apiService: apiService,
  );

  final CsvConverterViewModel viewModel = CsvConverterViewModel(
    csvRepository: csvRepository,
  );

  runApp(CsvToJsonApp(viewModel: viewModel));
}

class CsvToJsonApp extends StatelessWidget {
  final CsvConverterViewModel viewModel;

  const CsvToJsonApp({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CSV to JSON Converter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: CsvConverterView(viewModel: viewModel),
    );
  }
}
