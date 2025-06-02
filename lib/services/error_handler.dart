import '../constants/app_constants.dart';

class ErrorHandler {
  // Check if the result contains DESFire error status codes
  static bool containsErrorStatusCode(String text) {
    final String upperText = text.toUpperCase();
    
    final List<String> errorCodes = [
      '0C', '0E', '1C', '1E', '40', '6E', '7E', '91', '97', 
      '9D', '9E', 'A0', 'AE', 'BE', 'C1', 'CA', 'CD', 'CE', 
      'DE', 'EE', 'F0', 'F1'
    ];
    
    for (final String code in errorCodes) {
      if (upperText.contains(code)) {
        return true;
      }
    }
    return false;
  }

  // Check if result contains error indicators
  static bool isErrorResult(String result) {
    return result.toLowerCase().contains('error') || 
           result.toLowerCase().contains('exception') ||
           containsErrorStatusCode(result);
  }

  // Parse NFC error messages and extract status codes
  static String parseNfcError(String errorMessage) {
    final RegExp statusCodeRegex = RegExp(r'([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})?');
    final Iterable<RegExpMatch> matches = statusCodeRegex.allMatches(errorMessage.toUpperCase());
    
    List<String> interpretedErrors = [];
    
    for (final RegExpMatch match in matches) {
      final String? code1 = match.group(1);
      final String? code2 = match.group(2);
      
      if (code1 != null && AppConstants.mDesfireStatusCodes.containsKey(code1)) {
        interpretedErrors.add('$code1: ${AppConstants.mDesfireStatusCodes[code1]}');
      }
      
      if (code2 != null && AppConstants.mDesfireStatusCodes.containsKey(code2)) {
        interpretedErrors.add('$code2: ${AppConstants.mDesfireStatusCodes[code2]}');
      }
    }
    
    if (interpretedErrors.isNotEmpty) {
      return '${interpretedErrors.join('\n')}\n\nOriginal error: $errorMessage';
    }
    
    return '$errorMessage\n\nTroubleshooting:\n'
           '• Ensure the card is properly positioned\n'
           '• Check if the card supports DESFire protocol\n'
           '• Verify authentication parameters\n'
           '• Make sure the card is not write-protected';
  }

  // Get solution suggestion for specific error codes
  static String getErrorSolution(String statusCode) {
    switch (statusCode.toUpperCase()) {
      case '91':
      case '9D':
        return 'Solution: Check authentication credentials and key permissions';
      case 'AE':
        return 'Solution: Verify the authentication key and try re-authenticating';
      case '97':
        return 'Solution: Check encryption settings and key format';
      case 'A0':
        return 'Solution: Ensure the Application ID (AID) exists on the card';
      case 'F0':
        return 'Solution: Check if the File ID (FID) exists in the selected application';
      case '40':
        return 'Solution: Verify the key number exists for this application';
      case '7E':
        return 'Solution: Check data length parameters (FBP, LBP values)';
      case '1C':
        return 'Solution: Verify command parameters and card state';
      default:
        return 'Solution: Check card connection and try again';
    }
  }
}
