import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../api/http.dart';
import '../state.dart';
import '../theme.dart';
import '../i18n.dart';

// 我的(handoff: me 屏)——主色渐变头 + 悬浮快捷卡 + VIP 深底金 + 暖底服务卡
class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final theme = context.watch<ThemeController>();
    final vip = app.authed && app.isVip;

    return Scaffold(
      body: ListView(padding: EdgeInsets.zero, children: [
        // 主色渐变头部(150deg,底圆角 30)+ 悬浮快捷卡(压住头部下沿)
        Stack(clipBehavior: Clip.none, children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 56),
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFF8A3C), Color(0xFFFF6000)]),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t('profile'), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Row(children: [
                Container(
                  width: 56, height: 56,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(app.authed ? app.displayName.characters.first.toUpperCase() : 'Y',
                      style: const TextStyle(color: C.brand, fontSize: 22, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(app.authed ? app.displayName : t('notLoggedIn'),
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(app.authed ? 'UID ${app.user?['id'] ?? ''}' : t('tapLogin'),
                      style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 12)),
                ])),
                GestureDetector(
                  onTap: () { if (!app.authed) context.push('/login'); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .22), borderRadius: BorderRadius.circular(100)),
                    child: Text(app.authed ? 'VIP' : t('login'),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ]),
          ),
          // 悬浮快捷卡
          Positioned(
            left: 20, right: 20, bottom: -32,
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: C.surface, borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: C.brand.withValues(alpha: .12), blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: Row(children: [
                Expanded(child: _quick(context, Icons.schedule, t('history'), '/history')),
                Container(width: 1, color: C.line, margin: const EdgeInsets.symmetric(vertical: 6)),
                Expanded(child: _quick(context, Icons.favorite_border, '${t('myFav')} ${app.favorites.length}', '/favorites')),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 32),
        // VIP 深底金横幅
        GestureDetector(
          onTap: () => context.push('/vip'),
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(color: C.vipBg, borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.diamond, size: 15, color: C.vipGold),
                  const SizedBox(width: 7),
                  Text(t('joinVip'), style: const TextStyle(color: C.vipGold, fontSize: 14, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 4),
                Text(vip ? tp('vipUntil', {'d': app.vipExpire ?? ''}) : t('vipPitch'),
                    style: TextStyle(color: C.vipGold.withValues(alpha: .6), fontSize: 11)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: C.vipGold, borderRadius: BorderRadius.circular(100)),
                child: Text(vip ? t('renewNow') : t('joinNow'),
                    style: const TextStyle(color: C.vipInk, fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
        ),
        // 我的服务(暖底卡)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: Text(t('myServices'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.ink)),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(18)),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            _service(
              icon: Icons.diamond_outlined,
              label: t('vipCenter'),
              trailing: Text('${vip ? t('activated') : t('notActivated')} ›', style: TextStyle(fontSize: 12, color: C.quiet)),
              onTap: () => context.push('/vip'),
            ),
            _divider(),
            _service(
              icon: Icons.language,
              label: t('language'),
              trailing: Text('${_langName()} ›', style: TextStyle(fontSize: 12, color: C.quiet)),
              onTap: () => _pickLang(context),
            ),
            _divider(),
            _service(
              icon: Icons.dark_mode_outlined,
              label: t('darkMode'),
              trailing: _toggle(theme.dark, (v) => theme.toggle(v)),
              onTap: () => theme.toggle(!theme.dark),
            ),
          ]),
        ),
        // 底部登录 / 退出
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: app.authed
              ? GestureDetector(
                  onTap: () => app.logout(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(100)),
                    child: Text(t('logout'), style: TextStyle(color: C.ink2, fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                )
              : GestureDetector(
                  onTap: () => context.push('/login'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: C.brandGrad, borderRadius: BorderRadius.circular(100),
                      boxShadow: [BoxShadow(color: C.brand.withValues(alpha: .32), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Text(t('login'), style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
        ),
      ]),
    );
  }

  Widget _quick(BuildContext context, IconData icon, String label, String route) => GestureDetector(
        onTap: () => context.push(route),
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 20, color: C.brand),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.ink)),
        ]),
      );

  Widget _service({required IconData icon, required String label, required Widget trailing, required VoidCallback onTap}) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Icon(icon, size: 16, color: C.brand),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.ink))),
            trailing,
          ]),
        ),
      );

  Widget _divider() => Container(height: 1, color: C.brand.withValues(alpha: .08));

  // 深色模式开关(44×26,规范样式)
  Widget _toggle(bool on, ValueChanged<bool> onChanged) => GestureDetector(
        onTap: () => onChanged(!on),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 44, height: 26,
          padding: const EdgeInsets.all(3),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(color: on ? C.brand : const Color(0xFFEBDFD2), borderRadius: BorderRadius.circular(13)),
          child: Container(
            width: 20, height: 20,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .15), blurRadius: 3, offset: const Offset(0, 1))]),
          ),
        ),
      );

  static String _langName() {
    for (final l in languages) {
      if (l.$1 == Http.lang) return l.$2;
    }
    return '中文';
  }

  void _pickLang(BuildContext context) {
    showModalBottomSheet(context: context, backgroundColor: C.surface, builder: (c) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final l in languages)
          ListTile(
            title: Text(l.$2),
            trailing: Http.lang == l.$1 ? const Icon(Icons.check, color: C.brand) : null,
            onTap: () { context.read<AppState>().setLanguage(l.$1); Navigator.pop(c); },
          ),
      ]),
    ));
  }
}
