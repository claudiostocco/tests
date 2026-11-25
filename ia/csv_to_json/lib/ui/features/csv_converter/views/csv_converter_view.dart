import 'package:flutter/material.dart';
import 'package:csv_to_json/ui/theme/app_theme.dart';
import '../view_models/csv_converter_view_model.dart';

/// Main View for selecting CSV, converting to JSON, copying, and sending to API.
class CsvConverterView extends StatefulWidget {
  final CsvConverterViewModel viewModel;

  const CsvConverterView({
    super.key,
    required this.viewModel,
  });

  @override
  State<CsvConverterView> createState() => _CsvConverterViewState();
}

class _CsvConverterViewState extends State<CsvConverterView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    if (!mounted) return;

    final errorMessage = widget.viewModel.errorMessage;
    if (errorMessage != null && errorMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: widget.viewModel.clearErrorMessage,
          ),
        ),
      );
    }

    final successMessage = widget.viewModel.successMessage;
    if (successMessage != null && successMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(successMessage)),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final viewModel = widget.viewModel;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.transform, color: AppTheme.primaryColor),
                const SizedBox(width: 10),
                const Text('CSV to JSON Converter'),
              ],
            ),
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Card
                        _buildHeaderCard(),

                        const SizedBox(height: 24),

                        // File Picker Section
                        _buildFileSelectionCard(viewModel),

                        const SizedBox(height: 24),

                        // Action Buttons Section
                        _buildActionButtons(viewModel),

                        if (viewModel.jsonOutput != null) ...[
                          const SizedBox(height: 24),
                          // JSON Output Section
                          _buildJsonOutputCard(viewModel),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Loading Overlay
              if (viewModel.isLoading) _buildLoadingOverlay(viewModel),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Importador e Conversor CSV',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecione um arquivo CSV para convertê-lo em formato JSON e enviar para a API REST.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textMutedColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelectionCard(CsvConverterViewModel viewModel) {
    final fileName = viewModel.selectedFileName;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            OutlinedButton.icon(
              onPressed: viewModel.isLoading ? null : viewModel.pickFile,
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('Selecionar arquivo CSV'),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.jsonBgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: fileName != null ? AppTheme.primaryColor : AppTheme.cardBorderColor,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    fileName != null ? Icons.description : Icons.insert_drive_file_outlined,
                    color: fileName != null ? AppTheme.primaryColor : AppTheme.textMutedColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      fileName ?? 'Nenhum arquivo selecionado',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: fileName != null ? FontWeight.w600 : FontWeight.normal,
                        color: fileName != null ? AppTheme.textColor : AppTheme.textMutedColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (fileName != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      color: AppTheme.textMutedColor,
                      onPressed: viewModel.reset,
                      tooltip: 'Remover arquivo',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(CsvConverterViewModel viewModel) {
    return Row(
      children: [
        // "Importar CSV" Button (Required exact label)
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: viewModel.canImport ? viewModel.convertAndSendCsv : null,
            icon: const Icon(Icons.send_rounded),
            label: const Text('Importar CSV'),
          ),
        ),
        if (viewModel.jsonOutput != null) ...[
          const SizedBox(width: 16),
          // Copy JSON Button
          Expanded(
            flex: 1,
            child: OutlinedButton.icon(
              onPressed: viewModel.canCopy ? viewModel.copyJsonToClipboard : null,
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copiar JSON'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildJsonOutputCard(CsvConverterViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.code_rounded, color: AppTheme.secondaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      'Resultado JSON',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: viewModel.canCopy ? viewModel.copyJsonToClipboard : null,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copiar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.jsonBgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.cardBorderColor),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  viewModel.jsonOutput ?? '',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Color(0xFF38BDF8), // Light Sky Blue
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(CsvConverterViewModel viewModel) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppTheme.primaryColor),
                const SizedBox(height: 16),
                Text(
                  viewModel.loadingMessage ?? 'Carregando...',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
