import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as cr;
import 'package:encrypt/encrypt.dart' as enc;
import '../config.dart';

// 解密后端 AES-256-CBC 响应信封 {_e: base64(iv|ciphertext)}。
class Aes {
  static final _key = enc.Key(_hex(Config.encryptKeyHex));
  static final _encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));

  static Uint8List _hex(String h) {
    final out = Uint8List(h.length ~/ 2);
    for (var i = 0; i < h.length; i += 2) {
      out[i ~/ 2] = int.parse(h.substring(i, i + 2), radix: 16);
    }
    return out;
  }

  static dynamic decryptEnvelope(String b64) {
    final raw = base64.decode(b64);
    final iv = enc.IV(Uint8List.fromList(raw.sublist(0, 16)));
    final ct = enc.Encrypted(Uint8List.fromList(raw.sublist(16)));
    final plain = _encrypter.decrypt(ct, iv: iv);
    return jsonDecode(plain);
  }
}

// HLS 签名用 md5
String md5Hex(String s) => cr.md5.convert(utf8.encode(s)).toString();
