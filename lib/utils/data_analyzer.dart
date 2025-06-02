import 'data_formatter.dart';

class DataAnalyzer {
  // Detect type of data
  static String getDataType(String rawData) {
    String data = rawData.replaceAll(' ', '');
    
    if (data.isEmpty) return 'Empty';
    if (data == 'FF' * (data.length ~/ 2)) return 'Padding (All FF)';
    if (data == '00' * (data.length ~/ 2)) return 'Empty (All 00)';
    if (RegExp(r'^[0-9A-Fa-f]+$').hasMatch(data)) return 'Hexadecimal';
    
    return 'Mixed/Binary';
  }

  // Analyze structure and patterns in data
  static List<String> analyzeDataStructure(String rawData) {
    List<String> analysis = [];
    String data = rawData.replaceAll(' ', '');

    if (data.isEmpty) {
      analysis.add('• No data received');
      return analysis;
    }

    if (data.startsWith('00')) {
      analysis.add('• Starts with null bytes (00)');
    }
    
    if (data.startsWith('FF')) {
      analysis.add('• Starts with padding bytes (FF)');
    }

    if (RegExp(r'^[0-9A-Fa-f]+$').hasMatch(data)) {
      analysis.add('• Valid hexadecimal format');
    }

    if (data.length >= 4) {
      String firstTwo = data.substring(0, 2);
      int occurrences = data.split(firstTwo).length - 1;
      if (occurrences > 3) {
        analysis.add('• Contains repeated pattern: $firstTwo (${occurrences}x)');
      }
    }

    Set<String> uniqueBytes = <String>{};
    for (int index = 0; index < data.length; index += 2) {
      if (index + 1 < data.length) {
        uniqueBytes.add(data.substring(index, index + 2));
      }
    }

    if (uniqueBytes.length == 1) {
      analysis.add('• Uniform data (single byte value)');
    } else if (uniqueBytes.length < 4) {
      analysis.add('• Low entropy (${uniqueBytes.length} unique bytes)');
    } else if (uniqueBytes.length > data.length ~/ 4) {
      analysis.add('• High entropy (likely contains actual data)');
    }

    String asciiAttempt = DataFormatter.hexToAscii(data);
    if (asciiAttempt != 'Cannot convert to ASCII' &&
        asciiAttempt.replaceAll('.', '').trim().isNotEmpty) {
      analysis.add('• May contain ASCII text data');
    }

    if (analysis.isEmpty) {
      analysis.add('• Standard binary data format');
    }

    return analysis;
  }
}
