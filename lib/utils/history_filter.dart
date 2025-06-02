import '../models/nfc_history_entry.dart';

class HistoryFilter {
  static List<NfcHistoryEntry> filterAndSort(
    List<NfcHistoryEntry> entries,
    String searchQuery,
    String filterType,
    bool sortByNewest,
  ) {
    List<NfcHistoryEntry> filtered = entries.where((entry) {
      // Search filter
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!entry.rawData.toLowerCase().contains(query) &&
            !entry.metadata['aid'].toString().toLowerCase().contains(query) &&
            !entry.metadata['fid'].toString().toLowerCase().contains(query)) {
          return false;
        }
      }

      // Type filter
      if (filterType == 'Success' && !entry.isSuccessful) return false;
      if (filterType == 'Error' && entry.isSuccessful) return false;

      return true;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      if (sortByNewest) {
        return b.timestamp.compareTo(a.timestamp);
      } else {
        return a.timestamp.compareTo(b.timestamp);
      }
    });

    return filtered;
  }

  static String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static String truncateData(String data) {
    if (data.length <= 32) return data;
    return '${data.substring(0, 32)}...';
  }
}
