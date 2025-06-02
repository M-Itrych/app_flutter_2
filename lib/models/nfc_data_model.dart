class NfcDataModel {
  final String rawData;
  final Map<String, dynamic> metadata;

  const NfcDataModel({
    required this.rawData,
    required this.metadata,
  });

  String get timestamp => metadata['timestamp'] ?? '';
  String get aid => metadata['aid'] ?? 'Unknown';
  String get fid => metadata['fid'] ?? 'Unknown';
  String get keyNumber => metadata['keyNumber'] ?? 'Unknown';
  String get fbp => metadata['fbp'] ?? '0';
  String get lbp => metadata['lbp'] ?? 'End';
  String? get authKey => metadata['key']?.toString();

  int get dataLength => rawData.length;
  int get bytesRead => rawData.replaceAll(' ', '').length ~/ 2;
}
