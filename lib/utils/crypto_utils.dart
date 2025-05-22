
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;

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