import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../api/http.dart';
import '../state.dart';
import '../theme.dart';
import '../i18n.dart';

class MePage extends StatelessWidget {
  const MePage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final services = [
      (Icons.diamond_outlined, '会员中心', () => context.push('/vip')),
      (Icons.favorite, '我的收藏', () => context.push('/favorites')),
      (Icons.language, '语言', () => _pickLang(context)),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('个人中心'), centerTitle: false),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        GestureDetector(
          onTap: () => app.authed ? null : context.push('/login'),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(gradient: C.brandGrad, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              CircleAvatar(radius: 28, backgroundColor: Colors.white, child: Text(app.authed ? app.displayName.characters.first : '游', style: const TextStyle(color: C.brand, fontWeight: FontWeight.w900, fontSize: 24))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(app.authed ? app.displayName : '未登录', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(app.authed ? (app.isVip ? '会员到期 ${app.vipExpire}' : '普通用户') : '点击登录 / 注册', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
              if (app.authed && app.isVip) const Icon(Icons.diamond_outlined, color: Colors.white, size: 20),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.line)),
          child: Column(children: [
            for (final s in services)
              ListTile(
                leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(11)), child: Icon(s.$1, size: 18, color: C.ink2)),
                title: Text(s.$2),
                trailing: const Icon(Icons.chevron_right, color: C.ink3),
                onTap: s.$3,
              ),
          ]),
        ),
        const SizedBox(height: 20),
        if (app.authed)
          OutlinedButton(
            onPressed: () => app.logout(),
            style: OutlinedButton.styleFrom(foregroundColor: C.like, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
            child: Text(t('logout')),
          )
        else
          ElevatedButton(
            onPressed: () => context.push('/login'),
            style: ElevatedButton.styleFrom(backgroundColor: C.brand, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
            child: Text(t('login')),
          ),
      ]),
    );
  }

  void _pickLang(BuildContext context) {
    showModalBottomSheet(context: context, builder: (c) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final l in languages)
          ListTile(
            title: Text(l.$2),
            trailing: Http.lang == l.$1 ? const Icon(Icons.check, color: C.brand) : null,
            onTap: () { Http.lang = l.$1; Http.clearCache(); Navigator.pop(c); },
          ),
      ]),
    ));
  }
}
