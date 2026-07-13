import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'crypto.dart';

class ApiException implements Exception {
  final String message;
  final int status;
  ApiException(this.message, this.status);
  @override
  String toString() => message;
}

class Http {
  static SharedPreferences? _sp;
  static final Map<String, dynamic> _getCache = {};

  static Future<void> init() async {
    _sp = await SharedPreferences.getInstance();
  }

  static String get lang => _sp?.getString('lang') ?? 'zh';
  static set lang(String v) => _sp?.setString('lang', v);
  static String? get token => _sp?.getString('token');
  static Future<void> setToken(String? t) async {
    if (t == null) {
      await _sp?.remove('token');
    } else {
      await _sp?.setString('token', t);
    }
  }

  static Uri _uri(String path, Map<String, dynamic>? params) {
    final qp = <String, String>{'lang': lang};
    params?.forEach((k, v) {
      if (v != null && '$v'.isNotEmpty) qp[k] = '$v';
    });
    return Uri.parse('${Config.apiBase}$path').replace(queryParameters: qp);
  }

  static Map<String, String> _headers({bool json = false}) {
    final h = <String, String>{'Accept': 'application/json'};
    if (json) h['Content-Type'] = 'application/json';
    final t = token;
    if (t != null && t.isNotEmpty) h['Authorization'] = 'Bearer $t';
    return h;
  }

  static dynamic _decode(String body) {
    if (body.isEmpty) return null;
    dynamic j;
    try {
      j = jsonDecode(body);
    } catch (_) {
      return body;
    }
    if (j is Map && j.containsKey('_e')) {
      try {
        return Aes.decryptEnvelope(j['_e'] as String);
      } catch (_) {
        return j;
      }
    }
    return j;
  }

  static Future<dynamic> get(String path, {Map<String, dynamic>? params, bool cache = true}) async {
    final key = '$path::${params ?? {}}::$lang';
    if (cache && _getCache.containsKey(key)) return _getCache[key];
    final res = await http
        .get(_uri(path, params), headers: _headers())
        .timeout(const Duration(seconds: 15));
    final body = _decode(res.body);
    if (res.statusCode == 401) await setToken(null);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(_msg(body, res.statusCode), res.statusCode);
    }
    if (cache) _getCache[key] = body;
    return body;
  }

  static Future<dynamic> post(String path, Map<String, dynamic> data) async {
    final res = await http
        .post(_uri(path, null), headers: _headers(json: true), body: jsonEncode(data))
        .timeout(const Duration(seconds: 15));
    final body = _decode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(_msg(body, res.statusCode), res.statusCode);
    }
    return body;
  }

  static String _msg(dynamic body, int status) {
    if (body is Map && body['message'] != null) return '${body['message']}';
    return 'HTTP $status';
  }

  static void clearCache() => _getCache.clear();
}
