import '../models/nfc_data_model.dart';
import 'data_formatter.dart';
import 'data_analyzer.dart';

class DataExporter {
  static String createTextExport(NfcDataModel data) {
    return '''NFC Data Export
=============
Timestamp: ${data.timestamp}
Application ID: ${data.aid}
File ID: ${data.fid}
Key Number: ${data.keyNumber}
Read Range: ${data.fbp} - ${data.lbp}

Raw Data (Hex):
${DataFormatter.formatBinaryData(data.rawData)}

ASCII Interpretation:
${DataFormatter.hexToAscii(data.rawData)}

Hex Dump:
${DataFormatter.createHexDump(data.rawData)}
''';
  }

  static String createJsonExport(NfcDataModel data) {
    return '''{
  "metadata": {
    "timestamp": "${data.timestamp}",
    "aid": "${data.aid}",
    "fid": "${data.fid}",
    "keyNumber": "${data.keyNumber}",
    "fbp": "${data.fbp}",
    "lbp": "${data.lbp}"
  },
  "data": {
    "raw": "${data.rawData}",
    "formatted_hex": "${DataFormatter.formatBinaryData(data.rawData)}",
    "ascii": "${DataFormatter.hexToAscii(data.rawData)}",
    "byte_count": ${data.bytesRead}
  }
}''';
  }

  static String createCsvExport(NfcDataModel data) {
    List<String> lines = ['Offset,Hex,ASCII'];
    String cleanData = data.rawData.replaceAll(' ', '').replaceAll('\n', '');

    for (int index = 0; index < cleanData.length; index += 2) {
      if (index + 1 < cleanData.length) {
        String offset = (index ~/ 2).toString().padLeft(4, '0');
        String hexPair = cleanData.substring(index, index + 2);
        String ascii = '';

        try {
          int charCode = int.parse(hexPair, radix: 16);
          ascii = (charCode >= 32 && charCode <= 126)
              ? String.fromCharCode(charCode)
              : '.';
        } catch (error) {
          ascii = '?';
        }

        lines.add('$offset,$hexPair,$ascii');
      }
    }

    return lines.join('\n');
  }

  static String createFullReport(NfcDataModel data) {
    return '''NFC DATA ANALYSIS REPORT
========================

OPERATION DETAILS
-----------------
Read Timestamp: ${DataFormatter.formatTimestamp(data.timestamp)}
Application ID: ${data.aid}
File ID: ${data.fid}
Key Number: ${data.keyNumber}
Authentication Key: ${data.authKey?.substring(0, 8) ?? 'Unknown'}...
Read Range: ${data.fbp} - ${data.lbp}

DATA ANALYSIS
-------------
Data Length: ${data.dataLength} characters
Bytes Read: ${data.bytesRead}
Data Type: ${DataAnalyzer.getDataType(data.rawData)}

STRUCTURE ANALYSIS
------------------
${DataAnalyzer.analyzeDataStructure(data.rawData).join('\n')}

RAW DATA (FORMATTED)
--------------------
${DataFormatter.formatBinaryData(data.rawData)}

ASCII INTERPRETATION
--------------------
${DataFormatter.hexToAscii(data.rawData)}

HEX DUMP
--------
${DataFormatter.createHexDump(data.rawData)}

Report generated on: ${DateTime.now()}
''';
  }

  static String createShareSummary(NfcDataModel data) {
    return '''NFC Read Summary
Time: ${DataFormatter.formatTimestamp(data.timestamp)}
AID: ${data.aid} | FID: ${data.fid}
Data: ${data.rawData}''';
  }
}
