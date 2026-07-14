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

  // 热搜榜名次色:1 红、2 橙、3 黄,其余灰
  static const _rankColors = [Color(0xFFFF3B30), Color(0xFFFF6D00), Color(0xFFFFA000)];

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>(); // 主题切换即重建,刷新 C.* 颜色
    context.watch<AppState>(); // 语言切换即重建文案
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          // 火焰渐变头图(热度榜横幅)
          Container(
            margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFFFF3B30), Color(0xFFFF6D00), Color(0xFFFF9A2B)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: const Color(0xFFFF5722).withValues(alpha: .35), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.local_fire_department, color: Colors.white, size: 26),
                const SizedBox(width: 8),
                Text(t('hotBoard'), style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w700, letterSpacing: 1)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .22), borderRadius: BorderRadius.circular(999)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(t('live'), style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              // 子榜切换(横幅内玻璃感胶囊)
              Row(children: [
                for (final tab in _tabs) ...[
                  GestureDetector(
                    onTap: () => _pick(tab),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                      decoration: BoxDecoration(
                        color: _tab == tab ? Colors.white : Colors.white.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(t(tab), style: TextStyle(
                        color: _tab == tab ? const Color(0xFFE8480A) : Colors.white,
                        fontWeight: _tab == tab ? FontWeight.w600 : FontWeight.w400, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ]),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: C.brand))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                    itemCount: _list.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: C.line.withValues(alpha: .6), indent: 40),
                    itemBuilder: (c, i) => _row(_list[i], i + 1),
                  ),
          ),
        ]),
      ),
    );
  }

  // 热搜行:大号名次数字 + 标题 + 热度值(右对齐) + 爆/热徽标
  Widget _row(Drama d, int rank) {
    final top3 = rank <= 3;
    final rankColor = top3 ? _rankColors[rank - 1] : C.ink3;
    return InkWell(
      onTap: () => context.push('/drama/${d.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
        decoration: top3
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(colors: [rankColor.withValues(alpha: .08), Colors.transparent]),
              )
            : null,
        child: Row(children: [
          // 名次
          SizedBox(
            width: 34,
            child: Text('$rank', textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: top3 ? 20 : 16, fontStyle: FontStyle.italic, fontWeight: FontWeight.w800,
                color: rankColor,
                shadows: top3 ? [Shadow(color: rankColor.withValues(alpha: .4), blurRadius: 6)] : null,
              )),
          ),
          const SizedBox(width: 8),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 44, height: 58, child: Cover(d))),
          const SizedBox(width: 12),
          // 标题 + 题材
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: top3 ? FontWeight.w600 : FontWeight.w500, fontSize: 14))),
              if (rank == 1) _badge(t('boom'), const Color(0xFFFF3B30)),
              if (rank == 2 || rank == 3) _badge(t('hotTag'), const Color(0xFFFF6D00)),
            ]),
            const SizedBox(height: 4),
            Text(d.genre, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: C.ink3, fontSize: 11)),
          ])),
          const SizedBox(width: 8),
          // 热度值
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.local_fire_department, size: 13, color: top3 ? rankColor : C.ink3),
              const SizedBox(width: 2),
              Text(d.plays, style: TextStyle(color: top3 ? rankColor : C.ink3, fontSize: 12, fontWeight: top3 ? FontWeight.w600 : FontWeight.w400)),
            ]),
          ]),
        ]),
      ),
    );
  }

  Widget _badge(String txt, Color color) => Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        child: Text(txt, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
      );
}
