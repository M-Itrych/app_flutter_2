class DataFormatter {
  // Convert hex string to ASCII string
  static String hexToAscii(String hexData) {
    try {
      String cleanHex = hexData.replaceAll(' ', '').replaceAll('\n', '');
      String ascii = '';
      
      for (int index = 0; index < cleanHex.length; index += 2) {
        if (index + 1 < cleanHex.length) {
          String hexPair = cleanHex.substring(index, index + 2);
          int charCode = int.parse(hexPair, radix: 16);
          ascii += String.fromCharCode(charCode);
        }
      }
      return ascii;
    } catch (error) {
      return 'Cannot convert to ASCII';
    }
  }

  // Format hex data with spaces and line breaks
  static String formatBinaryData(String data) {
    String cleanData = data.replaceAll(' ', '').replaceAll('\n', '');
    String formatted = '';
    
    for (int index = 0; index < cleanData.length; index += 2) {
      if (index + 1 < cleanData.length) {
        formatted += cleanData.substring(index, index + 2) + ' ';
        if ((index / 2 + 1) % 8 == 0) {
          formatted += '\n';
        }
      }
    }
    return formatted.trim();
  }

  // Format timestamp string to readable format
  static String formatTimestamp(String timestamp) {
    try {
      DateTime dateTime = DateTime.parse(timestamp);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (error) {
      return timestamp;
    }
  }

  // Create formatted hex dump string
  static String createHexDump(String rawData) {
    String cleanData = rawData.replaceAll(' ', '').replaceAll('\n', '');

    if (cleanData.isEmpty) {
      return 'No data to display';
    }

    String hexDump = '';
    const int bytesPerLine = 16;
    
    for (int index = 0; index < cleanData.length; index += bytesPerLine * 2) {
      String offset = (index ~/ 2).toRadixString(16).padLeft(8, '0').toUpperCase();
      String hexLine = '';
      String asciiLine = '';
      
      for (int byteIndex = 0; byteIndex < bytesPerLine && index + (byteIndex * 2) < cleanData.length; byteIndex++) {
        int charIndex = index + (byteIndex * 2);
        
        if (charIndex + 1 < cleanData.length) {
          String hexPair = cleanData.substring(charIndex, charIndex + 2);
          
          if (byteIndex == 8) {
            hexLine += ' ';
          }
          hexLine += '$hexPair ';
          
          try {
            int charCode = int.parse(hexPair, radix: 16);
            asciiLine += String.fromCharCode(charCode);
          } catch (error) {
            asciiLine += '?';
          }
        } else if (charIndex < cleanData.length) {
          String singleHex = cleanData.substring(charIndex, charIndex + 1);
          hexLine += '$singleHex  ';
          asciiLine += '?';
        }
      }
      
      String paddedHexLine = hexLine.padRight(49);
      hexDump += '$offset: $paddedHexLine |$asciiLine|\n';
    }
    
    int totalBytes = cleanData.length ~/ 2;
    hexDump += '\n';
    hexDump += '=' * 80 + '\n';
    hexDump += 'Total bytes: $totalBytes (0x${totalBytes.toRadixString(16).toUpperCase()})\n';
    
    return hexDump.trim();
  }
}
