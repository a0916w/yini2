import 'http.dart';
import 'models.dart';

class Api {
  // auth
  static Future<Map> login(String account, String password) async =>
      await Http.post('/login', {'account': account, 'password': password}) as Map;
  static Future<Map> me() async => await Http.get('/me', cache: false) as Map;
  static Future logout() => Http.post('/logout', {});

  // content
  static Future<List> categories() async => (await Http.get('/categories') as List);
  static Future<List> banners() async => (await Http.get('/banners') as List);
  static Future<List> marquees() async => (await Http.get('/marquees') as List);
  static Future<Map> siteSettings() async => await Http.get('/site-settings') as Map;

  static Future<(List<Drama>, int, int)> videos({int? categoryId, String? keyword, int page = 1, int perPage = 18, bool fresh = false}) async {
    final b = await Http.get('/videos', params: {
      'category_id': categoryId,
      'keyword': keyword,
      'page': page,
      'per_page': perPage,
    }, cache: keyword == null, fresh: fresh) as Map;
    final list = (b['data'] as List).map((e) => Drama.fromJson(e as Map)).toList();
    return (list, (b['current_page'] as num?)?.toInt() ?? 1, (b['last_page'] as num?)?.toInt() ?? 1);
  }

  static Future<List<Drama>> latest() async =>
      ((await Http.get('/videos/latest') as List)).map((e) => Drama.fromJson(e as Map)).toList();
  static Future<List<Drama>> recommended() async =>
      ((await Http.get('/videos/recommended') as List)).map((e) => Drama.fromJson(e as Map)).toList();
  static Future<Drama> videoDetail(int id) async =>
      Drama.fromJson(await Http.get('/videos/$id') as Map);

  // vip / orders
  static Future<List<Plan>> plans() async {
    final m = await Http.get('/vip/plans') as Map;
    return m.values.map((e) => Plan.fromJson(e as Map)).toList();
  }

  static Future<List<PayChannel>> channels(String currency) async {
    final gws = await Http.get('/vip/payment-options') as List;
    final out = <PayChannel>[];
    for (final g in gws) {
      for (final o in (g['payment_options'] as List? ?? [])) {
        final currs = (o['currencies'] as List?)?.map((e) => '$e').toList() ?? ['${o['currency'] ?? 'cny'}'];
        if (!currs.contains(currency)) continue;
        final gn = '${g['name']}';
        final on = '${o['name'] ?? ''}';
        out.add(PayChannel(payTypeId: g['id'] as int, gatewayId: o['id'] as int, gkey: '${g['key']}', name: on.isNotEmpty && on != gn ? '$gn · $on' : gn));
      }
    }
    return out;
  }

  static Future<Map> createOrder({required String plan, required int payTypeId, required int gatewayId}) async =>
      await Http.post('/vip/order', {'plan': plan, 'pay_type_id': payTypeId, 'gateway_id': gatewayId}) as Map;
  static Future<List> myOrders() async => ((await Http.get('/vip/orders', cache: false) as Map)['data'] as List);
  static Future<Map?> activeEvent() async {
    final r = await Http.get('/event/active') as Map;
    return r['event'] as Map?;
  }

  // user data
  static Future<bool> toggleFavorite(int id) async {
    final r = await Http.post('/favorites/$id', {}) as Map;
    return r['is_favorited'] == true;
  }
  static Future<List<Drama>> favorites() async =>
      (((await Http.get('/favorites', params: {'per_page': 50}, cache: false) as Map)['data'] as List)).map((e) => Drama.fromJson(e as Map)).toList();
  static Future recordWatch(int id) => Http.post('/watch-history/$id', {});

  // 启动预热:核心列表接口进 GET 缓存,进页面即命中
  static void prewarm() {
    void fire(Future f) => f.then((_) {}, onError: (_) {});
    fire(categories());
    fire(videos(page: 1));
    fire(recommended());
    fire(latest());
    fire(marquees());
    fire(banners());
    fire(Http.get('/site-settings'));
    fire(plans());
  }

  // 预取剧集详情(缓存),点进详情/播放秒开;去重
  static final Set<int> _warmed = {};
  static void prefetchDetail(int id) {
    if (_warmed.contains(id)) return;
    _warmed.add(id);
    videoDetail(id).then((_) {}, onError: (_) => _warmed.remove(id));
  }
}
