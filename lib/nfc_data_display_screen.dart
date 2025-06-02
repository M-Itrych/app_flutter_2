// nfc_data_display_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/nfc_data_model.dart';
import 'utils/data_formatter.dart';
import 'utils/data_analyzer.dart';
import 'utils/data_exporter.dart';

// NfcDataDisplayScreen
// Stateful widget for displaying NFC data and analysis
// Params:
//   rawData: String - raw NFC data
//   metadata: Map<String, dynamic> - metadata for the NFC read
class NfcDataDisplayScreen extends StatefulWidget {
  final String sRawData;
  final Map<String, dynamic> mMetadata;

  const NfcDataDisplayScreen({
    super.key,
    required this.sRawData,
    required this.mMetadata,
  });

  @override
  State<NfcDataDisplayScreen> createState() => _NfcDataDisplayScreenState();
}

// _NfcDataDisplayScreenState
// State for NfcDataDisplayScreen, manages tabs and data display
class _NfcDataDisplayScreenState extends State<NfcDataDisplayScreen>
    with SingleTickerProviderStateMixin {
  late TabController oTabController;
  late NfcDataModel dataModel;
  bool bShowHex = true;

  // initState
  // Initializes tab controller
  @override
  void initState() {
    super.initState();
    oTabController = TabController(length: 3, vsync: this);
    dataModel = NfcDataModel(
      rawData: widget.sRawData,
      metadata: widget.mMetadata,
    );
  }

  // dispose
  // Disposes tab controller
  @override
  void dispose() {
    oTabController.dispose();
    super.dispose();
  }

  // _buildDataAnalysis
  // Builds the analysis tab content
  // Returns: Widget
  Widget _buildDataAnalysis() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Operation Details',
            [
              'Read Timestamp: ${DataFormatter.formatTimestamp(dataModel.timestamp)}',
              'Application ID: ${dataModel.aid}',
              'File ID: ${dataModel.fid}',
              'Key Number: ${dataModel.keyNumber}',
              'Read Range: ${dataModel.fbp} - ${dataModel.lbp}',
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Data Analysis',
            [
              'Data Length: ${dataModel.dataLength} characters',
              'Bytes Read: ${dataModel.bytesRead}',
              'Data Type: ${DataAnalyzer.getDataType(dataModel.rawData)}',
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Data Structure Detection',
            DataAnalyzer.analyzeDataStructure(dataModel.rawData),
          ),
        ],
      ),
    );
  }

  // _buildInfoCard
  // Builds a card widget for displaying info
  // Params:
  //   sTitle: String
  //   lItems: List<String>
  // Returns: Widget
  Widget _buildInfoCard(String sTitle, List<String> lItems) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            ...lItems.map((sItem) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(sItem),
            )),
          ],
        ),
      ),
    );
  }

  // _buildRawDataView
  // Builds the raw data tab content
  // Returns: Widget
  Widget _buildRawDataView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle between formatted hex and ASCII
          Row(
            children: [
              const Text('Display Format: '),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('BIN'),
                selected: bShowHex,
                onSelected: (bSelected) {
                  setState(() {
                    bShowHex = true;
                  });
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('HEX ASCII'),
                selected: !bShowHex,
                onSelected: (bSelected) {
                  setState(() {
                    bShowHex = false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        bShowHex ? 'Hexadecimal Data' : 'ASCII Interpretation',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          String textToCopy = bShowHex
                              ? DataFormatter.formatBinaryData(dataModel.rawData)
                              : DataFormatter.hexToAscii(dataModel.rawData);
                          Clipboard.setData(ClipboardData(text: textToCopy));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Data copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        tooltip: 'Copy to clipboard',
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        bShowHex
                            ? DataFormatter.formatBinaryData(dataModel.rawData)
                            : DataFormatter.hexToAscii(dataModel.rawData),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // _buildHexDumpView
  // Builds the hex dump tab content
  // Returns: Widget
  Widget _buildHexDumpView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Hex Dump View',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: DataFormatter.createHexDump(dataModel.rawData)));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Hex dump copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Copy hex dump',
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Container(
                child: SingleChildScrollView(
                  child: SelectableText(
                    DataFormatter.createHexDump(dataModel.rawData),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // build
  // Builds the main widget tree
  // Params:
  //   context: BuildContext
  // Returns: Widget
  @override
  Widget build(BuildContext oContext) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text('NFC Data View'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (sValue) {
              switch (sValue) {
                case 'save':
                  _saveDataToFile();
                  break;
                case 'share':
                  _shareData();
                  break;
                case 'export':
                  _exportData();
                  break;
              }
            },
            itemBuilder: (oContext) => [
              const PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    Icon(Icons.save),
                    SizedBox(width: 8),
                    Text('Save to File'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Share Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export Report'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: oTabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Analysis'),
            Tab(icon: Icon(Icons.data_object), text: 'Raw Data'),
            Tab(icon: Icon(Icons.grid_on), text: 'Hex Dump'),
          ],
        ),
      ),
      body: TabBarView(
        controller: oTabController,
        children: [
          _buildDataAnalysis(),
          _buildRawDataView(),
          _buildHexDumpView(),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(oContext);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Read Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _showDataComparisonDialog();
                },
                icon: const Icon(Icons.compare_arrows),
                label: const Text('Compare'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // _saveDataToFile
  // Shows dialog to select save format
  void _saveDataToFile() {
    showDialog(
      context: context,
      builder: (oContext) => AlertDialog(
        title: const Text('Save Data'),
        content: const Text('Choose save format:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(oContext);
              _performSave('txt');
            },
            child: const Text('Text File (.txt)'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(oContext);
              _performSave('json');
            },
            child: const Text('JSON (.json)'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(oContext);
              _performSave('csv');
            },
            child: const Text('CSV (.csv)'),
          ),
        ],
      ),
    );
  }

  // _performSave
  // Copies data to clipboard in selected format
  // Params:
  //   sFormat: String
  void _performSave(String sFormat) {
    String sContent = '';
    String sFilename = 'nfc_data_${DateTime.now().millisecondsSinceEpoch}';

    switch (sFormat) {
      case 'txt':
        sContent = DataExporter.createTextExport(dataModel);
        sFilename += '.txt';
        break;
      case 'json':
        sContent = DataExporter.createJsonExport(dataModel);
        sFilename += '.json';
        break;
      case 'csv':
        sContent = DataExporter.createCsvExport(dataModel);
        sFilename += '.csv';
        break;
    }

    Clipboard.setData(ClipboardData(text: sContent));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Data copied to clipboard as $sFormat format'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            _showExportPreview(sContent, sFormat);
          },
        ),
      ),
    );
  }

  // _showExportPreview
  // Shows dialog with export preview
  // Params:
  //   sContent: String
  //   sFormat: String
  void _showExportPreview(String sContent, String sFormat) {
    showDialog(
      context: context,
      builder: (oContext) => AlertDialog(
        title: Text('Export Preview ($sFormat)'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              sContent,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(oContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // _shareData
  // Copies summary to clipboard for sharing
  void _shareData() {
    String summary = DataExporter.createShareSummary(dataModel);
    Clipboard.setData(ClipboardData(text: summary));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data summary copied to clipboard - ready to share!'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  // _exportData
  // Shows dialog to confirm full report export
  void _exportData() {
    showDialog(
      context: context,
      builder: (oContext) => AlertDialog(
        title: const Text('Export Full Report'),
        content: const Text('Generate a comprehensive report with all analysis data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(oContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(oContext);
              _generateFullReport();
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  // _generateFullReport
  // Copies full analysis report to clipboard
  void _generateFullReport() {
    String report = DataExporter.createFullReport(dataModel);
    Clipboard.setData(ClipboardData(text: report));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Full report copied to clipboard'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Preview',
          onPressed: () => _showExportPreview(report, 'Full Report'),
        ),
      ),
    );
  }

  // _showDataComparisonDialog
  // Shows dialog for data comparison feature
  void _showDataComparisonDialog() {
    showDialog(
      context: context,
      builder: (oContext) => AlertDialog(
        title: const Text('Data Comparison'),
        content: const Text(
          'Comparison feature would allow you to:\n\n'
          '• Compare this read with previous reads\n'
          '• Highlight differences between datasets\n'
          '• Track changes over time\n'
          '• Analyze data patterns\n\n'
          'This feature requires storing read history.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(oContext),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(oContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Comparison feature coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Enable History'),
          ),
        ],
      ),
    );
  }
}