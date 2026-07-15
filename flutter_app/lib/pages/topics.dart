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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
          child: Row(children: [
            // 左:标题 / 部数·热度 / 去看看
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
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
            const SizedBox(width: 10),
            // 右:扇形叠放(完整露出,不出卡)
            if (covers.isNotEmpty)
              SizedBox(
                width: 150, height: 96,
                child: Stack(alignment: Alignment.center, children: [
                  if (covers.length > 2) _mini(covers[2], right: 92, angle: -9, w: 52, h: 70),
                  if (covers.length > 1) _mini(covers[1], right: 47, angle: -2, w: 56, h: 76),
                  _mini(covers[0], right: 0, angle: 8, w: 60, h: 82),
                ]),
              ),
          ]),
        ),
      ),
    );
  }

  // 斜放迷你封面(真实剧照 3:4,白描边+黑影,完整可见)
  Widget _mini(Drama d, {required double right, required double angle, required double w, required double h}) =>
      Positioned(
        right: right,
        child: Transform.rotate(
          angle: angle * 3.14159 / 180,
          child: Container(
            width: w, height: h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: .55), width: 1.4),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .28), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            clipBehavior: Clip.antiAlias,
            child: Cover(d, showTitle: false),
          ),
        ),
      );
}
