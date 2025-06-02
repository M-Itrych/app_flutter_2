class AppConstants {
  static const int iMaxHistoryEntries = 100;
  static const String sHistoryKey = 'nfc_history';
  
  // Default values
  static const String sDefaultFbp = '0';
  static const String sDefaultLbp = '8';
  static const String sDefaultAid = '332211';
  static const String sDefaultFid = '3';
  static const String sDefaultKeyNumber = '1';
  static const String sDefaultKey = '11111111111111111111111111111111';

  // DESFire status code to error message mapping
  static const Map<String, String> mDesfireStatusCodes = {
    '00': 'Success',
    '0C': 'No change',
    '0E': 'Out of EEPROM memory',
    '1C': 'Illegal command',
    '1E': 'Integrity error',
    '40': 'No such key',
    '6E': 'Error (ISO)',
    '7E': 'Length error - Invalid data length',
    '91': 'Permission denied - Insufficient privileges',
    '97': 'Crypto error - Authentication or encryption failed',
    '9D': 'Permission denied - Access denied',
    '9E': 'Parameter error - Invalid parameters',
    'A0': 'Application not found',
    'AE': 'Authentication error - Authentication failed',
    'AF': 'Additional frame (more data to follow)',
    'BE': 'Boundary error',
    'C1': 'Card integrity error',
    'CA': 'Command aborted',
    'CD': 'Card disabled',
    'CE': 'Count error',
    'DE': 'Duplicate error',
    'EE': 'EEPROM error',
    'F0': 'File not found',
    'F1': 'File integrity error',
  };
}
