import 'package:flutter/material.dart';
import '../services/nfc_service.dart';

class FilesScreen extends StatefulWidget {
  final List<String> filesList;
  final String sessionKey;

  const FilesScreen({
    Key? key, 
    required this.filesList, 
    required this.sessionKey,
  }) : super(key: key);

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final NfcService _nfcService = NfcService();
  String _statusMessage = "Select a file to read";
  bool _isScanning = false;
  late List<String> _filesList;

  @override
  void initState() {
    super.initState();
    // Initialize the local files list with the widget's filesList
    _filesList = List.from(widget.filesList);
  }

  void _selectFile(String fileName) async {
    setState(() {
      _isScanning = true;
      _statusMessage = "Reading file: $fileName...";
    });

    try {
      // Attempt to read the file using the session key
      final fileContent = await _nfcService.readFile(
        fileName,
        widget.sessionKey,
      );
      
      // Navigate back with the file content
      Navigator.pop(context, {
        'fileName': fileName,
        'content': fileContent,
        'success': true
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Error reading file: ${e.toString()}";
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select File"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.grey[100],
            padding: EdgeInsets.all(8.0),
            width: double.infinity,
            child: Text(
              _statusMessage,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Icon(Icons.vpn_key, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Session Key:', 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)
                          ),
                          Text(
                            widget.sessionKey.length > 8 
                              ? "${widget.sessionKey.substring(0, 4)}...${widget.sessionKey.substring(widget.sessionKey.length - 4)}" 
                              : widget.sessionKey,
                            style: TextStyle(fontSize: 14)
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Files list section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Available Files:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          
          _isScanning 
            ? Center(child: CircularProgressIndicator())
            : _filesList.isEmpty 
              ? Center(child: Text('No files found'))
              : Expanded(
                  child: ListView.builder(
                    itemCount: _filesList.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: ListTile(
                          leading: Icon(Icons.insert_drive_file, color: Colors.amber),
                          title: Text(_filesList[index]),
                          subtitle: Text('Tap to read file contents'),
                          trailing: Icon(Icons.chevron_right),
                          onTap: _isScanning ? null : () {
                            _selectFile(_filesList[index]);
                          },
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}