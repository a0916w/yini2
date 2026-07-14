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
        out.add({'name': cleanName(c['name'] as String?), 'count': c['videos_count'] ?? '', 'covers': covers});
      }
      if (mounted) setState(() => _topics = out);
    } catch (_) {
      if (mounted) setState(() => _topics = []);
    }
  }

  // 每个专题一组主题色(图标块 / 徽标)
  static const _accents = [
    (Color(0xFFFF6D00), Color(0xFFFFF1E4)), (Color(0xFF5B6BFF), Color(0xFFE9EBFF)),
    (Color(0xFF1F9D55), Color(0xFFE2F5EA)), (Color(0xFFB04BD8), Color(0xFFF5E7FB)),
    (Color(0xFFE8484A), Color(0xFFFDE9E9)), (Color(0xFF0E9BB5), Color(0xFFE2F6FA)),
  ];
  static const _icons = [
    Icons.local_fire_department, Icons.auto_awesome, Icons.favorite,
    Icons.bolt, Icons.diamond_outlined, Icons.stars,
  ];

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>(); // 主题切换即重建,刷新 C.* 颜色
    context.watch<AppState>(); // 语言切换即重建文案
    final topics = _topics;
    final dark = context.watch<ThemeController>().dark;
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: topics.length,
                    itemBuilder: (c, i) {
                      final item = topics[i];
                      final covers = (item['covers'] as List).cast<Drama>();
                      final accent = _accents[i % _accents.length];
                      final icon = _icons[i % _icons.length];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: C.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: C.line),
                          boxShadow: [BoxShadow(color: accent.$1.withValues(alpha: dark ? .10 : .07), blurRadius: 18, offset: const Offset(0, 6))],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          // 头部条:渐变色带 + 图标 + 名称 + 数量徽标
                          Container(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [accent.$1.withValues(alpha: dark ? .22 : .12), Colors.transparent]),
                            ),
                            child: Row(children: [
                              Container(
                                width: 34, height: 34,
                                decoration: BoxDecoration(color: dark ? accent.$1.withValues(alpha: .25) : accent.$2, borderRadius: BorderRadius.circular(11)),
                                child: Icon(icon, size: 18, color: accent.$1),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text('${item['name']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(color: accent.$1.withValues(alpha: .14), borderRadius: BorderRadius.circular(999)),
                                child: Text(tp('nPicked', {'n': '${item['count']}'}), style: TextStyle(color: accent.$1, fontSize: 11, fontWeight: FontWeight.w500)),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.chevron_right, color: C.ink3, size: 20),
                            ]),
                          ),
                          // 封面三连
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                            child: Row(children: [
                              for (var k = 0; k < covers.length; k++) ...[
                                Expanded(child: GestureDetector(
                                  onTap: () => context.push('/drama/${covers[k].id}'),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    AspectRatio(aspectRatio: 3 / 4, child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Cover(covers[k]))),
                                    const SizedBox(height: 6),
                                    Text(covers[k].title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: C.ink2)),
                                  ]),
                                )),
                                if (k < covers.length - 1) const SizedBox(width: 10),
                              ],
                            ]),
                          ),
                        ]),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}
