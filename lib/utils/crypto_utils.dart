
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/export.dart';
import 'package:convert/convert.dart';

class CryptoUtils {
  Uint8List aesEncrypt(Uint8List data, Uint8List keyBytes, {required Uint8List ivBytes}) {
    final key = encrypt.Key(keyBytes);
    final iv = encrypt.IV(ivBytes);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: null),
    );
    final encrypted = encrypter.encryptBytes(data, iv: iv);
    return Uint8List.fromList(encrypted.bytes);
  }

  Uint8List aesDecrypt(Uint8List data, Uint8List keyBytes, {required Uint8List ivBytes}) {
    final key = encrypt.Key(keyBytes);
    final iv = encrypt.IV(ivBytes);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: null),
    );
    final decrypted = encrypter.decryptBytes(encrypt.Encrypted(data), iv: iv);
    return Uint8List.fromList(decrypted);
  }

  Uint8List generateRndA() {
    final rnd = Random.secure();
    return Uint8List.fromList(List.generate(16, (_) => rnd.nextInt(256)));
  }

  Uint8List rotateLeft(Uint8List data) {
    return Uint8List.fromList([...data.sublist(1), data[0]]);
  }
}

class AESCMACHelper {
  /// Computes AES-CMAC using PointyCastle
  /// 
  /// [key] - The AES key as a hex string
  /// [data] - The input data as a hex string
  /// Returns the CMAC as a hex string
  static String computeAESCMAC(String hexKey, String hexData) {
    try {
      // Convert hex strings to bytes
      final keyBytes = Uint8List.fromList(hex.decode(hexKey));
      final dataBytes = Uint8List.fromList(hex.decode(hexData));
      
      // Create AES-CMAC cipher
      final cmac = CMac(BlockCipher('AES'), 64); // 64 bits = 8 bytes for MAC length
      
      // Initialize with key
      final keyParam = KeyParameter(keyBytes);
      cmac.init(keyParam);
      
      // Process the data
      cmac.update(dataBytes, 0, dataBytes.length);
      
      // Get the MAC
      final macBytes = Uint8List(cmac.macSize);
      cmac.doFinal(macBytes, 0);
      
      // Convert to hex string
      return hex.encode(macBytes).toUpperCase();
      
    } catch (e) {
      throw Exception('Error computing AES-CMAC: $e');
    }
  }
  
  /// Alternative method with explicit MAC size (128-bit/16-byte MAC)
  static String computeAESCMAC128(String hexKey, String hexData) {
    try {
      final keyBytes = Uint8List.fromList(hex.decode(hexKey));
      final dataBytes = Uint8List.fromList(hex.decode(hexData));
      
      // Create AES-CMAC with 128-bit MAC size
      final cmac = CMac(BlockCipher('AES'), 128); // 128 bits = 16 bytes
      
      final keyParam = KeyParameter(keyBytes);
      cmac.init(keyParam);
      
      cmac.update(dataBytes, 0, dataBytes.length);
      
      final macBytes = Uint8List(cmac.macSize);
      cmac.doFinal(macBytes, 0);
      
      return hex.encode(macBytes).toUpperCase();
      
    } catch (e) {
      throw Exception('Error computing AES-CMAC-128: $e');
    }
  }
}