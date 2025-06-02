// nfc_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'nfc_data_display_screen.dart';

class NfcHistoryEntry {
  final String id;
  final String rawData;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final bool isSuccessful;

  NfcHistoryEntry({
    required this.id,
    required this.rawData,
    required this.metadata,
    required this.timestamp,
    this.isSuccessful = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rawData': rawData,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'isSuccessful': isSuccessful,
    };
  }

  factory NfcHistoryEntry.fromJson(Map<String, dynamic> json) {
    return NfcHistoryEntry(
      id: json['id'],
      rawData: json['rawData'],
      metadata: Map<String, dynamic>.from(json['metadata']),
      timestamp: DateTime.parse(json['timestamp']),
      isSuccessful: json['isSuccessful'] ?? true,
    );
  }
}

class NfcHistoryScreen extends StatefulWidget {
  final List<NfcHistoryEntry> historyEntries;
  final Function(List<NfcHistoryEntry>) onHistoryUpdated;

  const NfcHistoryScreen({
    super.key,
    required this.historyEntries,
    required this.onHistoryUpdated,
  });

  @override
  State<NfcHistoryScreen> createState() => _NfcHistoryScreenState();
}

class _NfcHistoryScreenState extends State<NfcHistoryScreen> {
  String _searchQuery = '';
  String _filterType = 'All';
  bool _sortByNewest = true;

  List<NfcHistoryEntry> get _filteredAndSortedEntries {
    List<NfcHistoryEntry> filtered = widget.historyEntries.where((entry) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!entry.rawData.toLowerCase().contains(query) &&
            !entry.metadata['aid'].toString().toLowerCase().contains(query) &&
            !entry.metadata['fid'].toString().toLowerCase().contains(query)) {
          return false;
        }
      }

      // Type filter
      if (_filterType == 'Success' && !entry.isSuccessful) return false;
      if (_filterType == 'Error' && entry.isSuccessful) return false;

