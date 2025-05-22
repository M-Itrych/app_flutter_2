import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import '../services/nfc_service.dart';
import './files_screen.dart';  // Import the correct file

class AuthenticationScreen extends StatefulWidget {
  final String applicationId;
  final String defaultKey;

  const AuthenticationScreen({
    Key? key, 
    required this.applicationId, 
    this.defaultKey = '',
  }) : super(key: key);

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  late final TextEditingController _keyController;
  final NfcService _nfcService = NfcService();
  bool _isAuthenticating = false;
  String _statusMessage = '';
  
  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.defaultKey);
  }
  
  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  void _navigateToFilesScreen(List<String> filesList, String sessionKey) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilesScreen(
          filesList: filesList,
          sessionKey: sessionKey,
        ),
      ),
    );
    
    // Handle the result if needed
    if (result != null && result['success'] == true) {
      setState(() {
        _statusMessage = "File read successful: ${result['fileName']}";
      });
      
      // Optionally show the file content or navigate to a file content view
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("File: ${result['fileName']}"),
          content: SingleChildScrollView(
            child: Text(result['content'] ?? 'No content'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _authenticateWithKey() async {
    final key = _keyController.text;
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an authentication key')),
      );
      return;
    }

    Uint8List keyBytes;
    try {
      // If the key is a hex string, decode it
      if (RegExp(r'^[0-9A-Fa-f]+$').hasMatch(key) && key.length == 32) {
        keyBytes = Uint8List.fromList(hex.decode(key));
      } else {
        // If it's not a valid hex string, show an error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid 16-byte hex key (32 hex characters)')),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid key format: $e')),
      );
      return;
    }
    
    setState(() {
      _isAuthenticating = true;
      _statusMessage = 'Authenticating...';
    });
    
    try {
      await _nfcService.selectAppWithId(widget.applicationId);

      final sessionKeyHex = await _nfcService.authenticateWithCustomKey(keyBytes);

      final filesList = await _nfcService.getFilesList(widget.applicationId, hex.encode(sessionKeyHex));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication successful. Found ${filesList.length} files.')),
      );

      _navigateToFilesScreen(filesList, hex.encode(sessionKeyHex));
      
    } catch (e) {
      setState(() {
        _statusMessage = 'Authentication failed: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication failed: $e')),
      );
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication Required'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Application ID display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Application ID:',
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.applicationId,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Status message if any
            if (_statusMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(_statusMessage),
              ),
              
            SizedBox(height: 24),
            
            // Authentication key input
            Text(
              'Enter authentication key (32 hex characters):',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _keyController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g., 11111111111111111111111111111111',
                prefixIcon: Icon(Icons.vpn_key),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () => _keyController.clear(),
                ),
              ),
              obscureText: true, // Hide the key input for security
            ),
            
            SizedBox(height: 24),
            
            // Authentication button
            Center(
              child: ElevatedButton(
                onPressed: _isAuthenticating ? null : _authenticateWithKey,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isAuthenticating 
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_open),
                        SizedBox(width: 8),
                        Text(
                          'Authenticate',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}