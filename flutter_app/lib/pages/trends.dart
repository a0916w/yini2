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

class TrendsPage extends StatefulWidget {
  const TrendsPage({super.key});
  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> {
  final _tabs = ['hottest', 'newest', 'forYou']; // i18n key
  String _tab = 'hottest';
  List<Drama> _list = [];
  bool _loading = true;
  AppState? _app;
  String _lang = Http.lang;
  final Map<String, List<Drama>> _cache = {}; // 按子 tab 缓存

  void _onApp() { if (_app!.lang != _lang) { _lang = _app!.lang; _cache.clear(); _load(); } }

  @override
  void initState() {
    super.initState();
    _app = context.read<AppState>();
    _app!.addListener(_onApp);
    _load();
    _prefetchTabs();
  }

  @override
  void dispose() {
    _app?.removeListener(_onApp);
    super.dispose();
  }

  // 后台把其余榜单也拉好,切换零等待
  void _prefetchTabs() {
    for (final tab in _tabs) {
      if (_cache.containsKey(tab)) continue;
      _fetch(tab).then((rows) { if (mounted) _cache[tab] = rows; }).catchError((_) {});
    }
  }

  Future<List<Drama>> _fetch(String tab) async {
    if (tab == 'newest') return Api.latest();
    if (tab == 'forYou') return Api.recommended();
    final (r, _, _) = await Api.videos(perPage: 50);
    r.sort((a, b) => b.viewCount - a.viewCount);
    return r;
  }

  void _pick(String tab) {
    if (_tab == tab) return;
    _tab = tab;
    final cached = _cache[tab];
    if (cached != null) {
      setState(() { _list = cached; _loading = false; });
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final reqTab = _tab;
    setState(() => _loading = true);
    try {
      final rows = await _fetch(reqTab);
      _cache[reqTab] = rows;
      if (mounted && _tab == reqTab) setState(() => _list = rows);
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // 金 / 银 / 铜
  static const _medals = [Color(0xFFFFB300), Color(0xFF9FA8B8), Color(0xFFCD7F52)];

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>(); // 主题切换即重建,刷新 C.* 颜色
    context.watch<AppState>(); // 语言切换即重建文案
    final top3 = _list.take(3).toList();
    final rest = _list.length > 3 ? _list.sublist(3) : <Drama>[];
    return Scaffold(
      // 顶部橙色渐变洇染到页面背景
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [C.brand.withValues(alpha: .22), C.brand.withValues(alpha: .08), C.bg],
            stops: const [0, .18, .42],
          ),
        ),
        child: SafeArea(
        child: Column(children: [
          // 头部:标题 + 分段切换
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(gradient: C.brandGrad, borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.emoji_events, color: Colors.white, size: 19),
              ),
              const SizedBox(width: 10),
              Text(t('rank'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
              const Spacer(),
              // 分段切换
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(999)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  for (final tab in _tabs)
                    GestureDetector(
                      onTap: () => _pick(tab),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: _tab == tab ? C.brandGrad : null,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(t(tab), style: TextStyle(color: _tab == tab ? Colors.white : C.ink2, fontWeight: _tab == tab ? FontWeight.w600 : FontWeight.w400, fontSize: 12)),
                      ),
                    ),
                ]),
              ),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: C.brand))
                : ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 20), children: [
                    // TOP3 领奖台(2-1-3)
                    if (top3.length >= 3)
                      SizedBox(
                        height: 220,
                        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Expanded(child: _podium(top3[1], 2)),
                          const SizedBox(width: 10),
                          Expanded(child: _podium(top3[0], 1, big: true)),
                          const SizedBox(width: 10),
                          Expanded(child: _podium(top3[2], 3)),
                        ]),
                      ),
                    const SizedBox(height: 14),
                    // 4 名以后
                    Container(
                      decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.line)),
                      child: Column(children: [
                        for (var i = 0; i < rest.length; i++) ...[
                          _row(rest[i], i + 4),
                          if (i < rest.length - 1) Divider(height: 1, color: C.line, indent: 64),
                        ],
                      ]),
                    ),
                  ]),
          ),
        ]),
        ),
      ),
    );
  }

  // 领奖台位(第 1 名更大,带皇冠)
  Widget _podium(Drama d, int rank, {bool big = false}) {
    final medal = _medals[rank - 1];
    return GestureDetector(
      onTap: () => context.push('/drama/${d.id}'),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (big) Icon(Icons.workspace_premium, color: medal, size: 22),
        Stack(clipBehavior: Clip.none, children: [
          Container(
            height: big ? 150 : 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: medal, width: 2),
              boxShadow: [BoxShadow(color: medal.withValues(alpha: .35), blurRadius: 14, offset: const Offset(0, 5))],
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox.expand(child: Cover(d)),
          ),
          Positioned(
            top: -7, left: -7,
            child: Container(
              width: 24, height: 24,
              decoration: BoxDecoration(color: medal, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
              alignment: Alignment.center,
              child: Text('$rank', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
        const SizedBox(height: 7),
        Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: C.ink)),
        const SizedBox(height: 2),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.local_fire_department, size: 12, color: C.brand),
          const SizedBox(width: 2),
          Text(d.plays, style: TextStyle(fontSize: 11, color: C.ink3)),
        ]),
      ]),
    );
  }

  // 4 名以后的行
  Widget _row(Drama d, int rank) {
    return InkWell(
      onTap: () => context.push('/drama/${d.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(children: [
          SizedBox(width: 26, child: Text('$rank', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, color: C.ink3))),
          const SizedBox(width: 6),
          ClipRRect(borderRadius: BorderRadius.circular(9), child: SizedBox(width: 52, height: 68, child: Cover(d))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            const SizedBox(height: 5),
            Row(children: [
              const Icon(Icons.local_fire_department, size: 13, color: C.brand),
              const SizedBox(width: 3),
              Text(d.plays, style: TextStyle(color: C.ink3, fontSize: 12)),
              if (d.genre.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: C.tag, borderRadius: BorderRadius.circular(5)),
                  child: Text(d.genre, style: TextStyle(color: C.tagInk, fontSize: 10)),
                ),
              ],
            ]),
          ])),
          const Icon(Icons.play_circle_outline, color: C.brand, size: 22),
        ]),
      ),
    );
  }
}
