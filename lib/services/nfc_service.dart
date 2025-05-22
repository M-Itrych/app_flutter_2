import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import '../utils/crypto_utils.dart';
import 'dart:typed_data';
import 'package:convert/convert.dart';

class NfcService {
  final CryptoUtils _cryptoUtils = CryptoUtils();
  

  Future<void> selectApp() async {
    await selectAppWithId("332211");
  }
  

  Future<void> selectAppWithId(String appId) async {
    try {

      if (!RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(appId)) {
        throw Exception("Invalid application ID format. Expected 3 bytes (6 hex chars)");
      }
      
      var tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 10),
        iosMultipleTagMessage: "Multiple tags found!",
        iosAlertMessage: "Scan your tag",
      );

      if (tag.type == NFCTagType.iso7816) {
        print("SELECT APP");
        // Construct the SELECT command with the provided app ID
        String selectCommand = "905A000003${appId}00";
        print("Send to card: $selectCommand");
        var selectAppResponse = await FlutterNfcKit.transceive(selectCommand);
        print("RECV FROM CARD: $selectAppResponse");
        
        // Check response status (last 4 characters)
        String status = selectAppResponse.substring(selectAppResponse.length - 4);
        if (status != "9100") {
          throw Exception("Failed to select application. Status: $status");
        }
        
        print("Application selected successfully");
      } else {
        throw Exception("Unsupported tag type: ${tag.type}");
      }
    } catch (e) {
      print("Error in selectAppWithId: $e");
      throw Exception("Failed to select application: $e");
    }
  }

  Future<void> authenticateWithAes() async {

    final keyBytes = Uint8List.fromList(List.filled(16, 0x11));
    await authenticateWithCustomKey(keyBytes);
  }

  Future<Uint8List> authenticateWithCustomKey(Uint8List keyBytes) async {
    if (keyBytes.length != 16) {
      throw Exception("Key must be exactly 16 bytes");
    }
    
    try {
      print("AUTH AES");
      print("Send to card: 90AA0000010100");
      String response = await FlutterNfcKit.transceive("90AA0000010100");
        
      print("Recv from card: $response");

      if (response.length < 36 || !response.endsWith("91AF")) {
        throw Exception("Card returned error status: ${response.substring(response.length - 4)}");
      }

      print("Key: ${hex.encode(keyBytes)}");

      String encRNDBhex = response.substring(0, 32);
      print("PICC-to->RPCD E(Kx, RNDB): $encRNDBhex");

      Uint8List encRNDB = Uint8List.fromList(hex.decode(encRNDBhex));

      Uint8List decryptedRNDB = _cryptoUtils.aesDecrypt(encRNDB, keyBytes, ivBytes: Uint8List(16));
      print("Plain RNDB: ${hex.encode(decryptedRNDB)}");

      Uint8List rndA = _cryptoUtils.generateRndA();
      print("Generated RndA HEX: ${hex.encode(rndA)}");

      Uint8List rotatedRNDB = _cryptoUtils.rotateLeft(decryptedRNDB);
      print("RNDB': ${hex.encode(rotatedRNDB)}");

      Uint8List RndARndB = Uint8List.fromList(rndA + rotatedRNDB);
      Uint8List encryptedRndAERndB = _cryptoUtils.aesEncrypt(RndARndB, keyBytes, ivBytes: encRNDB);
      
      Uint8List encryptedRndA = encryptedRndAERndB.sublist(0, 16);
      print("Encrypted RndA: ${hex.encode(encryptedRndA)}");
      
      Uint8List encryptedRotatedRndB = encryptedRndAERndB.sublist(16, 32);
      print("Encrypted RNDB`: ${hex.encode(encryptedRotatedRndB)}");

      String dataHex = hex.encode(encryptedRndAERndB).toUpperCase();

      String responseCommand = "90AF000020${dataHex}00";
      print("Send to card: $responseCommand");

      String response2 = await FlutterNfcKit.transceive(responseCommand);
      print("Recv from card: $response2");

      // Check if the response indicates an error
      if (response2.length < 36 || !response2.endsWith("9100")) {
        throw Exception("Card returned error status: ${response2.substring(response2.length - 4)}");
      }

      String encryptedRndAPrimeHex = response2.substring(0, 32);
      print("PICC-to->PCD E(Kx, RndA`): $encryptedRndAPrimeHex");

      Uint8List encryptedRndAPrime = Uint8List.fromList(hex.decode(encryptedRndAPrimeHex));
   
      Uint8List rotatedRNDA = _cryptoUtils.aesDecrypt(encryptedRndAPrime, keyBytes, ivBytes: encryptedRotatedRndB);
      print("plain RNDA': ${hex.encode(rotatedRNDA)}");
      
      Uint8List expectedRotatedA = _cryptoUtils.rotateLeft(rndA);
      print("Expected RNDA': ${hex.encode(expectedRotatedA)}");
        
      bool listsEqual = _verifyRotatedRNDA(rotatedRNDA, expectedRotatedA);
      
      if (!listsEqual) {
        print("RNDA' verification failed");
        print("Expected: ${hex.encode(expectedRotatedA)}");
        print("Actual: ${hex.encode(rotatedRNDA)}");
        throw Exception("Card authentication response verification failed");
      }
      
      Uint8List sessionKey = _generateSessionKey(rndA, decryptedRNDB);
      print("Session key: ${hex.encode(sessionKey)}");
      print("Authentication successful!");
      
      return sessionKey;

    } catch (e) {
      print("❌ Authentication error: $e");
      throw Exception("Authentication failed: $e");
    } finally {
      // Close the NFC connection
      try {
        await FlutterNfcKit.finish();
      } catch (e) {
        print("Error closing NFC connection: $e");
      }
    }
  }

  bool _verifyRotatedRNDA(Uint8List rotatedRNDA, Uint8List expectedRotatedA) {
    if (rotatedRNDA.length != expectedRotatedA.length) {
      return false;
    }
    
    for (int i = 0; i < rotatedRNDA.length; i++) {
      if (rotatedRNDA[i] != expectedRotatedA[i]) {
        return false;
      }
    }
    
    return true;
  }

  Uint8List _generateSessionKey(Uint8List rndA, Uint8List decryptedRNDB) {
    Uint8List sessionKey = Uint8List(16);
    // First 4 bytes of A
    sessionKey.setRange(0, 4, rndA, 0);
    // First 4 bytes of B
    sessionKey.setRange(4, 8, decryptedRNDB, 0);
    // Last 4 bytes of A
    sessionKey.setRange(8, 12, rndA, 12);
    // Last 4 bytes of B
    sessionKey.setRange(12, 16, decryptedRNDB, 12);
    
    return sessionKey;
  }

  Future<List<String>> getApplicationList() async {
    try {
      var tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 10),
        iosMultipleTagMessage: "Multiple tags found!",
        iosAlertMessage: "Scan your tag",
      );

      if (tag.type == NFCTagType.iso7816) {
        print("SELECT APP");
        var selectAppResponse = await FlutterNfcKit.transceive("906A000000");
        print("RECV FROM CARD: $selectAppResponse");
        String plainAppResponse = selectAppResponse.substring(0, selectAppResponse.length - 4);
        print("Plain App Response: $plainAppResponse");
        List<String> appList = RegExp(r'.{1,6}').allMatches(plainAppResponse)
            .map((match) => match.group(0)!)
            .toList();

        return appList;
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      await FlutterNfcKit.finish();
    }
    return <String>[];
  }

  Future<List<String>> getFilesList(String applicationId, String sessionKey) async {
  try {
    var tag = await FlutterNfcKit.poll(
      timeout: const Duration(seconds: 10),
      iosMultipleTagMessage: "Multiple tags found!",
      iosAlertMessage: "Scan your tag",
    );

    if (tag.type == NFCTagType.iso7816) {
      final selectAppResponse = await FlutterNfcKit.transceive("905A000003${applicationId}00");
      print("Select App Response: $selectAppResponse");
      
      if (!selectAppResponse.endsWith("9100")) {
        throw Exception("Failed to select application. Status: ${selectAppResponse.substring(selectAppResponse.length - 4)}");
      }

      print("GETTING FILE LIST");
      print("Send to card: 906F000000");
      String response = await FlutterNfcKit.transceive("906F000000");
      print("Recv from card: $response");
      
      // Check if response is successful
      if (!response.endsWith("9100")) {
        throw Exception("Failed to get file list. Status: ${response.substring(response.length - 4)}");
      }
      
      String fileIdsPart = response.substring(0, response.length - 4);
      List<String> fileIds = [];
      
      for (int i = 0; i < fileIdsPart.length; i += 2) {
        if (i + 2 <= fileIdsPart.length) {
          String fileId = fileIdsPart.substring(i, i + 2);
          fileIds.add(fileId);
        }
      }
      
      print("File IDs: $fileIds");
      return fileIds;
    } else {
      throw Exception("Unsupported tag type: ${tag.type}");
    }
  } catch (e) {
    print("Error getting file list: $e");
    throw Exception("Failed to get file list: $e");
  } finally {
    // Close the NFC connection
    try {
      await FlutterNfcKit.finish();
    } catch (e) {
      print("Error closing NFC connection: $e");
    }
  }
}
Future<String> readFile(String fileName, String sessionKey) async {
  try {
    NFCTag tag = await FlutterNfcKit.poll();

    print('Tag type: ${tag.type}, standard: ${tag.standard}');

    if (tag.type != NFCTagType.iso7816) {
      throw Exception("Unsupported tag type: ${tag.type}");

      
    }

    String response = await FlutterNfcKit.transceive("90BD00000703000000080000");
    print('Response: $response');

    await FlutterNfcKit.finish();

    return response;
  } catch (e) {
    print("Error: $e");
    await FlutterNfcKit.finish();
    return "";
  }
}
}