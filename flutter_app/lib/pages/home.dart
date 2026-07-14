import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../api/api.dart';
import '../api/http.dart';
import '../api/models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import '../i18n.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Drama> _latest = [], _hot = [];
  String _marquee = '';
  AppState? _app;
  String _lang = Http.lang;

  void _onApp() {
    if (_app!.lang != _lang) { _lang = _app!.lang; _fetchSections(); }
  }

  void _fetchSections() {
    Api.latest().then((r) { if (mounted) setState(() => _latest = r); }).catchError((_) {});
    Api.videos(perPage: 50).then((r) {
      final rows = r.$1..sort((a, b) => b.viewCount - a.viewCount);
      if (mounted) setState(() => _hot = rows);
      for (final d in rows.take(9)) { Api.prefetchDetail(d.id); }
    }).catchError((_) {});
    Api.marquees().then((m) {
      final txt = m.map((e) => '${(e as Map)['content']}').where((s) => s.isNotEmpty).join('　　');
      if (mounted && txt.isNotEmpty) setState(() => _marquee = txt);
    }).catchError((_) {});
  }

  @override
  void initState() {
    super.initState();
    _app = context.read<AppState>();
    _app!.addListener(_onApp);
    _fetchSections();
  }

  @override
  void dispose() {
    _app?.removeListener(_onApp);
    super.dispose();
  }

  // 伪评分(按 id 稳定生成 8.8~9.8)
  static String _rating(int id) => (8.8 + (id % 11) / 10).toStringAsFixed(1);
  // 瀑布流封面宽高比(按 id 稳定,竖版直图)
  static double _aspect(int id) => const [.72, .62, .78, .66, .7][id % 5];

  // 设计色
  static const _badge = C.brandDeep; // 「新」徽标(品牌橙)

  // hero 渐变(按 id 循环,深邃浓郁)
  static const _heroGrads = [
    [Color(0xFF2D63E8), Color(0xFF0A1240)],
    [Color(0xFFC2183B), Color(0xFF33060F)],
    [Color(0xFF7C4DFF), Color(0xFF1A0C4A)],
    [Color(0xFF00ACC1), Color(0xFF06282E)],
    [Color(0xFFE8480A), Color(0xFF3A1002)],
  ];

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>(); // 主题切换即重建,刷新 C.* 颜色
    context.watch<AppState>(); // 语言切换即重建文案
    final hero = _hot.isNotEmpty ? _hot.first : null;
    final fresh3 = _latest.take(3).toList();
    final watching = _hot.length > 1 ? _hot.sublist(1) : <Drama>[];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: C.brand,
          onRefresh: () async => _fetchSections(),
          child: _hot.isEmpty && _latest.isEmpty
              ? const Center(child: CircularProgressIndicator(color: C.brand))
              : ListView(padding: EdgeInsets.zero, children: [
                  // 暗红头部区 + 今日主打
                  Stack(children: [
                    Positioned.fill(
                      child: Column(children: [
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                colors: [const Color(0xFF241005), const Color(0xFF241005).withValues(alpha: .0)],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 90), // hero 下半段露出页面底色
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const SizedBox(height: 2),
                            PageTitle(t('cinema'), color: Colors.white),
                            const SizedBox(height: 8),
                            Text(tp('cinemaSub2', {'n': _latest.isEmpty ? '…' : '${_latest.length}'}),
                                style: TextStyle(color: Colors.white.withValues(alpha: .55), fontSize: 13)),
                          ])),
                          GestureDetector(
                            onTap: () => context.push('/search'),
                            child: Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), shape: BoxShape.circle),
                              child: const Icon(Icons.search, size: 20, color: Colors.white),
                            ),
                          ),
                        ]),
                      ),
                      if (hero != null) _heroCard(hero),
                    ]),
                  ]),
                  if (_marquee.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: C.brand.withValues(alpha: .10), borderRadius: BorderRadius.circular(999)),
                      child: Row(children: [
                        const Icon(Icons.campaign_outlined, size: 15, color: C.brand),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_marquee, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: C.ink2, fontSize: 12))),
                      ]),
                    ),
                  // 新剧首发
                  if (fresh3.isNotEmpty) ...[
                    _sectionTitle(t('newSection'), suffix: t('dailyNew')),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        for (var i = 0; i < fresh3.length; i++) ...[
                          Expanded(child: _newCard(fresh3[i])),
                          if (i < fresh3.length - 1) const SizedBox(width: 12),
                        ],
                      ]),
                    ),
                  ],
                  // 大家都在看(竖版封面瀑布流)
                  if (watching.isNotEmpty) ...[
                    _sectionTitle(t('everyoneWatching')),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: _waterfall(watching),
                    ),
                  ],
                ]),
        ),
      ),
    );
  }

  // ── 瀑布流:两列错落,按累计高度分配 ──
  Widget _waterfall(List<Drama> items) {
    final left = <Drama>[], right = <Drama>[];
    double lh = 0, rh = 0;
    for (final d in items) {
      final h = 1 / _aspect(d.id); // 相对高度
      if (lh <= rh) { left.add(d); lh += h; } else { right.add(d); rh += h; }
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(children: [for (final d in left) _hotCard(d)])),
      const SizedBox(width: 12),
      Expanded(child: Column(children: [for (final d in right) _hotCard(d)])),
    ]);
  }

  // ── 今日主打 hero 卡 ──
  Widget _heroCard(Drama d) {
    final g = _heroGrads[d.id % _heroGrads.length];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => context.push('/drama/${d.id}'),
        child: Container(
          height: 190,
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: g),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: g[1].withValues(alpha: .45), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
                child: Text(t('todayPick'), style: const TextStyle(color: _badge, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
              const SizedBox(height: 7),
              Row(children: [
                Expanded(
                  child: Text('★${_rating(d.id)} · ${d.plays}${t('playsLabel')}', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 13)),
                ),
                GestureDetector(
                  onTap: () => context.push('/watch/${d.id}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.play_arrow, size: 17, color: _badge),
                      const SizedBox(width: 4),
                      Text(t('watchNow2'), style: const TextStyle(color: _badge, fontSize: 13.5, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  // ── 区块标题:深红竖条 + 标题 + 灰色后缀 ──
  Widget _sectionTitle(String title, {String? suffix}) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(width: 4, height: 15, decoration: BoxDecoration(gradient: C.brandGrad, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          if (suffix != null) ...[
            const SizedBox(width: 8),
            Padding(padding: const EdgeInsets.only(bottom: 1), child: Text(suffix, style: TextStyle(color: C.ink3, fontSize: 12))),
          ],
        ]),
      );

  // ── 新剧首发卡:新徽标 + 底部播放量 ──
  Widget _newCard(Drama d) => GestureDetector(
        onTap: () => context.push('/drama/${d.id}'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(fit: StackFit.expand, children: [
              ClipRRect(borderRadius: BorderRadius.circular(12), child: Cover(d)),
              Positioned(top: 0, left: 0, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: const BoxDecoration(color: _badge, borderRadius: BorderRadius.only(topLeft: Radius.circular(12), bottomRight: Radius.circular(10))),
                child: Text(t('newBadge'), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              )),
              Positioned(left: 9, bottom: 8, child: Text('▶ ${d.plays}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, shadows: [Shadow(blurRadius: 5, color: Colors.black87)]))),
            ]),
          ),
          const SizedBox(height: 7),
          Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: C.ink)),
        ]),
      );

  // ── 瀑布流卡:竖版直图 + 评分徽标 ──
  Widget _hotCard(Drama d) => GestureDetector(
        onTap: () => context.push('/drama/${d.id}'),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AspectRatio(
              aspectRatio: _aspect(d.id),
              child: Stack(fit: StackFit.expand, children: [
                ClipRRect(borderRadius: BorderRadius.circular(14), child: Cover(d)),
                Positioned(top: 8, right: 8, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: .45), borderRadius: BorderRadius.circular(8)),
                  child: Text('★${_rating(d.id)}', style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 12, fontWeight: FontWeight.w700)),
                )),
                Positioned(left: 9, bottom: 8, child: Text('▶ ${d.plays}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, shadows: [Shadow(blurRadius: 5, color: Colors.black87)]))),
              ]),
            ),
            const SizedBox(height: 7),
            Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: C.ink)),
            if (d.genre.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(d.genre, style: TextStyle(fontSize: 11, color: C.ink3)),
            ],
          ]),
        ),
      );
}
