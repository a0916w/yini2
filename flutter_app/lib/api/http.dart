import 'dart:convert';
import 'package:flutter/foundation.dart' show compute;
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
  // 两层缓存:内存(秒取)+ 磁盘(冷启动秒开),SWR:命中立即返回,过期后台静默刷新
  static final Map<String, dynamic> _getCache = {};
  static final Map<String, int> _cacheAt = {}; // key -> 写入时间(ms)
  static final Map<String, Future<dynamic>> _inflight = {};
  static const _ttlMs = 10 * 60 * 1000; // 超过 10 分钟视为过期,返回旧数据同时后台刷新

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

  // AES 解密挪到后台 isolate,避免大响应解密卡 UI 线程
  static Future<dynamic> _decode(String body) async {
    if (body.isEmpty) return null;
    dynamic j;
    try {
      j = jsonDecode(body);
    } catch (_) {
      return body;
    }
    if (j is Map && j.containsKey('_e')) {
      try {
        return await compute(decryptEnvelopeIsolate, j['_e'] as String);
      } catch (_) {
        return j;
      }
    }
    return j;
  }

  static Future<dynamic> get(String path, {Map<String, dynamic>? params, bool cache = true, bool fresh = false}) {
    final key = '$path::${params ?? {}}::$lang';
    if (cache && !fresh) {
      // 1) 内存命中:立即返回;过期则后台静默刷新(SWR)
      if (_getCache.containsKey(key)) {
        if (_stale(key)) _revalidate(path, params, key);
        return Future.value(_getCache[key]);
      }
      // 2) 磁盘命中(冷启动):秒开,同时后台刷新
      final disk = _diskRead(key);
      if (disk != null) {
        _getCache[key] = disk;
        if (_stale(key)) _revalidate(path, params, key);
        return Future.value(disk);
      }
    }
    // 3) 未命中/强制刷新:走网络(进行中请求去重)
    if (cache && _inflight.containsKey(key)) return _inflight[key]!;
    final f = _fetch(path, params, cache, key);
    if (cache) {
      _inflight[key] = f;
      _settle(f, key); // 吞掉清理链上的错误;调用方仍从 f 收到原错误
    }
    return f;
  }

  // 等 f 结束后移除 inflight;try/catch 确保不产生"未处理异常"
  static Future<void> _settle(Future f, String key) async {
    try { await f; } catch (_) {}
    _inflight.remove(key);
  }

  static bool _stale(String key) =>
      DateTime.now().millisecondsSinceEpoch - (_cacheAt[key] ?? 0) > _ttlMs;

  // 后台静默刷新:失败忽略,成功更新两层缓存,下次读取即新数据
  static void _revalidate(String path, Map<String, dynamic>? params, String key) {
    if (_inflight.containsKey(key)) return;
    final f = _fetch(path, params, true, key);
    _inflight[key] = f;
    _settle(f, key);
  }

  static dynamic _diskRead(String key) {
    final raw = _sp?.getString('hc::$key');
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map;
      _cacheAt[key] = (m['t'] as num?)?.toInt() ?? 0;
      return m['b'];
    } catch (_) {
      return null;
    }
  }

  static void _diskWrite(String key, dynamic body) {
    try {
      _sp?.setString('hc::$key', jsonEncode({'t': _cacheAt[key], 'b': body}));
    } catch (_) {} // 不可序列化/超限时放弃落盘,内存缓存仍有效
  }

  static Future<dynamic> _fetch(String path, Map<String, dynamic>? params, bool cache, String key) async {
    final res = await http
        .get(_uri(path, params), headers: _headers())
        .timeout(const Duration(seconds: 15));
    final body = await _decode(res.body);
    if (res.statusCode == 401) await setToken(null);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(_msg(body, res.statusCode), res.statusCode);
    }
    if (cache) {
      _getCache[key] = body;
      _cacheAt[key] = DateTime.now().millisecondsSinceEpoch;
      _diskWrite(key, body);
    }
    return body;
  }

  static Future<dynamic> post(String path, Map<String, dynamic> data) async {
    final res = await http
        .post(_uri(path, null), headers: _headers(json: true), body: jsonEncode(data))
        .timeout(const Duration(seconds: 15));
    final body = await _decode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(_msg(body, res.statusCode), res.statusCode);
    }
    return body;
  }

  static String _msg(dynamic body, int status) {
    if (body is Map && body['message'] != null) return '${body['message']}';
    return 'HTTP $status';
  }

  static void clearCache() {
    _getCache.clear();
    _cacheAt.clear();
    final keys = _sp?.getKeys().where((k) => k.startsWith('hc::')).toList() ?? [];
    for (final k in keys) {
      _sp?.remove(k);
    }
  }
}
