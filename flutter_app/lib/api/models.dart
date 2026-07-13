// 文本清洗 / 标题解析(与前台一致)
import 'dart:convert';

String cleanName(String? s) {
  if (s == null || s.isEmpty) return '';
  if (RegExp(r'[一-鿿]').hasMatch(s)) {
    return s.replaceAll(RegExp(r"\s+[A-Za-z0-9][A-Za-z0-9\s'’&/.,-]*$"), '').trim();
  }
  return s;
}

String parseTitle(dynamic t) {
  if (t == null) return '';
  if (t is String && t.trim().startsWith('{')) {
    try {
      final o = jsonDecode(t) as Map;
      return cleanName((o['zh'] ?? o['zh-CN'] ?? o['en'] ?? (o.values.isNotEmpty ? o.values.first : '')) as String?);
    } catch (_) {
      return t;
    }
  }
  return cleanName('$t');
}

String fmtPlays(dynamic n) {
  final v = (n is num) ? n : num.tryParse('$n') ?? 0;
  return v >= 10000 ? '${(v / 10000).toStringAsFixed(1)}万' : '$v';
}

class Drama {
  final int id;
  final String title;
  final String? cover;
  final int viewCount;
  final int duration;
  final bool free;
  final String genre;
  final String desc;
  // detail-only
  final String? playUrl;
  final String? playType;
  final String? keyUrl;
  final bool canPlayFull;
  final int trialSeconds;
  final bool isFavorited;

  Drama({
    required this.id,
    required this.title,
    this.cover,
    this.viewCount = 0,
    this.duration = 0,
    this.free = true,
    this.genre = '',
    this.desc = '',
    this.playUrl,
    this.playType,
    this.keyUrl,
    this.canPlayFull = false,
    this.trialSeconds = 0,
    this.isFavorited = false,
  });

  String get plays => fmtPlays(viewCount);

  factory Drama.fromJson(Map v) {
    final cat = v['category'];
    return Drama(
      id: v['id'] as int,
      title: parseTitle(v['title']),
      cover: v['cover_url'] as String?,
      viewCount: (v['view_count'] as num?)?.toInt() ?? 0,
      duration: (v['duration'] as num?)?.toInt() ?? 0,
      free: !(v['is_vip'] == true || v['is_vip'] == 1),
      genre: cat is Map ? cleanName(cat['name'] as String?) : '',
      desc: (v['description'] as String?) ?? '',
      playUrl: v['play_url'] as String?,
      playType: v['play_type'] as String?,
      keyUrl: v['key_url'] as String?,
      canPlayFull: v['can_play_full'] == true,
      trialSeconds: (v['vip_trial_seconds'] as num?)?.toInt() ?? 0,
      isFavorited: v['is_favorited'] == true,
    );
  }
}

class Plan {
  final String key;
  final String name;
  final String currency; // cny | sgd
  final num price;
  final num origin;
  final int days;
  final String sub;
  final String tag;
  Plan({required this.key, required this.name, required this.currency, required this.price, required this.origin, required this.days, required this.sub, required this.tag});
  String get symbol => currency == 'sgd' ? 'S\$' : '¥';
  bool get hot => tag.isNotEmpty;

  factory Plan.fromJson(Map p) {
    final sgd = p['currency'] == 'sgd';
    final list = sgd ? (p['price_sgd'] as num? ?? 0) : (p['price'] as num? ?? 0);
    final origin = sgd ? (p['original_price_sgd'] as num? ?? 0) : (p['original_price'] as num? ?? 0);
    final price = p['event_price'] != null ? (p['event_price'] as num) : list;
    return Plan(
      key: '${p['key']}',
      name: '${p['name']}',
      currency: sgd ? 'sgd' : 'cny',
      price: price,
      origin: origin,
      days: (p['days'] as num?)?.toInt() ?? 0,
      sub: (p['description'] as String?) ?? '',
      tag: (p['tag'] as String?) ?? '',
    );
  }
}

class PayChannel {
  final int payTypeId;
  final int gatewayId;
  final String name;
  final String gkey;
  PayChannel({required this.payTypeId, required this.gatewayId, required this.name, required this.gkey});
}