      return true;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      if (_sortByNewest) {
        return b.timestamp.compareTo(a.timestamp);
      } else {
        return a.timestamp.compareTo(b.timestamp);
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: Text('NFC History (${widget.historyEntries.length})'),
        actions: [
          IconButton(
            icon: Icon(_sortByNewest ? Icons.arrow_downward : Icons.arrow_upward),
            onPressed: () {
              setState(() {
                _sortByNewest = !_sortByNewest;
              });
            },
            tooltip: _sortByNewest ? 'Sort by Oldest' : 'Sort by Newest',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear_all':
                  _showClearHistoryDialog();
                  break;
                case 'export_all':
                  _exportAllHistory();
                  break;
                case 'statistics':
                  _showStatisticsDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'statistics',
                child: Row(
                  children: [
                    Icon(Icons.analytics),
                    SizedBox(width: 8),
                    Text('Statistics'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_all',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export All'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear History'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[100],
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by data, AID, or FID...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Filter: '),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _filterType == 'All',
                      onSelected: (selected) {
                        setState(() {
                          _filterType = 'All';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Success'),
                      selected: _filterType == 'Success',
                      onSelected: (selected) {
                        setState(() {
                          _filterType = 'Success';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Error'),
                      selected: _filterType == 'Error',
                      onSelected: (selected) {
                        setState(() {
                          _filterType = 'Error';
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // History List
          Expanded(
            child: _filteredAndSortedEntries.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _filteredAndSortedEntries.length,
                    itemBuilder: (context, index) {
                      final entry = _filteredAndSortedEntries[index];
                      return _buildHistoryItem(entry, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            widget.historyEntries.isEmpty
                ? 'No NFC reads yet'
                : 'No entries match your search',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.historyEntries.isEmpty
                ? 'Your NFC read history will appear here'
                : 'Try adjusting your search or filters',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(NfcHistoryEntry entry, int index) {
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
              _formatTime(entry.timestamp),
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
              'Data: ${_truncateData(entry.rawData)}',
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
                  _formatDateTime(entry.timestamp),
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
                _viewHistoryEntry(entry);
                break;
              case 'copy':
                _copyHistoryEntry(entry);
                break;
              case 'delete':
                _deleteHistoryEntry(entry);
                break;
              case 'compare':
                _compareWithPrevious(entry, index);
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
            if (index < _filteredAndSortedEntries.length - 1)
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
        onTap: () => _viewHistoryEntry(entry),
      ),
    );
  }

  String _truncateData(String data) {
    if (data.length <= 32) return data;
    return '${data.substring(0, 32)}...';
  }

  String _formatTime(DateTime dateTime) {
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _viewHistoryEntry(NfcHistoryEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NfcDataDisplayScreen(
          sRawData: entry.rawData,
          mMetadata: entry.metadata,
        ),
      ),
    );
  }

  void _copyHistoryEntry(NfcHistoryEntry entry) {
    String summary = '''NFC Read Data
Time: ${_formatDateTime(entry.timestamp)}
AID: ${entry.metadata['aid']} | FID: ${entry.metadata['fid']}
Data: ${entry.rawData}''';

    Clipboard.setData(ClipboardData(text: summary));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _deleteHistoryEntry(NfcHistoryEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this history entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final updatedHistory = List<NfcHistoryEntry>.from(widget.historyEntries);
              updatedHistory.removeWhere((e) => e.id == entry.id);
              widget.onHistoryUpdated(updatedHistory);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Entry deleted'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _compareWithPrevious(NfcHistoryEntry entry, int index) {
    if (index >= _filteredAndSortedEntries.length - 1) return;

    final previousEntry = _filteredAndSortedEntries[index + 1];
    _showComparisonDialog(entry, previousEntry);
  }

  void _showComparisonDialog(NfcHistoryEntry current, NfcHistoryEntry previous) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Comparison'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current (${_formatDateTime(current.timestamp)}):',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(
                    current.rawData,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Previous (${_formatDateTime(previous.timestamp)}):',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(
                    previous.rawData,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Comparison Result:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  current.rawData == previous.rawData
                      ? '✅ Data is identical'
                      : '❌ Data has changed',
                  style: TextStyle(
                    color: current.rawData == previous.rawData ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (current.rawData != previous.rawData) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Changes detected between reads',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: Text('Are you sure you want to delete all ${widget.historyEntries.length} history entries?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onHistoryUpdated([]);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('History cleared'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _exportAllHistory() {
    if (widget.historyEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No history to export'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    String export = 'NFC History Export\n==================\n\n';
    
    for (int i = 0; i < widget.historyEntries.length; i++) {
      final entry = widget.historyEntries[i];
      export += 'Entry ${i + 1}\n';
      export += 'Timestamp: ${_formatDateTime(entry.timestamp)}\n';
      export += 'Status: ${entry.isSuccessful ? 'Success' : 'Error'}\n';
      export += 'AID: ${entry.metadata['aid']}\n';
      export += 'FID: ${entry.metadata['fid']}\n';
      export += 'Key Number: ${entry.metadata['keyNumber']}\n';
      export += 'Data: ${entry.rawData}\n';
      export += '${'-' * 50}\n\n';
    }

    Clipboard.setData(ClipboardData(text: export));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All history exported to clipboard'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showStatisticsDialog() {
    final totalReads = widget.historyEntries.length;
    final successfulReads = widget.historyEntries.where((e) => e.isSuccessful).length;
    final failedReads = totalReads - successfulReads;
    
    final uniqueAids = widget.historyEntries
        .map((e) => e.metadata['aid'].toString())
        .toSet()
        .length;
    
    final uniqueFids = widget.historyEntries
        .map((e) => e.metadata['fid'].toString())
        .toSet()
        .length;

    final oldestRead = widget.historyEntries.isEmpty 
        ? null 
        : widget.historyEntries.reduce((a, b) => a.timestamp.isBefore(b.timestamp) ? a : b);
    
    final newestRead = widget.historyEntries.isEmpty 
        ? null 
        : widget.historyEntries.reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('History Statistics'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatItem('Total Reads', totalReads.toString()),
              _buildStatItem('Successful', '$successfulReads (${(successfulReads / totalReads * 100).toStringAsFixed(1)}%)'),
              _buildStatItem('Failed', '$failedReads (${(failedReads / totalReads * 100).toStringAsFixed(1)}%)'),
              const SizedBox(height: 16),
              _buildStatItem('Unique Applications', uniqueAids.toString()),
              _buildStatItem('Unique Files', uniqueFids.toString()),
              const SizedBox(height: 16),
              if (oldestRead != null)
                _buildStatItem('First Read', _formatDateTime(oldestRead.timestamp)),
              if (newestRead != null)
                _buildStatItem('Latest Read', _formatDateTime(newestRead.timestamp)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.blue)),
        ],
      ),
    );
  }
}