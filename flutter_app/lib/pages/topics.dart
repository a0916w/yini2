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

  // 每个专题一组鲜艳渐变 + 水印图标
  static const _grads = [
    [Color(0xFFFF8A2B), Color(0xFFE8480A)], [Color(0xFF6A7BFF), Color(0xFF3B2FC9)],
    [Color(0xFF34C77B), Color(0xFF0E7A4A)], [Color(0xFFC26BFF), Color(0xFF7A2ABF)],
    [Color(0xFFFF5D74), Color(0xFFC2183B)], [Color(0xFF3EC2DB), Color(0xFF0E6C86)],
    [Color(0xFFFFB13D), Color(0xFFCC6A00)], [Color(0xFF8F9BB3), Color(0xFF4A5468)],
  ];
  static const _icons = [
    Icons.local_fire_department, Icons.auto_awesome, Icons.favorite,
    Icons.bolt, Icons.diamond_outlined, Icons.stars, Icons.whatshot, Icons.movie_filter,
  ];

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>(); // 主题切换即重建,刷新 C.* 颜色
    context.watch<AppState>(); // 语言切换即重建文案
    final topics = _topics;
    return Scaffold(
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 头部
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(gradient: C.brandGrad, borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(t('topicColl'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
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

  // 沉浸式渐变横幅卡:扇形封面 + 大水印图标 + 名称/数量
  Widget _card(Map item, int i) {
    final covers = (item['covers'] as List).cast<Drama>();
    final g = _grads[i % _grads.length];
    final icon = _icons[i % _icons.length];
    return GestureDetector(
      onTap: () => context.push('/topic/${item['id']}?name=${Uri.encodeComponent('${item['name']}')}'),
      child: Container(
        height: 118,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: g),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: g[1].withValues(alpha: .35), blurRadius: 16, offset: const Offset(0, 7))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          // 右上大水印图标
          Positioned(right: -16, top: -16, child: Icon(icon, size: 96, color: Colors.white.withValues(alpha: .14))),
          // 高光斜带
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Colors.white.withValues(alpha: .14), Colors.transparent],
                  stops: const [0, .5],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(children: [
              // 扇形三连封面
              if (covers.isNotEmpty)
                SizedBox(
                  width: 118,
                  child: Stack(alignment: Alignment.center, children: [
                    for (var k = covers.length - 1; k >= 0; k--)
                      Positioned(
                        left: 14.0 + k * 26,
                        child: Transform.rotate(
                          angle: (k - 1) * .12,
                          child: Container(
                            width: 52, height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(color: Colors.white.withValues(alpha: .85), width: 1.5),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .25), blurRadius: 8, offset: const Offset(0, 3))],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Cover(covers[k]),
                          ),
                        ),
                      ),
                  ]),
                ),
              const SizedBox(width: 14),
              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${item['name']}', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: .5,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1))])),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .22), borderRadius: BorderRadius.circular(999)),
                  child: Text(tp('nPicked', {'n': '${item['count']}'}), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                ),
              ])),
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .22), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
