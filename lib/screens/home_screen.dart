import 'package:flutter/material.dart';
import '../services/nfc_service.dart';
import './authentication_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final NfcService _nfcService = NfcService();

  String _statusMessage = "Waiting for NFC scan...";
  bool _isScanning = false;
  List<String> _applicationList = [];

  Future<void> _getApplicationList() async {
    setState(() {
      _isScanning = true;
      _statusMessage = "Getting application list...";
    });

    // Simulate a delay for the operation
    List<String> appList = await _nfcService.getApplicationList();
    print("Application List: $appList");
    setState(() {
      _applicationList = appList;
    });

    setState(() {
      _isScanning = false;
      _statusMessage = "Application list retrieved!";
    });
  }

  void _navigateToAuthScreen(BuildContext context, String applicationId) async {

  String defaultKey = "11111111111111111111111111111111";
  
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AuthenticationScreen(
        applicationId: applicationId,
        defaultKey: defaultKey,
      ),
    ),
  );
  
  if (result == true) {
    setState(() {
      _statusMessage = "Authentication successful for: $applicationId";
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            color: Colors.grey[100],
            padding: EdgeInsets.all(8.0),
            width: double.infinity,
            child: Text(
              _statusMessage,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          
          // Application list section
          if (_applicationList.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Applications on NFC Tag:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _applicationList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.app_registration),
                    title: Text(_applicationList[index]),
                    onTap: () {
                      _navigateToAuthScreen(context, _applicationList[index]);
                      setState(() {
                        _applicationList = [];
                      _statusMessage = "Waiting for NFC scan...";
                      _isScanning = false;
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isScanning ? null : _getApplicationList,
        tooltip: 'Scan NFC Card',
        child: Icon(_isScanning ? Icons.hourglass_empty : Icons.nfc),
      ),
    );
  }
}