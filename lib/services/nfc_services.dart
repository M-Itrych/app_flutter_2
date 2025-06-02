import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import '../utils/crypto_utils.dart';
import 'dart:typed_data';
import 'package:convert/convert.dart';

class DesfireServices {
  final CryptoUtils oCryptoUtils = CryptoUtils();
  final bool bDebugMode;

  DesfireServices({this.bDebugMode = true});

  void _debugPrint(String sMessage) {
    if (bDebugMode) {
      print(sMessage);
    }
  }

  Future<bool> isNfcAvailable() async {
    try {
      NFCAvailability eAvailability = await FlutterNfcKit.nfcAvailability;
      return eAvailability == NFCAvailability.available;
    } catch (eError) {
      _debugPrint("Error checking NFC availability: $eError");
      return false;
    }
  }

  bool _verifyRotatedRNDA(Uint8List uRotatedRNDA, Uint8List uExpectedRotatedA) {
    if (uRotatedRNDA.length != uExpectedRotatedA.length) {
      return false;
    }
    for (int iIndex = 0; iIndex < uRotatedRNDA.length; iIndex++) {
      if (uRotatedRNDA[iIndex] != uExpectedRotatedA[iIndex]) {
        return false;
      }
    }
    return true;
  }

  Uint8List _generateSessionKey(Uint8List uRndA, Uint8List uDecryptedRNDB) {
    Uint8List uSessionKey = Uint8List(16);
    uSessionKey.setRange(0, 4, uRndA, 0);
    uSessionKey.setRange(4, 8, uDecryptedRNDB, 0);
    uSessionKey.setRange(8, 12, uRndA, 12);
    uSessionKey.setRange(12, 16, uDecryptedRNDB, 12);
    return uSessionKey;
  }

  void _validateHexString(String hexString, String paramName, {int? expectedLength}) {
    if (hexString.isEmpty) {
      throw ArgumentError('$paramName cannot be empty');
    }
    if (!RegExp(r'^[0-9A-Fa-f]+$').hasMatch(hexString)) {
      throw ArgumentError('$paramName must contain only hexadecimal characters');
    }
    if (expectedLength != null && hexString.length != expectedLength) {
      throw ArgumentError('$paramName must be exactly $expectedLength characters long');
    }
  }

  Future<Uint8List> _authenticateWithApp(String sKey, String sKeyNumber) async {
    try {
      _validateHexString(sKey, 'Key', expectedLength: 32);
      _validateHexString(sKeyNumber, 'Key number');

      if (sKey.length != 32) {
        throw Exception("Key must be exactly 32 hex characters (16 bytes)");
      }

      Uint8List uKey = Uint8List.fromList(hex.decode(sKey));

      _debugPrint("[DESFireServices: AppAuth] Starting authentication in app context...");
      _debugPrint("[DesfireServices: AppAuth] Send to card: 90AA0000010${sKeyNumber}00");

      String sResponse = await FlutterNfcKit.transceive("90AA0000010${sKeyNumber}00");
      _debugPrint("[DesfireServices: AppAuth] Recv from card: $sResponse");

      if (sResponse.length < 36 || !sResponse.endsWith("91AF")) {
        throw Exception("Card returned error status: ${sResponse.substring(sResponse.length - 4)}");
      }

      String sEncryptedRNDB = sResponse.substring(0, 32);
      _debugPrint("[DesfireServices: AppAuth] PICC-to->RPCD E(Kx, RNDB): $sEncryptedRNDB");

      Uint8List uEncryptedRNDB = Uint8List.fromList(hex.decode(sEncryptedRNDB));

      Uint8List uDecryptedRNDB = oCryptoUtils.aesDecrypt(uEncryptedRNDB, uKey, ivBytes: Uint8List(16));
      _debugPrint("[DesfireServices: AppAuth] Plain RNDB HEX: ${hex.encode(uDecryptedRNDB)}");

      Uint8List uRNDA = oCryptoUtils.generateRndA();
      _debugPrint("[DesfireServices: AppAuth] Generated RndA HEX: ${hex.encode(uRNDA)}");

      Uint8List uRotatedRNDB = oCryptoUtils.rotateLeft(uDecryptedRNDB);
      _debugPrint("[DesfireServices: AppAuth] RNDB': ${hex.encode(uRotatedRNDB)}");

      Uint8List uRNDARNDB = Uint8List.fromList(uRNDA + uRotatedRNDB);
      Uint8List uEncryptedRNDARNDB = oCryptoUtils.aesEncrypt(uRNDARNDB, uKey, ivBytes: uEncryptedRNDB);

      Uint8List uEncryptedRNDA = uEncryptedRNDARNDB.sublist(0, 16);
      _debugPrint("[DesfireServices: AppAuth] Encrypted RndA: ${hex.encode(uEncryptedRNDA)}");

      Uint8List uEncryptedRotatedRNDB = uEncryptedRNDARNDB.sublist(16, 32);
      _debugPrint("[DesfireServices: AppAuth] Encrypted RNDB`: ${hex.encode(uEncryptedRotatedRNDB)}");

      String sDataHex = hex.encode(uEncryptedRNDARNDB).toUpperCase();

      String sResponseCommand = "90AF000020${sDataHex}00";
      _debugPrint("[DesfireServices: AppAuth] Send to card: $sResponseCommand");

      String sCardResponse = await FlutterNfcKit.transceive(sResponseCommand);
      _debugPrint("[DesfireServices: AppAuth] Recv from card: $sCardResponse");

      if (sCardResponse.length < 36 || !sCardResponse.endsWith("9100")) {
        throw Exception("Card returned error status: ${sCardResponse.substring(sCardResponse.length - 4)}");
      }

      String sEncryptedRNDAPrime = sCardResponse.substring(0, 32);
      _debugPrint("[DesfireServices: AppAuth] PICC-to->PCD E(Kx, RndA`): $sEncryptedRNDAPrime");

      Uint8List uEncryptedRNDAPrime = Uint8List.fromList(hex.decode(sEncryptedRNDAPrime));

      Uint8List uRotatedRNDA = oCryptoUtils.aesDecrypt(uEncryptedRNDAPrime, uKey, ivBytes: uEncryptedRotatedRNDB);

      Uint8List uExpectedRotatedA = oCryptoUtils.rotateLeft(uRNDA);

      bool bListsEqual = _verifyRotatedRNDA(uRotatedRNDA, uExpectedRotatedA);

      if (!bListsEqual) {
        _debugPrint("RNDA' verification failed");
        _debugPrint("Expected: ${hex.encode(uExpectedRotatedA)}");
        _debugPrint("Actual: ${hex.encode(uRotatedRNDA)}");
        throw Exception("Card authentication response verification failed");
      }

      Uint8List uSessionKey = _generateSessionKey(uRNDA, uDecryptedRNDB);
      _debugPrint("[DesfireServices: AppAuth] Session key: ${hex.encode(uSessionKey)}");
      _debugPrint("[DesfireServices: AppAuth] Authentication successful!");

      return uSessionKey;

    } catch (eError) {
      if (eError is ArgumentError) {
        _debugPrint("❌ Invalid parameter: $eError");
        rethrow;
      }
      _debugPrint("❌ App Authentication error: $eError");
      rethrow;
    }
  }

