import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/api.dart';
import '../api/models.dart';
import '../state.dart';
import '../i18n.dart';
import '../theme.dart';

class VipPage extends StatefulWidget {
  const VipPage({super.key});
  @override
  State<VipPage> createState() => _VipPageState();
}

class _VipPageState extends State<VipPage> {
  static List<(IconData, String)> get _rights => [
    (Icons.movie_outlined, t('freeWatch')),
    (Icons.block, t('adFree')),
    (Icons.download_outlined, t('offline')),
    (Icons.bolt, t('earlyAccess')),
    (Icons.diamond_outlined, t('badge')),
  ];
  List<Plan> _plans = [];
  List<PayChannel> _channels = [];
  String? _plan;
  PayChannel? _ch;
  bool _busy = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ps = await Api.plans();
      setState(() {
        _plans = ps;
        _plan = (ps.where((p) => p.hot).isNotEmpty ? ps.firstWhere((p) => p.hot) : ps.first).key;
      });
      await _loadChannels();
    } catch (_) {}
  }

  Future<void> _loadChannels() async {
    final cur = _plans.where((p) => p.key == _plan).firstOrNull;
    if (cur == null) return;
    try {
      final chs = await Api.channels(cur.currency);
      setState(() { _channels = chs; _ch = chs.firstOrNull; });
    } catch (_) {}
  }

  @override
  void dispose() { _poll?.cancel(); super.dispose(); }

  Future<void> _buy() async {
    final app = context.read<AppState>();
    final cur = _plans.where((p) => p.key == _plan).firstOrNull;
    if (cur == null || _ch == null) return;
    if (!app.authed) { _toast(t('loginFirst')); return; }
    setState(() => _busy = true);
    try {
      final r = await Api.createOrder(plan: cur.key, payTypeId: _ch!.payTypeId, gatewayId: _ch!.gatewayId);
      final url = r['pay_url'] as String?;
      final orderNo = (r['order'] as Map?)?['order_no'] as String?;
      if (url != null && url.isNotEmpty) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        if (orderNo != null) _startPoll(orderNo, app);
        _toast(t('payNote'));
      } else {
        _toast(t('orderFail'));
      }
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startPoll(String orderNo, AppState app) {
    _poll?.cancel();
    final started = DateTime.now();
    _poll = Timer.periodic(const Duration(seconds: 3), (tm) async {
      if (DateTime.now().difference(started).inSeconds > 180) { tm.cancel(); return; }
      try {
        final orders = await Api.myOrders();
        final o = orders.cast<Map>().where((x) => x['order_no'] == orderNo).firstOrNull;
        if (o != null && '${o['status']}' == '1') {
          tm.cancel();
          await app.refreshMe();
          if (mounted) _toast(t('paySuccess'));
        }
      } catch (_) {}
    });
  }

  void _toast(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cur = _plans.where((p) => p.key == _plan).firstOrNull;
    final dark = context.watch<ThemeController>().dark;
    return Scaffold(
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: C.surface, border: Border(top: BorderSide(color: C.line))),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(t('total'), style: TextStyle(color: C.ink3, fontSize: 12)),
                Text('${cur?.symbol ?? '¥'}${cur?.price ?? '--'}', style: const TextStyle(color: C.brand, fontWeight: FontWeight.w800, fontSize: 24)),
              ]),
              const Spacer(),
              GestureDetector(
                onTap: _busy || cur == null ? null : _buy,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 13),
                  decoration: BoxDecoration(
                    gradient: C.brandGrad, borderRadius: BorderRadius.circular(100),
                    boxShadow: [BoxShadow(color: C.brand.withValues(alpha: .4), blurRadius: 14, offset: const Offset(0, 6))],
                  ),
                  child: Text(_busy ? t('processing') : t('joinNow'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ]),
          ),
        ),
      ),
      body: Container(
        decoration: pageTopGrad(dark),
        child: SafeArea(
          bottom: false,
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 10, 20, 20), children: [
        // 顶栏:返回圆钮 + 标题
        Row(children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: C.surface, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: C.brand.withValues(alpha: .12), blurRadius: 10, offset: const Offset(0, 3))]),
              child: Icon(Icons.arrow_back_ios_new, size: 15, color: C.ink),
            ),
          ),
          const SizedBox(width: 12),
          Text(t('vipCenter'), style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: C.ink)),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: C.vipBg, borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(app.authed ? app.displayName : t('notLoggedIn'), style: const TextStyle(color: C.vipGold, fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 4),
              Text(app.isVip ? tp('vipUntil2', {'d': app.vipExpire ?? ''}) : t('noVipYet'), style: TextStyle(color: C.vipGold.withValues(alpha: .6), fontSize: 12)),
            ])),
            const Icon(Icons.diamond, color: C.vipGold, size: 28),
          ]),
        ),
        const SizedBox(height: 20),
        // 会员权益
        Text(t('vipRights'), style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: C.ink)),
        const SizedBox(height: 14),
        Row(children: _rights.map((r) => Expanded(child: Column(children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: C.tag, shape: BoxShape.circle), alignment: Alignment.center, child: Icon(r.$1, color: C.brand, size: 21)),
          const SizedBox(height: 7),
          Text(r.$2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
        ]))).toList()),
        const SizedBox(height: 22),
        Text(t('choosePlan'), style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: C.ink)),
        const SizedBox(height: 12),
        Row(children: _plans.map((p) {
          final active = _plan == p.key;
          return Expanded(child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () { setState(() => _plan = p.key); _loadChannels(); },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
                decoration: BoxDecoration(
                  color: active ? C.tag : C.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: active ? C.brand : Colors.transparent, width: 1.5),
                ),
                child: Column(children: [
                  if (p.hot) Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(gradient: C.brandGrad, borderRadius: BorderRadius.circular(999)), child: Text(p.tag.isEmpty ? t('hot') : p.tag, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500))),
                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text.rich(TextSpan(children: [
                    TextSpan(text: '${p.price}', style: const TextStyle(color: C.brand, fontWeight: FontWeight.w600, fontSize: 24)),
                    TextSpan(text: p.currency == 'sgd' ? ' SGD' : t('yuan'), style: const TextStyle(color: C.brand, fontSize: 12, fontWeight: FontWeight.w500)),
                  ])),
                  if (p.origin > p.price) Text('${p.symbol}${p.origin}', style: TextStyle(color: C.ink3, fontSize: 11, decoration: TextDecoration.lineThrough)),
                ]),
              ),
            ),
          ));
        }).toList()),
        if (cur?.sub.isNotEmpty ?? false) Padding(padding: const EdgeInsets.only(top: 10), child: Text(cur!.sub, style: TextStyle(color: C.ink3, fontSize: 12))),
        const SizedBox(height: 22),
        Text(t('payMethod'), style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: C.ink)),
        const SizedBox(height: 10),
        if (_channels.isEmpty)
          Text(t('noPay'), style: TextStyle(color: C.ink3, fontSize: 13))
        else
          ..._channels.map((c) {
            final on = _ch?.payTypeId == c.payTypeId && _ch?.gatewayId == c.gatewayId;
            return GestureDetector(
              onTap: () => setState(() => _ch = c),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: on ? C.tag : C.surface2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: on ? C.brand : Colors.transparent, width: 1.4),
                ),
                child: Row(children: [
                  Container(width: 34, height: 34, decoration: BoxDecoration(gradient: C.brandGrad, borderRadius: BorderRadius.circular(10)), alignment: Alignment.center, child: Text(c.name.characters.first, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                  const SizedBox(width: 12),
                  Expanded(child: Text(c.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.ink))),
                  Icon(on ? Icons.check_circle : Icons.radio_button_unchecked, color: on ? C.brand : C.quiet, size: 20),
                ]),
              ),
            );
          }),
        const SizedBox(height: 12),
        Center(child: Text(t('vipAgree'), style: TextStyle(color: C.ink3, fontSize: 11))),
          ]),
        ),
      ),
    );
  }
}
