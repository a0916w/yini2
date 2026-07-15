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

// 榜单(handoff: rank 屏)——浅橙渐变、前三领奖台(皇冠)、暖底列表卡
class TrendsPage extends StatefulWidget {
  const TrendsPage({super.key});
  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> {
  // 飙升榜 / 热播榜 / 新剧榜
  final _tabs = ['soar', 'hotPlay', 'newList'];
  String _tab = 'soar';
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
    if (tab == 'soar') return Api.recommended();
    if (tab == 'newList') return Api.latest();
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

  // 榜单名次色(规范)
  static const _rank1 = Color(0xFFFF4D1F);
  static const _rank2 = Color(0xFFB8AFA6);
  static const _rank3 = Color(0xFFD3A26A);
  static const _rankRest = Color(0xFFC9B8A6);

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<ThemeController>().dark;
    context.watch<AppState>(); // 语言切换即重建文案
    final top3 = _list.take(3).toList();
    final rest = _list.length > 3 ? _list.sublist(3) : <Drama>[];
    return Scaffold(
      body: Container(
        decoration: pageTopGrad(dark),
        child: SafeArea(
          bottom: false,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: C.brand))
              : ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 24), children: [
                  PageTitle(t('rankTitle'), sub: t('rankSub')),
                  const SizedBox(height: 14),
                  // 榜单切换胶囊
                  Row(children: [
                    for (final tab in _tabs) ...[
                      GestureDetector(
                        onTap: () => _pick(tab),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                          decoration: BoxDecoration(
                            color: _tab == tab ? C.brand : (dark ? C.surface2 : Colors.white.withValues(alpha: .85)),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(t(tab), style: TextStyle(
                              fontSize: 12, fontWeight: _tab == tab ? FontWeight.w700 : FontWeight.w600,
                              color: _tab == tab ? Colors.white : C.ink2)),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ]),
                  // 前三领奖台
                  if (top3.length >= 3) ...[
                    const SizedBox(height: 20),
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Expanded(flex: 100, child: _podium(top3[1], 2, _rank2)),
                      const SizedBox(width: 10),
                      Expanded(flex: 120, child: _podium(top3[0], 1, _rank1, crown: true)),
                      const SizedBox(width: 10),
                      Expanded(flex: 100, child: _podium(top3[2], 3, _rank3)),
                    ]),
                  ],
                  const SizedBox(height: 16),
                  // 4名以后:暖底列表卡
                  for (var i = 0; i < rest.length; i++) ...[
                    _row(rest[i], i + 4),
                    if (i < rest.length - 1) const SizedBox(height: 10),
                  ],
                ]),
        ),
      ),
    );
  }

  // 领奖台位:3:4 封面 + 名次数字 + 热度值;第1名列更宽更大,带皇冠
  Widget _podium(Drama d, int rank, Color rankColor, {bool crown = false}) {
    return GestureDetector(
      onTap: () => context.push('/drama/${d.id}'),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (crown) CustomPaint(size: const Size(26, 16), painter: _CrownPainter()),
        if (crown) const SizedBox(height: 2),
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: crown
                  ? [BoxShadow(color: coverColor(d.id).withValues(alpha: .32), blurRadius: 24, offset: const Offset(0, 10))]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Cover(d, showTitle: false),
          ),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('$rank', style: TextStyle(fontSize: crown ? 19 : 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: rankColor)),
          const SizedBox(width: 5),
          Text(d.plays, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: C.brand)),
        ]),
      ]),
    );
  }

  // 4名以后行:暖底卡 r16(名次、缩略、剧名+类型·热度、看剧胶囊)
  Widget _row(Drama d, int rank) {
    return Container(
      decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        SizedBox(width: 22, child: Text('$rank', textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: _rankRest))),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => context.push('/drama/${d.id}'),
          child: ClipRRect(borderRadius: BorderRadius.circular(9), child: SizedBox(width: 44, height: 58, child: Cover(d))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/drama/${d.id}'),
            behavior: HitTestBehavior.opaque,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.ink)),
              const SizedBox(height: 4),
              Text('${d.genre.isEmpty ? '' : '${d.genre} · '}${tp('heatN', {'n': d.plays})}',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: C.ink3)),
            ]),
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/watch/${d.id}'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: C.brand, borderRadius: BorderRadius.circular(100)),
            child: Text(t('watchBtn'), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

// 皇冠(规范 SVG:M2 14L1 4l7 4 5-7 5 7 7-4-1 10H2z,#FFB020)
class _CrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 26, sy = size.height / 16;
    final p = Path()
      ..moveTo(2 * sx, 14 * sy)
      ..lineTo(1 * sx, 4 * sy)
      ..lineTo(8 * sx, 8 * sy)
      ..lineTo(13 * sx, 1 * sy)
      ..lineTo(18 * sx, 8 * sy)
      ..lineTo(25 * sx, 4 * sy)
      ..lineTo(24 * sx, 14 * sy)
      ..close();
    canvas.drawPath(p, Paint()..color = C.crown);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
