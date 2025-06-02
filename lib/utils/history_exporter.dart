import '../models/nfc_history_entry.dart';
import 'history_filter.dart';

class HistoryExporter {
  static String exportAllHistory(List<NfcHistoryEntry> historyEntries) {
    String export = 'NFC History Export\n==================\n\n';
    
    for (int i = 0; i < historyEntries.length; i++) {
      final entry = historyEntries[i];
      export += 'Entry ${i + 1}\n';
      export += 'Timestamp: ${HistoryFilter.formatDateTime(entry.timestamp)}\n';
      export += 'Status: ${entry.isSuccessful ? 'Success' : 'Error'}\n';
      export += 'AID: ${entry.metadata['aid']}\n';
      export += 'FID: ${entry.metadata['fid']}\n';
      export += 'Key Number: ${entry.metadata['keyNumber']}\n';
      export += 'Data: ${entry.rawData}\n';
      export += '${'-' * 50}\n\n';
    }

    return export;
  }

  static String exportSingleEntry(NfcHistoryEntry entry) {
    return '''NFC Read Data
Time: ${HistoryFilter.formatDateTime(entry.timestamp)}
AID: ${entry.metadata['aid']} | FID: ${entry.metadata['fid']}
Data: ${entry.rawData}''';
  }
}
