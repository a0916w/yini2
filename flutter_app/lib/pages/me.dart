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
    final vip = app.authed && app.isVip;

    final quick = [
      (Icons.history, '观看记录', ''),
      (Icons.favorite_border, '我的收藏', '${app.favorites.length}'),
      (Icons.download_outlined, '下载', ''),
      (Icons.receipt_long_outlined, '我的订单', ''),
    ];
    final services = [
      (Icons.diamond_outlined, '会员中心', vip ? '已开通' : '未开通', () => context.push('/vip')),
      (Icons.confirmation_num_outlined, '兑换码', '', () => _todo(context)),
      (Icons.card_giftcard, '积分商城', '', () => _todo(context)),
      (Icons.event_available_outlined, '任务中心', '', () => _todo(context)),
      (Icons.auto_awesome, '魔改愿望榜', '', () => context.go('/wishes')),
      (Icons.mail_outline, '站内消息', '', () => _todo(context)),
      (Icons.campaign_outlined, '官方公告', '', () => _todo(context)),
      (Icons.fact_check_outlined, '问卷调查', '', () => _todo(context)),
      (Icons.chat_bubble_outline, '意见反馈', '', () => _todo(context)),
      (Icons.headset_mic_outlined, '联系客服', '', () => _todo(context)),
      (Icons.language, '语言', _langName(), () => _pickLang(context)),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('个人中心'), centerTitle: false),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        // 资料卡(橙渐变)
        GestureDetector(
          onTap: () { if (!app.authed) context.push('/login'); },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(gradient: C.brandGrad, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: C.brand.withValues(alpha: .3), blurRadius: 22, offset: const Offset(0, 8))]),
            child: Row(children: [
              Container(
                width: 56, height: 56,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(app.authed ? app.displayName.characters.first : '橙', style: const TextStyle(color: C.brand, fontWeight: FontWeight.w600, fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(app.authed ? app.displayName : '未登录', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(app.authed ? 'UID ${app.user?['id'] ?? ''}' : '点击登录 / 注册', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
              if (vip)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .22), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: .4))),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.diamond_outlined, size: 12, color: Colors.white), SizedBox(width: 4), Text('VIP', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))]),
                )
              else
                const Icon(Icons.chevron_right, color: Colors.white70),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        // 四宫格
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.line)),
          child: Row(children: quick.map((q) => Expanded(child: GestureDetector(
            onTap: () {
              if (q.$2 == '我的收藏') {
                context.push('/favorites');
              } else {
                _todo(context);
              }
            },
            child: Column(children: [
              Icon(q.$1, size: 22, color: C.ink2),
              const SizedBox(height: 6),
              Text('${q.$2}${q.$3.isNotEmpty ? ' ${q.$3}' : ''}', style: TextStyle(fontSize: 11, color: C.ink3)),
            ]),
          ))).toList()),
        ),
        const SizedBox(height: 12),
        // 黑金开通会员
        GestureDetector(
          onTap: () => context.push('/vip'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2B2118), Color(0xFF1F1812)]), borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [Icon(Icons.diamond_outlined, size: 15, color: Color(0xFFF7D9B8)), SizedBox(width: 6), Text('开通会员', style: TextStyle(color: Color(0xFFF7D9B8), fontWeight: FontWeight.w600))]),
                const SizedBox(height: 3),
                Text(vip ? '有效期至 ${app.vipExpire}' : '海量剧集免费看 · 免广告', style: const TextStyle(color: Color(0xFFC9A87E), fontSize: 12)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(gradient: C.brandGrad, borderRadius: BorderRadius.circular(999)),
                child: Text(vip ? '立即续费' : '立即开通', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 18),
        const Padding(padding: EdgeInsets.only(left: 2, bottom: 10), child: Text('我的服务', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
        Container(
          decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.line)),
          child: Column(children: [
            for (var i = 0; i < services.length; i++) ...[
              InkWell(
                onTap: services[i].$4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  child: Row(children: [
                    Container(width: 34, height: 34, decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(11)), child: Icon(services[i].$1, size: 17, color: C.ink2)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(services[i].$2, style: const TextStyle(fontSize: 15))),
                    if (services[i].$3.isNotEmpty) Text(services[i].$3, style: TextStyle(color: C.ink3, fontSize: 13)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: C.ink3, size: 20),
                  ]),
                ),
              ),
              if (i < services.length - 1) Divider(height: 1, color: C.line, indent: 60),
            ],
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: C.line)),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: C.surface,
            child: SwitchListTile(
              value: context.watch<ThemeController>().dark,
              activeThumbColor: C.brand,
              onChanged: (v) => context.read<ThemeController>().toggle(v),
              secondary: Container(width: 34, height: 34, decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(11)), child: Icon(Icons.dark_mode_outlined, size: 17, color: C.ink2)),
              title: const Text('深色模式', style: TextStyle(fontSize: 15)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (app.authed)
          OutlinedButton(
            onPressed: () => app.logout(),
            style: OutlinedButton.styleFrom(foregroundColor: C.like, minimumSize: const Size.fromHeight(48), side: BorderSide(color: C.line), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
            child: Text(t('logout')),
          )
        else
          ElevatedButton(
            onPressed: () => context.push('/login'),
            style: ElevatedButton.styleFrom(backgroundColor: C.brand, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
            child: Text(t('login')),
          ),
        const SizedBox(height: 20),
      ]),
    );
  }

  static String _langName() {
    for (final l in languages) {
      if (l.$1 == Http.lang) return l.$2;
    }
    return '中文';
  }

  static void _todo(BuildContext c) => ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('功能开发中'), duration: Duration(seconds: 1)));

  void _pickLang(BuildContext context) {
    showModalBottomSheet(context: context, builder: (c) => SafeArea(
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
