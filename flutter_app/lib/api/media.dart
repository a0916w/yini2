import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api.dart';
import 'crypto.dart';

// 站点配置驱动的媒体地址解析(与前台一致):
//  封面: cover_base_url -> encrypt_cover_base_url,再取 `${url}.txt`(base64 图)
//  HLS : hls_base_url -> encrypt_hls_base_url,追加 ?wsSecret=md5(key+path+time)&wsTime
class Media {
  static Map? _settings;
  static Future<Map>? _pending;
  static final Map<String, Uint8List?> _coverCache = {};
  static final Map<String, ({String signed, int exp})> _hlsCache = {};

  static Future<Map> settings() {
    if (_settings != null) return Future.value(_settings!);
    return _pending ??= Api.siteSettings().then((s) {
      _settings = s;
      return s;
    }).catchError((_) => <String, dynamic>{});
  }

  static String _strip(String? s) => (s ?? '').replaceAll(RegExp(r'/+$'), '');

  static Future<Uint8List?> resolveCover(String? url) async {
    if (url == null || url.isEmpty) return null;
    if (_coverCache.containsKey(url)) return _coverCache[url];
    final s = await settings();
    final coverBase = s['cover_base_url'] as String?;
    final encBase = s['encrypt_cover_base_url'] as String?;
    Uint8List? bytes;
    try {
      if (encBase != null && coverBase != null && url.startsWith(coverBase)) {
        final swapped = url.replaceFirst(_strip(coverBase), _strip(encBase));
        final res = await http.get(Uri.parse('$swapped.txt')).timeout(const Duration(seconds: 12));
        final txt = res.body;
        final i = txt.indexOf('base64,');
        if (i >= 0) bytes = base64.decode(txt.substring(i + 7).trim());
      } else {
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
        if (res.statusCode == 200) bytes = res.bodyBytes;
      }
    } catch (_) {
      bytes = null;
    }
    _coverCache[url] = bytes;
    return bytes;
  }

  static Future<String> signHls(String url) async {
    if (url.isEmpty) return url;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final c = _hlsCache[url];
    if (c != null && c.exp - now > 600) return c.signed;
    final s = await settings();
    final hlsBase = s['hls_base_url'] as String?;
    final encBase = s['encrypt_hls_base_url'] as String?;
    final key = s['encrypt_hls_key'] as String?;
    if (encBase == null || key == null) return url;
    var target = url;
    if (hlsBase != null && url.startsWith(hlsBase)) {
      target = url.replaceFirst(_strip(hlsBase), _strip(encBase));
    }
    try {
      final wsTime = now + 7200;
      final u = Uri.parse(target);
      final secret = md5Hex('$key${u.path}$wsTime');
      final signed = '${u.origin}${u.path}?wsSecret=$secret&wsTime=$wsTime';
      _hlsCache[url] = (signed: signed, exp: wsTime);
      return signed;
    } catch (_) {
      return target;
    }
  }
}
