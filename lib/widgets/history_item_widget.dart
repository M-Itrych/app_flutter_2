import 'package:flutter/material.dart';
import '../models/nfc_history_entry.dart';
import '../utils/history_filter.dart';

class HistoryItemWidget extends StatelessWidget {
  final NfcHistoryEntry entry;
  final int index;
  final int totalFilteredCount;
  final VoidCallback onView;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final VoidCallback? onCompare;

  const HistoryItemWidget({
    super.key,
    required this.entry,
    required this.index,
    required this.totalFilteredCount,
    required this.onView,
    required this.onCopy,
    required this.onDelete,
    this.onCompare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: entry.isSuccessful ? Colors.green : Colors.red,
          child: Icon(
            entry.isSuccessful ? Icons.check : Icons.error,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'AID: ${entry.metadata['aid']} | FID: ${entry.metadata['fid']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              HistoryFilter.formatTime(entry.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Data: ${HistoryFilter.truncateData(entry.rawData)}',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${entry.rawData.replaceAll(' ', '').length ~/ 2} bytes',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  HistoryFilter.formatDateTime(entry.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'view':
                onView();
                break;
              case 'copy':
                onCopy();
                break;
              case 'delete':
                onDelete();
                break;
              case 'compare':
                onCompare?.call();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'copy',
              child: Row(
                children: [
                  Icon(Icons.copy),
                  SizedBox(width: 8),
                  Text('Copy Data'),
                ],
              ),
            ),
            if (onCompare != null)
              const PopupMenuItem(
                value: 'compare',
                child: Row(
                  children: [
                    Icon(Icons.compare_arrows),
                    SizedBox(width: 8),
                    Text('Compare'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: onView,
      ),
    );
  }
}
