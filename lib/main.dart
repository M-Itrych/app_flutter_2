import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nfc_roger_app/services/nfc_services.dart';
import 'constants/app_constants.dart';
import 'services/error_handler.dart';
import 'services/history_service.dart';
import 'utils/input_validator.dart';
import 'widgets/troubleshooting_dialog.dart';
import 'widgets/quick_actions_widget.dart';
import 'nfc_data_display_screen.dart';
import 'nfc_history_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext oBuildContext) {
    return MaterialApp(
      title: 'NFC Reader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainApp(),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final TextEditingController oFbpController = TextEditingController(text: AppConstants.sDefaultFbp);
  final TextEditingController oLbpController = TextEditingController(text: AppConstants.sDefaultLbp);
  final TextEditingController oAidController = TextEditingController(text: AppConstants.sDefaultAid);
  final TextEditingController oFidController = TextEditingController(text: AppConstants.sDefaultFid);
  final TextEditingController oKeyNumberController = TextEditingController(text: AppConstants.sDefaultKeyNumber);
  final TextEditingController oKeyController = TextEditingController(text: AppConstants.sDefaultKey);

  bool bIsLoading = false;
  List<NfcHistoryEntry> lHistoryEntries = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final List<NfcHistoryEntry> history = await HistoryService.loadHistory();
    setState(() {
      lHistoryEntries = history;
    });
  }

  void _addToHistory(String sRawData, Map<String, dynamic> mMetadata, {bool bIsSuccessful = true}) {
    final List<NfcHistoryEntry> updatedHistory = HistoryService.addToHistory(
      lHistoryEntries,
      sRawData,
      mMetadata,
      isSuccessful: bIsSuccessful,
    );

    setState(() {
      lHistoryEntries = updatedHistory;
    });

    HistoryService.saveHistory(lHistoryEntries);
  }

  void _onHistoryUpdated(List<NfcHistoryEntry> lUpdatedHistory) {
    setState(() {
      lHistoryEntries = lUpdatedHistory;
    });
    HistoryService.saveHistory(lHistoryEntries);
  }

  void _performNfcOperation(Map<String, dynamic> mMetadata) {
    final DesfireServices oDesfireServices = DesfireServices(bDebugMode: true);
    
    oDesfireServices.processDesfire(
      mMetadata['fbp'],
      mMetadata['lbp'],
      mMetadata['aid'],
      mMetadata['fid'],
      mMetadata['keyNumber'],
      mMetadata['key'],
    ).then((sResult) => _handleNfcSuccess(sResult, mMetadata))
     .catchError((eError) => _handleNfcError(eError, mMetadata));
  }

  void _handleNfcSuccess(String sResult, Map<String, dynamic> mMetadata) {
    setState(() {
      bIsLoading = false;
    });

    if (ErrorHandler.isErrorResult(sResult)) {
      String sErrorAnalysis = ErrorHandler.parseNfcError(sResult);
      _showDetailedErrorDialog(sResult, sErrorAnalysis, mMetadata);
    } else {
      _addToHistory(sResult, mMetadata, bIsSuccessful: true);
      _navigateToDataDisplay(sResult, mMetadata);
    }
  }

  void _handleNfcError(dynamic eError, Map<String, dynamic> mMetadata) {
    setState(() {
      bIsLoading = false;
    });

    String sErrorMessage = eError.toString();
    String sInterpretedError = ErrorHandler.parseNfcError(sErrorMessage);
    _showDetailedErrorDialog(sErrorMessage, sInterpretedError, mMetadata);
  }

  void _navigateToDataDisplay(String sResult, Map<String, dynamic> mMetadata) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (oBuildContext) => NfcDataDisplayScreen(
          sRawData: sResult,
          mMetadata: mMetadata,
        ),
      ),
    );
  }

  void _showDetailedErrorDialog(String sOriginalError, String sInterpretedError, Map<String, dynamic> mMetadata) {
    _addToHistory(sOriginalError, mMetadata, bIsSuccessful: false);

    final RegExp oStatusCodeRegex = RegExp(r'([0-9A-Fa-f]{2})');
    final Iterable<RegExpMatch> oMatches = oStatusCodeRegex.allMatches(sOriginalError.toUpperCase());
    String sSolutions = '';
    
    for (final RegExpMatch oMatch in oMatches) {
      final String? sCode = oMatch.group(1);
      if (sCode != null && AppConstants.mDesfireStatusCodes.containsKey(sCode) && sCode != '00') {
        sSolutions += '${ErrorHandler.getErrorSolution(sCode)}\n';
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext oBuildContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Expanded(child: Text('NFC Operation Failed')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ExpansionTile(
                  title: const Text('Error Details', style: TextStyle(fontWeight: FontWeight.bold)),
                  children: [
                    SelectableText(sInterpretedError),
                  ],
                ),
                ExpansionTile(
                  title: const Text('Attempted Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
                  children: [
                    Text('AID: ${mMetadata['aid']}'),
                    Text('FID: ${mMetadata['fid']}'),
                    Text('Key Number: ${mMetadata['keyNumber']}'),
                    Text('Range: ${mMetadata['fbp']} - ${mMetadata['lbp']}'),
                  ],
                ),
                if (sSolutions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Recommended Actions:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  Text(sSolutions.trim()),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(oBuildContext),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(oBuildContext);
                TroubleshootingDialog.show(context);
              },
              child: const Text('Get Help'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(oBuildContext);
                _retryWithSuggestions(mMetadata);
              },
              child: const Text('Retry'),
            ),
          ],
        );
      },
    );
  }

  void _retryWithSuggestions(Map<String, dynamic> mMetadata) {
    setState(() {
      bIsLoading = true;
    });
    _performNfcOperation(mMetadata);
  }

  void onButtonPressed() {
    String? sValidationError = InputValidator.validateNfcInputs(
      fbp: oFbpController.text,
      lbp: oLbpController.text,
      aid: oAidController.text,
      fid: oFidController.text,
      keyNumber: oKeyNumberController.text,
      key: oKeyController.text,
    );

    if (sValidationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sValidationError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Map<String, dynamic> mMetadata = {
      'fbp': oFbpController.text,
      'lbp': oLbpController.text,
      'aid': oAidController.text,
      'fid': oFidController.text,
      'keyNumber': oKeyNumberController.text,
      'key': oKeyController.text,
      'timestamp': DateTime.now().toString(),
    };

    setState(() {
      bIsLoading = true;
    });

    _performNfcOperation(mMetadata);
  }

  void _clearAllFields() {
    oFbpController.clear();
    oLbpController.clear();
    oAidController.clear();
    oFidController.clear();
    oKeyNumberController.clear();
    oKeyController.clear();
  }

  void _loadLastSuccessfulConfig() {
    final Map<String, String>? config = HistoryService.getLastSuccessfulConfig(lHistoryEntries);

    if (config != null) {
      oFbpController.text = config['fbp']!;
      oLbpController.text = config['lbp']!;
      oAidController.text = config['aid']!;
      oFidController.text = config['fid']!;
      oKeyNumberController.text = config['keyNumber']!;
      oKeyController.text = config['key']!;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Last successful configuration loaded'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No successful configuration found'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showRecentReadsDialog() {
    if (lHistoryEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No recent reads available'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (oBuildContext) => AlertDialog(
        title: Text('Recent Reads (${lHistoryEntries.take(5).length})'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: lHistoryEntries.take(5).length,
            itemBuilder: (oBuildContext, iIndex) {
              final NfcHistoryEntry oEntry = lHistoryEntries[iIndex];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: oEntry.isSuccessful ? Colors.green : Colors.red,
                  radius: 16,
                  child: Icon(
                    oEntry.isSuccessful ? Icons.check : Icons.error,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                title: Text(
                  'AID: ${oEntry.metadata['aid']} | FID: ${oEntry.metadata['fid']}',
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTime(oEntry.timestamp),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      oEntry.rawData.length > 20 
                          ? '${oEntry.rawData.substring(0, 20)}...'
                          : oEntry.rawData,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.pop(oBuildContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (oBuildContext) => NfcDataDisplayScreen(
                        sRawData: oEntry.rawData,
                        mMetadata: oEntry.metadata,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(oBuildContext);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (oBuildContext) => NfcHistoryScreen(
                    historyEntries: lHistoryEntries,
                    onHistoryUpdated: _onHistoryUpdated,
                  ),
                ),
              );
            },
            child: const Text('View All History'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(oBuildContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime oDateTime) {
    final DateTime oNow = DateTime.now();
    final Duration oDifference = oNow.difference(oDateTime);

    if (oDifference.inMinutes < 1) {
      return 'Just now';
    } else if (oDifference.inHours < 1) {
      return '${oDifference.inMinutes}m ago';
    } else if (oDifference.inDays < 1) {
      return '${oDifference.inHours}h ago';
    } else {
      return '${oDateTime.day}/${oDateTime.month}/${oDateTime.year}';
    }
  }

  @override
  void dispose() {
    oFbpController.dispose();
    oLbpController.dispose();
    oAidController.dispose();
    oFidController.dispose();
    oKeyNumberController.dispose();
    oKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext oBuildContext) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text('NFC READER'),
        actions: [
          // Recent reads button
          if (lHistoryEntries.isNotEmpty)
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.access_time),
                  if (lHistoryEntries.length > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          '${lHistoryEntries.length > 9 ? '9+' : lHistoryEntries.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: _showRecentReadsDialog,
              tooltip: 'Recent Reads',
            ),
          // History button
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (oBuildContext) => NfcHistoryScreen(
                    historyEntries: lHistoryEntries,
                    onHistoryUpdated: _onHistoryUpdated,
                  ),
                ),
              );
            },
            tooltip: 'View History',
          ),
          // Help button
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () => TroubleshootingDialog.show(context),
            tooltip: 'Troubleshooting Guide',
          ),
        ],
      ), 
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              QuickActionsWidget(
                onLoadLastConfig: _loadLastSuccessfulConfig,
                onClearAll: _clearAllFields,
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: oFbpController,
                decoration: const InputDecoration(
                  labelText: 'FBP (First Byte Position)',
                  border: OutlineInputBorder(),
                  hintText: 'Enter FBP value',
                  helperText: 'Starting byte position for read operation',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: oLbpController,
                decoration: const InputDecoration(
                  labelText: 'LBP (Last Byte Position)',
                  border: OutlineInputBorder(),
                  hintText: 'Enter LBP value',
                  helperText: 'Ending byte position for read operation',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: oAidController,
                decoration: const InputDecoration(
                  labelText: 'AID (Application ID)',
                  border: OutlineInputBorder(),
                  hintText: 'Enter Application ID (e.g., 332211)',
                  helperText: '3-byte hex application identifier',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: oFidController,
                decoration: const InputDecoration(
                  labelText: 'FID (File ID)',
                  border: OutlineInputBorder(),
                  hintText: 'Enter File ID',
                  helperText: 'File identifier within the application',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: oKeyNumberController,
                decoration: const InputDecoration(
                  labelText: 'KEY NUMBER',
                  border: OutlineInputBorder(),
                  hintText: 'Enter key number (0-13)',
                  helperText: 'Authentication key number',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: oKeyController,
                decoration: const InputDecoration(
                  labelText: 'KEY',
                  border: OutlineInputBorder(),
                  hintText: 'Enter 32-character hex key',
                  helperText: 'AES authentication key (32 hex characters)',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: bIsLoading ? null : onButtonPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                    disabledForegroundColor: Colors.white,
                  ),
                  child: bIsLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'WAITING FOR CARD...',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      : const Text(
                          'START NFC READING',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}