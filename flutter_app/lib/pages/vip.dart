import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/api.dart';
import '../api/models.dart';
import '../state.dart';
import '../theme.dart';

class VipPage extends StatefulWidget {
  const VipPage({super.key});
  @override
  State<VipPage> createState() => _VipPageState();
}

class _VipPageState extends State<VipPage> {
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
    if (!app.authed) { _toast('请先登录'); return; }
    setState(() => _busy = true);
    try {
      final r = await Api.createOrder(plan: cur.key, payTypeId: _ch!.payTypeId, gatewayId: _ch!.gatewayId);
      final url = r['pay_url'] as String?;
      final orderNo = (r['order'] as Map?)?['order_no'] as String?;
      if (url != null && url.isNotEmpty) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        if (orderNo != null) _startPoll(orderNo, app);
        _toast('支付完成后将自动到账');
      } else {
        _toast('下单失败');
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
    _poll = Timer.periodic(const Duration(seconds: 3), (t) async {
      if (DateTime.now().difference(started).inSeconds > 180) { t.cancel(); return; }
      try {
        final orders = await Api.myOrders();
        final o = orders.cast<Map>().where((x) => x['order_no'] == orderNo).firstOrNull;
        if (o != null && '${o['status']}' == '1') {
          t.cancel();
          await app.refreshMe();
          if (mounted) _toast('开通成功');
        }
      } catch (_) {}
    });
  }

  void _toast(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cur = _plans.where((p) => p.key == _plan).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('会员中心')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              const Text('合计', style: TextStyle(color: C.ink3, fontSize: 12)),
              Text('${cur?.symbol ?? '¥'}${cur?.price ?? '--'}', style: const TextStyle(color: C.brand, fontWeight: FontWeight.w900, fontSize: 24)),
            ]),
            const Spacer(),
            ElevatedButton(
              onPressed: _busy || cur == null ? null : _buy,
              style: ElevatedButton.styleFrom(backgroundColor: C.brand, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
              child: Text(_busy ? '处理中…' : '立即开通', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ]),
        ),
      ),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2B2118), Color(0xFF1F1812)]), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(app.authed ? app.displayName : '未登录', style: const TextStyle(color: Color(0xFFF7D9B8), fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 4),
              Text(app.isVip ? '会员有效期至 ${app.vipExpire}' : '尚未开通会员', style: const TextStyle(color: Color(0xFFC9A87E), fontSize: 12)),
            ])),
            const Icon(Icons.diamond_outlined, color: Color(0xFFF7D9B8), size: 28),
          ]),
        ),
        const SizedBox(height: 20),
        const Text('选择套餐', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
                  color: active ? const Color(0xFFFFF7F0) : C.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: active ? C.brand : C.line, width: 1.5),
                ),
                child: Column(children: [
                  if (p.hot) Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(gradient: C.brandGrad, borderRadius: BorderRadius.circular(999)), child: Text(p.tag.isEmpty ? '热销' : p.tag, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))),
                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text.rich(TextSpan(children: [
                    TextSpan(text: '${p.price}', style: const TextStyle(color: C.brand, fontWeight: FontWeight.w900, fontSize: 24)),
                    TextSpan(text: p.currency == 'sgd' ? ' SGD' : ' 元', style: const TextStyle(color: C.brand, fontSize: 12, fontWeight: FontWeight.w700)),
                  ])),
                  if (p.origin > p.price) Text('${p.symbol}${p.origin}', style: const TextStyle(color: C.ink3, fontSize: 11, decoration: TextDecoration.lineThrough)),
                ]),
              ),
            ),
          ));
        }).toList()),
        const SizedBox(height: 22),
        const Text('支付方式', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        if (_channels.isEmpty)
          const Text('当前套餐暂无可用支付方式', style: TextStyle(color: C.ink3, fontSize: 13))
        else
          ..._channels.map((c) {
            final on = _ch?.payTypeId == c.payTypeId && _ch?.gatewayId == c.gatewayId;
            return ListTile(
              onTap: () => setState(() => _ch = c),
              contentPadding: EdgeInsets.zero,
              leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: C.brand, borderRadius: BorderRadius.circular(10)), alignment: Alignment.center, child: Text(c.name.characters.first, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
              title: Text(c.name),
              trailing: Icon(on ? Icons.check_circle : Icons.radio_button_unchecked, color: on ? C.brand : C.ink3, size: 20),
            );
          }),
        const SizedBox(height: 12),
        const Center(child: Text('开通前请阅读《会员服务协议》· 虚拟商品暂不支持退款', style: TextStyle(color: C.ink3, fontSize: 11))),
      ]),
    );
  }
}
