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

  // 金 / 银 / 铜金属渐变(ShaderMask 用)
  static const _metals = [
    [Color(0xFFF9E7A0), Color(0xFFE3B341), Color(0xFFA97814)], // 金
    [Color(0xFFF2F5FA), Color(0xFFB9C2D0), Color(0xFF7E8A9E)], // 银
    [Color(0xFFF0C9A2), Color(0xFFCE8B4E), Color(0xFF8C5527)], // 铜
  ];

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>(); // 主题切换即重建,刷新 C.* 颜色
    context.watch<AppState>(); // 语言切换即重建文案
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          // 鎏金深色横幅(不随主题变化,自成一体)
          Container(
            margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF23253C), Color(0xFF15161F)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .28), blurRadius: 22, offset: const Offset(0, 9))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // 鎏金大标题
                  ShaderMask(
                    shaderCallback: (r) => const LinearGradient(colors: [Color(0xFFF9E7A0), Color(0xFFE3B341)]).createShader(r),
                    child: Text(t('rank'), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: 4)),
                  ),
                  const SizedBox(height: 6),
                  Text(t('rankDesc'), style: TextStyle(color: Colors.white.withValues(alpha: .45), fontSize: 11, letterSpacing: .5)),
                ])),
                // 鎏金奖杯圆标
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF9E7A0), Color(0xFFB98A1E)]),
                    boxShadow: [BoxShadow(color: const Color(0xFFE3B341).withValues(alpha: .4), blurRadius: 16)],
                  ),
                  child: const Icon(Icons.emoji_events, color: Color(0xFF3D2E08), size: 24),
                ),
              ]),
              const SizedBox(height: 16),
              // 子榜切换:金色描边极简胶囊
              Row(children: [
                for (final tab in _tabs) ...[
                  GestureDetector(
                    onTap: () => _pick(tab),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                      decoration: BoxDecoration(
                        color: _tab == tab ? const Color(0xFFE3B341).withValues(alpha: .16) : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _tab == tab ? const Color(0xFFE3B341) : Colors.white.withValues(alpha: .18)),
                      ),
                      child: Text(t(tab), style: TextStyle(
                        color: _tab == tab ? const Color(0xFFF0D284) : Colors.white.withValues(alpha: .55),
                        fontWeight: _tab == tab ? FontWeight.w600 : FontWeight.w400, fontSize: 12, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ]),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: C.brand))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                    itemCount: _list.length,
                    itemBuilder: (c, i) => _row(_list[i], i + 1),
                  ),
          ),
        ]),
      ),
    );
  }

  // 榜单行:金属名次 + 大封面 + 留白,克制干净
  Widget _row(Drama d, int rank) {
    final top3 = rank <= 3;
    return InkWell(
      onTap: () => context.push('/drama/${d.id}'),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: top3 ? 12 : 10),
        child: Row(children: [
          // 名次:TOP3 金属渐变大字,其余细体灰
          SizedBox(
            width: 44,
            child: top3
                ? ShaderMask(
                    shaderCallback: (r) => LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: _metals[rank - 1],
                    ).createShader(r),
                    child: Text('$rank', textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, height: 1)),
                  )
                : Text('$rank', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w300, color: C.ink3, height: 1)),
          ),
          const SizedBox(width: 10),
          // 封面:TOP3 更大,金属细描边
          Container(
            width: top3 ? 62 : 52,
            height: top3 ? 82 : 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: top3 ? Border.all(color: _metals[rank - 1][1].withValues(alpha: .8), width: 1.5) : null,
              boxShadow: top3 ? [BoxShadow(color: _metals[rank - 1][1].withValues(alpha: .25), blurRadius: 12, offset: const Offset(0, 4))] : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Cover(d),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: top3 ? FontWeight.w600 : FontWeight.w500, fontSize: top3 ? 15 : 14)),
            const SizedBox(height: 5),
            Row(children: [
              if (d.genre.isNotEmpty) ...[
                Text(d.genre, style: TextStyle(color: C.ink3, fontSize: 11)),
                Container(width: 3, height: 3, margin: const EdgeInsets.symmetric(horizontal: 6), decoration: BoxDecoration(color: C.ink3.withValues(alpha: .6), shape: BoxShape.circle)),
              ],
              Icon(Icons.play_arrow_rounded, size: 13, color: C.ink3),
              const SizedBox(width: 1),
              Text(d.plays, style: TextStyle(color: C.ink3, fontSize: 11)),
            ]),
          ])),
          Icon(Icons.chevron_right, color: C.ink3.withValues(alpha: .5), size: 20),
        ]),
      ),
    );
  }
}
