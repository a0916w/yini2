import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api/models.dart';

// 本地观看历史(最近在前,最多 100 条)
class WatchHistory {
  static SharedPreferences? _sp;
  static const _key = 'watch_history';
  static const _max = 100;

  static Future<SharedPreferences> get _prefs async => _sp ??= await SharedPreferences.getInstance();

  static Future<List<Drama>> list() async {
    final sp = await _prefs;
    final raw = sp.getStringList(_key) ?? [];
    final out = <Drama>[];
    for (final s in raw) {
      try {
        final m = jsonDecode(s) as Map;
        out.add(Drama(
          id: (m['id'] as num).toInt(),
          title: '${m['title'] ?? ''}',
          genre: '${m['genre'] ?? ''}',
          cover: m['cover'] as String?,
          viewCount: (m['views'] as num?)?.toInt() ?? 0,
        ));
      } catch (_) {}
    }
    return out;
  }

  static Future<void> record(Drama d) async {
    final sp = await _prefs;
    final raw = sp.getStringList(_key) ?? [];
    raw.removeWhere((s) {
      try { return (jsonDecode(s) as Map)['id'] == d.id; } catch (_) { return true; }
    });
    raw.insert(0, jsonEncode({'id': d.id, 'title': d.title, 'genre': d.genre, 'cover': d.cover, 'views': d.viewCount}));
    while (raw.length > _max) {
      raw.removeLast();
    }
    await sp.setStringList(_key, raw);
  }

  static Future<void> clear() async => (await _prefs).remove(_key);
}
