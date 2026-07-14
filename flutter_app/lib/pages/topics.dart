import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../api/api.dart';
import '../api/http.dart';
import '../api/models.dart';
import '../state.dart';
import '../i18n.dart';
import '../theme.dart';

class TopicsPage extends StatefulWidget {
  const TopicsPage({super.key});
  @override
  State<TopicsPage> createState() => _TopicsPageState();
}

class _TopicsPageState extends State<TopicsPage> {
  List<Map>? _topics; // {name, count, covers:[Drama]}
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

  // 深邃浓郁渐变(暗红/藏蓝/绛紫/深紫循环)
  static const _grads = [
    [Color(0xFF7A0410), Color(0xFFE8232E)],
    [Color(0xFF0B1F4B), Color(0xFF1E63D0)],
    [Color(0xFF5A0A3C), Color(0xFFD81B60)],
    [Color(0xFF2A1070), Color(0xFF7C4DFF)],
    [Color(0xFF063A42), Color(0xFF00ACC1)],
    [Color(0xFF702800), Color(0xFFFF6D00)],
  ];
  static const _chips = ['chip1', 'chip2', 'chip3', 'chip4'];

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>(); // 主题切换即重建,刷新 C.* 颜色
    context.watch<AppState>(); // 语言切换即重建文案
    final topics = _topics;
    return Scaffold(
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 头部:标题 + 副题
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t('topicColl'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(t('topicSub'), style: TextStyle(color: C.ink3, fontSize: 12.5)),
            ]),
          ),
          Expanded(
            child: topics == null
                ? const Center(child: CircularProgressIndicator(color: C.brand))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                    itemCount: topics.length,
                    itemBuilder: (c, i) => _card(topics[i], i),
                  ),
          ),
        ]),
      ),
    );
  }

  // 深色渐变大横幅:角标 chip + 大标题 + 部数/热度 + 去看看
  Widget _card(Map item, int i) {
    final covers = (item['covers'] as List).cast<Drama>();
    final g = _grads[i % _grads.length];
    // 热度:取样本剧集播放量之和
    var heat = 0;
    for (final d in covers) { heat += d.viewCount; }
    final sub = heat > 0
        ? tp('nDramaHeat', {'n': '${item['count']}', 'v': fmtPlays(heat)})
        : tp('nDramas', {'n': '${item['count']}'});
    return GestureDetector(
      onTap: () => context.push('/topic/${item['id']}?name=${Uri.encodeComponent('${item['name']}')}'),
      child: Container(
        height: 148,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: g),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: g[0].withValues(alpha: .35), blurRadius: 16, offset: const Offset(0, 7))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          // 右侧大圆装饰(两枚,半透明白)
          Positioned(right: -50, top: -70, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .07)))),
          Positioned(right: 30, bottom: -90, child: Container(width: 170, height: 170, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .06)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // 角标 chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: .28), borderRadius: BorderRadius.circular(8)),
                child: Text(t(_chips[i % _chips.length]), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 10),
              // 大标题
              Text('${item['name']}', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800, letterSpacing: .5)),
              const Spacer(),
              // 底行:部数·热度 + 去看看
              Row(children: [
                Expanded(child: Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 13))),
                Text(t('goSee'), style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
