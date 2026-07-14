import 'package:flutter/foundation.dart';
import 'api/http.dart';
import 'api/api.dart';

class AppState extends ChangeNotifier {
  bool authed = false;
  Map? user;
  bool isVip = false;
  String? vipExpire;
  final Set<int> favorites = {};

  Future<void> boot() async {
    authed = Http.token != null && Http.token!.isNotEmpty;
    if (authed) await refreshMe();
    notifyListeners();
  }

  Future<void> refreshMe() async {
    if (Http.token == null) return;
    try {
      final r = await Api.me();
      user = r['user'] as Map?;
      isVip = r['is_vip'] == true;
      vipExpire = (r['vip_expired_at'] as String?)?.substring(0, 10);
      authed = true;
    } catch (_) {/* keep */}
    notifyListeners();
  }

  Future<void> login(String account, String password) async {
    final acct = account.trim();
    if (password.isEmpty && acct.contains('|')) {
      await Http.setToken(acct);
    } else {
      final r = await Api.login(acct, password);
      await Http.setToken(r['token'] as String?);
      user = r['user'] as Map?;
    }
    authed = true;
    await refreshMe();
  }

  Future<void> logout() async {
    try {
      await Api.logout();
    } catch (_) {}
    await Http.setToken(null);
    authed = false;
    user = null;
    isVip = false;
    notifyListeners();
  }

  String get displayName => (user?['nickname'] as String?) ?? '未登录';

  // 语言切换:按语言分桶缓存(不清空,切回即命中),预热新语言,通知各 tab 重载
  String get lang => Http.lang;
  void setLanguage(String code) {
    if (Http.lang == code) return;
    Http.lang = code;
    Api.prewarm(); // 预热新语言的各 tab 数据
    notifyListeners();
  }

  Future<bool> toggleFavorite(int id) async {
    if (authed) {
      try {
        final v = await Api.toggleFavorite(id);
        if (v) {
          favorites.add(id);
        } else {
          favorites.remove(id);
        }
        notifyListeners();
        return v;
      } catch (_) {}
    }
    final added = !favorites.contains(id);
    added ? favorites.add(id) : favorites.remove(id);
    notifyListeners();
    return added;
  }
}
