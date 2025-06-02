import 'package:flutter/material.dart';

class TroubleshootingDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext buildContext) {
        return AlertDialog(
          title: const Text('DESFire Troubleshooting Guide'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTroubleshootingSection(
                  'Authentication Errors (91, 9D, AE)',
                  [
                    'Verify the authentication key is correct',
                    'Check if key number exists (0-13 for applications)',
                    'Ensure proper key format (32 hex chars for AES)',
                    'Try authenticating with master key first',
                  ],
                ),
                _buildTroubleshootingSection(
                  'Application/File Errors (A0, F0)',
                  [
                    'Check if Application ID exists on card',
                    'Verify File ID exists in selected application',
                    'Use correct 3-byte AID format (e.g., 332211)',
                    'Ensure application is properly selected',
                  ],
                ),
                _buildTroubleshootingSection(
                  'Data/Parameter Errors (7E, 9E, 1C)',
                  [
                    'Verify FBP (First Byte Position) ≤ LBP (Last Byte Position)',
                    'Check data length doesn\'t exceed file size',
                    'Ensure parameters are within valid ranges',
                    'Use correct numeric formats for all inputs',
                  ],
                ),
                _buildTroubleshootingSection(
                  'Card Communication Issues',
                  [
                    'Keep card steady during operation',
                    'Ensure card supports DESFire EV1/EV2',
                    'Check NFC is enabled on device',
                    'Try repositioning the card',
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(buildContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildTroubleshootingSection(String title, List<String> tips) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 4),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: Colors.grey[600])),
                Expanded(child: Text(tip, style: const TextStyle(fontSize: 13))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
