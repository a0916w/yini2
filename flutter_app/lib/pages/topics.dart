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

  // 深色渐变大横幅:左侧标题/热度/去看看,右侧斜叠三张封面
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
        height: 136,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: g),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: g[0].withValues(alpha: .35), blurRadius: 16, offset: const Offset(0, 7))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          // 大圆装饰(半透明白)
          Positioned(right: -50, top: -70, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .07)))),
          Positioned(right: 30, bottom: -90, child: Container(width: 170, height: 170, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .06)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
            child: Row(children: [
              // 左:标题 / 热度 / 去看看
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('${item['name']}', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800, letterSpacing: .5,
                          shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1))])),
                  const SizedBox(height: 7),
                  Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 12.5)),
                  const SizedBox(height: 13),
                  // 去看看:玻璃感胶囊
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .2),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withValues(alpha: .35)),
                    ),
                    child: Text(t('goSee'), style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
              // 右:斜叠三张封面(海报堆)
              if (covers.isNotEmpty)
                SizedBox(
                  width: 128,
                  height: double.infinity,
                  child: Stack(alignment: Alignment.centerRight, clipBehavior: Clip.none, children: [
                    for (var k = 0; k < covers.length; k++)
                      Positioned(
                        right: (covers.length - 1 - k) * 34.0,
                        child: Transform.rotate(
                          angle: (k - (covers.length - 1)) * .09, // 向下张开
                          child: Container(
                            width: 62, height: 84,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: .9), width: 1.6),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .3), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Cover(covers[k]),
                          ),
                        ),
                      ),
                  ]),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}
