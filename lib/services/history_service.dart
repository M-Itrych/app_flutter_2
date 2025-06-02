import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants/app_constants.dart';
import '../nfc_history_screen.dart';

class HistoryService {
  // Load history from SharedPreferences
  static Future<List<NfcHistoryEntry>> loadHistory() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> historyJson = prefs.getStringList(AppConstants.sHistoryKey) ?? [];
      
      return historyJson
          .map((json) => NfcHistoryEntry.fromJson(jsonDecode(json)))
          .toList();
    } catch (error) {
      print('Error loading history: $error');
      return [];
    }
  }

  // Save history to SharedPreferences
  static Future<void> saveHistory(List<NfcHistoryEntry> historyEntries) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> historyJson = historyEntries
          .map((entry) => jsonEncode(entry.toJson()))
          .toList();
      
      await prefs.setStringList(AppConstants.sHistoryKey, historyJson);
    } catch (error) {
      print('Error saving history: $error');
    }
  }

  // Add new entry to history
  static List<NfcHistoryEntry> addToHistory(
    List<NfcHistoryEntry> currentHistory,
    String rawData,
    Map<String, dynamic> metadata,
    {bool isSuccessful = true}
  ) {
    final NfcHistoryEntry entry = NfcHistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      rawData: rawData,
      metadata: metadata,
      timestamp: DateTime.now(),
      isSuccessful: isSuccessful,
    );

    List<NfcHistoryEntry> updatedHistory = [entry, ...currentHistory];
    
    // Keep only last entries to prevent storage issues
    if (updatedHistory.length > AppConstants.iMaxHistoryEntries) {
      updatedHistory = updatedHistory.take(AppConstants.iMaxHistoryEntries).toList();
    }

    return updatedHistory;
  }

  // Get last successful configuration
  static Map<String, String>? getLastSuccessfulConfig(List<NfcHistoryEntry> historyEntries) {
    final NfcHistoryEntry? lastSuccessful = historyEntries
        .where((entry) => entry.isSuccessful)
        .isNotEmpty
        ? historyEntries.where((entry) => entry.isSuccessful).first
        : null;

    if (lastSuccessful != null) {
      return {
        'fbp': lastSuccessful.metadata['fbp'] ?? '',
        'lbp': lastSuccessful.metadata['lbp'] ?? '',
        'aid': lastSuccessful.metadata['aid'] ?? '',
        'fid': lastSuccessful.metadata['fid'] ?? '',
        'keyNumber': lastSuccessful.metadata['keyNumber'] ?? '',
        'key': lastSuccessful.metadata['key'] ?? '',
      };
    }

    return null;
  }
}
