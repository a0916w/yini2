import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../api/api.dart';
import '../api/http.dart';
import '../api/models.dart';
import '../state.dart';
import '../i18n.dart';
import '../theme.dart';
import '../widgets.dart';

// 专题(handoff: topic 屏)——全宽渐变专题卡 + 右下斜放迷你封面
class TopicsPage extends StatefulWidget {
  const TopicsPage({super.key});
  @override
  State<TopicsPage> createState() => _TopicsPageState();
}

class _TopicsPageState extends State<TopicsPage> {
  List<Map>? _topics; // {id, name, count, covers:[Drama]}
  AppState? _app;
  String _lang = Http.lang;

  void _onApp() { if (_app!.lang != _lang) { _lang = _app!.lang; setState(() => _topics = null); _load(); } }

  @override
  void initState() {
    super.initState();
    _app = context.read<AppState>();
    _app!.addListener(_onApp);
    _load();
  }

  @override
  void dispose() {
    _app?.removeListener(_onApp);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final cats = await Api.categories();
      final out = <Map>[];
      for (final c in cats.cast<Map>()) {
        List<Drama> covers = [];
        try {
          final (rows, _, _) = await Api.videos(categoryId: c['id'] as int, perPage: 3);
          covers = rows;
        } catch (_) {}
        out.add({'id': c['id'], 'name': cleanName(c['name'] as String?), 'count': c['videos_count'] ?? '', 'covers': covers});
      }
      if (mounted) setState(() => _topics = out);
    } catch (_) {
      if (mounted) setState(() => _topics = []);
    }
  }

  // 专题卡渐变(规范:120deg,四组循环)
  static const _grads = [
    [Color(0xFFB3543F), Color(0xFF8A3B28)], // 霸总
    [Color(0xFF3D5A8C), Color(0xFF2C4166)], // 浪漫
    [Color(0xFF8A4A5E), Color(0xFF663445)], // 秘书
    [Color(0xFF5B4E9E), Color(0xFF423876)], // 豪门
  ];

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<ThemeController>().dark;
    context.watch<AppState>(); // 语言切换即重建文案
    final topics = _topics;
    return Scaffold(
      body: Container(
        decoration: pageTopGrad(dark),
        child: SafeArea(
          bottom: false,
          child: topics == null
              ? const Center(child: CircularProgressIndicator(color: C.brand))
              : ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 24), children: [
                  PageTitle(t('topicColl'), sub: t('topicSub')),
                  const SizedBox(height: 16),
                  for (var i = 0; i < topics.length; i++) ...[
                    _card(topics[i], i),
                    if (i < topics.length - 1) const SizedBox(height: 12),
                  ],
                ]),
        ),
      ),
    );
  }

  // 专题卡:r22 渐变 + 同色阴影;专题名 20/800;N部剧·N热度;白底「去看看›」;右下斜放迷你封面
  Widget _card(Map item, int i) {
    final covers = (item['covers'] as List).cast<Drama>();
    final g = _grads[i % _grads.length];
    var heat = 0;
    for (final d in covers) { heat += d.viewCount; }
    final sub = heat > 0
        ? tp('nDramaHeat', {'n': '${item['count']}', 'v': fmtPlays(heat)})
        : tp('nDramas', {'n': '${item['count']}'});
    return GestureDetector(
      onTap: () => context.push('/topic/${item['id']}?name=${Uri.encodeComponent('${item['name']}')}'),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: g),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: g[0].withValues(alpha: .3), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          // 第二张(在后,-8deg,白10%)
          if (covers.length > 1)
            Positioned(
              right: 34, bottom: -4,
              child: Transform.rotate(
                angle: -8 * 3.14159 / 180,
                child: Container(width: 56, height: 76,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .1), borderRadius: BorderRadius.circular(10))),
              ),
            ),
          // 第一张(在前,12deg,白14%,内嵌剧名)
          if (covers.isNotEmpty)
            Positioned(
              right: -10, bottom: -8,
              child: Transform.rotate(
                angle: 12 * 3.14159 / 180,
                child: Container(
                  width: 64, height: 86,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(11)),
                  child: Text(covers.first.title, maxLines: 4, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, height: 1.4)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${item['name']}', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(sub, style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 11)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100)),
                child: Text(t('goSee'), style: TextStyle(color: g[1], fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
