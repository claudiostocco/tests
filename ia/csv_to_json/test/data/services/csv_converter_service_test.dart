import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:csv_to_json/data/services/csv_converter_service.dart';

void main() {
  group('CsvConverterServiceImpl', () {
    late CsvConverterService converterService;

    setUp(() {
      converterService = CsvConverterServiceImpl();
    });

    test('should correctly convert the sample CSV file with sanitized keys, ISO dates, and numeric currency', () {
      final file = File('/home/claudio/projects/tests/ia/csv_to_json/example/vendas_realizadas_relatorio_detalhado_24-07-2026_12_28_18.csv');
      expect(file.existsSync(), isTrue, reason: 'Sample file should exist for test verification');

      final csvInput = file.readAsStringSync();
      final jsonResult = converterService.convertCsvToJson(csvInput);

      expect(jsonResult, isNotNull);
      final List<dynamic> decoded = jsonDecode(jsonResult);

      expect(decoded.length, equals(223));

      final firstItem = decoded[0] as Map<String, dynamic>;

      // Check sanitized keys (no prepositions, no spaces, lowercase, no accents)
      expect(firstItem.containsKey('datatransacao'), isTrue);
      expect(firstItem.containsKey('ntransacao'), isTrue);
      expect(firstItem.containsKey('idvenda'), isTrue);
      expect(firstItem.containsKey('bandeira'), isTrue);
      expect(firstItem.containsKey('formapagamento'), isTrue);
      expect(firstItem.containsKey('planovenda'), isTrue);
      expect(firstItem.containsKey('parcela'), isTrue);
      expect(firstItem.containsKey('totalparcela'), isTrue);
      expect(firstItem.containsKey('numeroautorizacao'), isTrue);
      expect(firstItem.containsKey('tipocartao'), isTrue);
      expect(firstItem.containsKey('numerocartao'), isTrue);
      expect(firstItem.containsKey('numeroterminal'), isTrue);
      expect(firstItem.containsKey('indicadorcancelamentovenda'), isTrue);
      expect(firstItem.containsKey('dataprevistaliquidacao'), isTrue);
      expect(firstItem.containsKey('status'), isTrue);
      expect(firstItem.containsKey('valorparcelabruto'), isTrue);
      expect(firstItem.containsKey('valorparcelaliquido'), isTrue);
      expect(firstItem.containsKey('totalplanovenda'), isTrue);

      // Check ISO dates
      expect(firstItem['datatransacao'], equals('2026-06-30T10:03:24'));
      expect(firstItem['dataprevistaliquidacao'], equals('2026-07-30'));

      // Check numeric currency values (R$ removed, decimal double)
      expect(firstItem['valorparcelabruto'], equals(68.30));
      expect(firstItem['valorparcelaliquido'], equals(66.33));
      expect(firstItem['totalplanovenda'], equals(68.30));

      // Check codes
      expect(firstItem['ntransacao'], equals(3702714913));
      expect(firstItem['numeroautorizacao'], equals('032562'));
      expect(firstItem['indicadorcancelamentovenda'], equals('000'));
    });

    test('should sanitize keys by removing prepositions and spaces', () {
      const csvReportInput = '''
Relatório de Vendas;;;
Data da transação;Valor de parcela;Status do pedido
30/06/2026 10:00:00;R\$ 100,50;Processado
''';

      final jsonResult = converterService.convertCsvToJson(csvReportInput);
      final List<dynamic> decoded = jsonDecode(jsonResult);
      final firstItem = decoded[0] as Map<String, dynamic>;

      expect(firstItem.containsKey('datatransacao'), isTrue);
      expect(firstItem.containsKey('valorparcela'), isTrue);
      expect(firstItem.containsKey('statuspedido'), isTrue);

      expect(firstItem['datatransacao'], equals('2026-06-30T10:00:00'));
      expect(firstItem['valorparcela'], equals(100.50));
      expect(firstItem['statuspedido'], equals('Processado'));
    });

    test('should throw CsvConversionException if CSV is empty', () {
      expect(
        () => converterService.convertCsvToJson(''),
        throwsA(isA<CsvConversionException>()),
      );
    });
  });
}