  Future<String> _desfireGetData(
    String sFbp,
    String sLbp,
    String sAid,
    String sFid,
    String sKey,
    String sKeyNumber
  ) async {
    try {
      // Add input validation
      _validateHexString(sFbp, 'First byte position');
      _validateHexString(sLbp, 'Last byte position');
      _validateHexString(sAid, 'Application ID', expectedLength: 6);
      _validateHexString(sFid, 'File ID');
      _validateHexString(sKey, 'Key', expectedLength: 32);
      _validateHexString(sKeyNumber, 'Key number');

      // Add timeout for card operations
      String sSelectAppResponse = await FlutterNfcKit.transceive("905A000003${sAid}00")
          .timeout(Duration(seconds: 5), onTimeout: () {
        throw TimeoutException('Card operation timed out during app selection');
      });
      
      _debugPrint("905A000003${sAid}00");
      _debugPrint("[DesfireServices: GetData] Select app response: $sSelectAppResponse");
      
      if (!sSelectAppResponse.endsWith("9100")) {
        throw Exception("Failed to select application: ${sSelectAppResponse.substring(sSelectAppResponse.length - 4)}");
      }

      _debugPrint("[DesfireServices: GetData] Authenticating with selected application...");
      Uint8List uSessionKey = await _authenticateWithApp(sKey, sKeyNumber);
      _debugPrint("[DesfireServices: GetData] Authentication successful, session key: ${hex.encode(uSessionKey)}");

      int iOffset = int.parse(sFbp, radix: 16);
      int iLength = int.parse(sLbp, radix: 16);
      int iFileID = int.parse(sFid, radix: 16);

      int iActualOffset;
      int iActualLength;

      if (iOffset > iLength) {
        iActualOffset = iLength;
        iActualLength = iOffset;
      } else {
        iActualOffset = iOffset;
        iActualLength = iLength;
      }

      String sOffsetHex = iActualOffset.toRadixString(16).padRight(5, '0').padLeft(6, '0');
      String sLengthHex = iActualLength.toRadixString(16).padRight(5, '0').padLeft(6, '0');
      String sFileIDHex = iFileID.toRadixString(16).padLeft(2, '0');
      _debugPrint("Offset: $sOffsetHex, Length: $sLengthHex, FileID: $sFileIDHex");

      // Optimize string building
      final StringBuffer commandBuffer = StringBuffer();
      commandBuffer.write("90BD000007");
      commandBuffer.write(sFileIDHex);
      commandBuffer.write(sOffsetHex);
      commandBuffer.write(sLengthHex);
      commandBuffer.write("00");
      String sCommand = commandBuffer.toString();

      _debugPrint("[DesfireServices: GetData] Send to card: $sCommand");

      String sResponse = await FlutterNfcKit.transceive(sCommand)
          .timeout(Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Card operation timed out during data read');
      });
      
      _debugPrint("[DesfireServices: GetData] Response: $sResponse");

      // Validate response length before processing
      if (sResponse.length < 6) {
        throw Exception("Invalid response length: ${sResponse.length}");
      }

      String sSessionKeyHex = hex.encode(uSessionKey);
      String sCommandData = "BD${sFileIDHex}${sOffsetHex}${sLengthHex}";
      _debugPrint("[DesfireServices: GetData] Command data for CMAC: $sCommandData");
      
      String sIV = AESCMACHelper.computeAESCMAC128(sSessionKeyHex, sCommandData);
      _debugPrint("[DesfireServices: GetData] IV for decryption: $sIV");

      Uint8List uResponseData = Uint8List.fromList(hex.decode(sResponse.substring(0, sResponse.length - 4)));
      Uint8List uIvBytes = Uint8List.fromList(hex.decode(sIV));
      Uint8List uDecodedResponse = oCryptoUtils.aesDecrypt(uResponseData, uSessionKey, ivBytes: uIvBytes);
      _debugPrint("[DesfireServices: GetData] Decrypted response: ${hex.encode(uDecodedResponse)}");

      String sHexString = hex.encode(uDecodedResponse).substring(0, (iActualLength - iActualOffset) * 2).toUpperCase();

      // Optimize hex string reversal if needed
      if (iOffset > iLength) {
        final List<String> hexPairs = <String>[];
        for (int i = 0; i < sHexString.length; i += 2) {
          hexPairs.add(sHexString.substring(i, i + 2));
        }
        return hexPairs.reversed.join('');
      } else {
        return sHexString;
      }

    } on TimeoutException catch (eTimeout) {
      _debugPrint("❌ Timeout error: $eTimeout");
      rethrow;
    } on ArgumentError catch (eArgument) {
      _debugPrint("❌ Invalid parameter: $eArgument");
      rethrow;
    } catch (eError) {
      _debugPrint("❌ GetData error: $eError");
      rethrow;
    }
  }

  Future<String> processDesfire(
    String sFbp, 
    String sLbp, 
    String sAid, 
    String sFid, 
    String sKeyNumber, 
    String sKey
  ) async {
    try {
      // Add input validation at entry point
      if (sFbp.isEmpty || sLbp.isEmpty || sAid.isEmpty || 
          sFid.isEmpty || sKeyNumber.isEmpty || sKey.isEmpty) {
        throw ArgumentError("All parameters must be non-empty");
      }

      if (!await isNfcAvailable()) {
        throw Exception("NFC is not available on this device");
      }

      _debugPrint("[DesfireServices] Starting NFC polling...");
      NFCTag oTag = await FlutterNfcKit.poll(
        timeout: Duration(seconds: 10),
        iosMultipleTagMessage: "Multiple tags found!",
        iosAlertMessage: "Scan your DESFire card",
      );
      
      _debugPrint("[DesfireServices] Tag detected: ${oTag.type}");
      
      if (oTag.type != NFCTagType.iso7816) {
        throw Exception("Unsupported tag type: ${oTag.type}. Expected ISO7816 (DESFire)");
      }

      _debugPrint("[DesfireServices] Tag standard: ${oTag.standard}");
      _debugPrint("[DesfireServices] Tag ID: ${oTag.id}");

      String sResponse = await _desfireGetData(sFbp, sLbp, sAid, sFid, sKey, sKeyNumber);
      _debugPrint("[DesfireServices: GetData] Final Response: $sResponse");

      return sResponse;
      
    } on ArgumentError catch (eArgument) {
      _debugPrint("❌ Invalid parameter: $eArgument");
      return "Error: Invalid parameter - $eArgument";
    } on TimeoutException catch (eTimeout) {
      _debugPrint("❌ Operation timeout: $eTimeout");
      return "Error: Operation timed out - $eTimeout";
    } catch (eError) {
      _debugPrint("❌ DESFire process error: $eError");
      return "Error: $eError";
    } finally {
      try {
        await FlutterNfcKit.finish(iosAlertMessage: "Scan completed");
        _debugPrint("[DesfireServices] NFC session finished");
      } catch (eFinishError) {
        _debugPrint("❌ Error finishing NFC session: $eFinishError");
      }
    }
  }
}

// Add custom exception for timeout handling
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => 'TimeoutException: $message';
}