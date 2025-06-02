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
