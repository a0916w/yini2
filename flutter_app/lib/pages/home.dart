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

// 剧场(handoff: home 屏)——浅橙渐变、logo 顶栏、分类胶囊、Hero、新剧横滑、两列网格
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map> _cats = [];
  int? _catId; // null = 全部
  List<Drama> _latest = [], _hot = [], _catList = [];
  AppState? _app;
  String _lang = Http.lang;
  final Map<int, List<Drama>> _catCache = {};

  void _onApp() {
    if (_app!.lang != _lang) { _lang = _app!.lang; _catCache.clear(); _catId = null; _fetchAll(); }
  }

  void _fetchAll() {
    Api.categories().then((c) {
      if (mounted) setState(() => _cats = c.cast<Map>());
      // 预取各分类,切换零等待
      for (final cat in c.cast<Map>()) {
        final id = cat['id'] as int?;
        if (id == null || _catCache.containsKey(id)) continue;
        Api.videos(categoryId: id).then((r) { if (mounted) _catCache[id] = r.$1; }).catchError((_) {});
      }
    }).catchError((_) {});
    Api.latest().then((r) { if (mounted) setState(() => _latest = r); }).catchError((_) {});
    Api.videos(perPage: 50).then((r) {
      final rows = r.$1..sort((a, b) => b.viewCount - a.viewCount);
      if (mounted) setState(() => _hot = rows);
      for (final d in rows.take(9)) { Api.prefetchDetail(d.id); }
    }).catchError((_) {});
  }

  @override
  void initState() {
    super.initState();
    _app = context.read<AppState>();
    _app!.addListener(_onApp);
    _fetchAll();
  }

  @override
  void dispose() {
    _app?.removeListener(_onApp);
    super.dispose();
  }

  void _pickCat(int? id) {
    if (_catId == id) return;
    setState(() {
      _catId = id;
      _catList = id == null ? [] : (_catCache[id] ?? []);
    });
    if (id != null && _catCache[id] == null) {
      Api.videos(categoryId: id).then((r) {
        if (!mounted) return;
        _catCache[id] = r.$1;
        if (_catId == id) setState(() => _catList = r.$1);
      }).catchError((_) {});
    }
  }

  static String _rating(int id) => (8.8 + (id % 11) / 10).toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<ThemeController>().dark;
    context.watch<AppState>(); // 语言切换即重建文案
    final hero = _hot.isNotEmpty ? _hot.first : null;
    final freshList = _latest.take(8).toList();
    final watching = _hot.skip(1).take(6).toList();
    final tabs = [{'id': null, 'name': t('all')}, ..._cats.map((c) => {'id': c['id'], 'name': cleanName(c['name'] as String?)})];

    return Scaffold(
      body: Container(
        decoration: pageTopGrad(dark),
        child: SafeArea(
          bottom: false,
          child: (_hot.isEmpty && _latest.isEmpty)
              ? const Center(child: CircularProgressIndicator(color: C.brand))
              : ListView(padding: const EdgeInsets.only(bottom: 24), children: [
                  // 顶栏:YiniTV logo + 签到有礼 + 搜索圆钮
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Row(children: [
                      Text.rich(TextSpan(children: [
                        TextSpan(text: 'Yini', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -.5, color: C.ink)),
                        const TextSpan(text: 'TV', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -.5, color: C.brand)),
                      ])),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.push('/vip'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(100),
                              boxShadow: [BoxShadow(color: C.brand.withValues(alpha: .12), blurRadius: 10, offset: const Offset(0, 3))]),
                          child: Text(t('checkin'), style: const TextStyle(color: C.brand, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => context.push('/search'),
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: C.surface, shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: C.brand.withValues(alpha: .12), blurRadius: 10, offset: const Offset(0, 3))]),
                          child: Icon(Icons.search, size: 16, color: C.ink),
                        ),
                      ),
                    ]),
                  ),
                  // 分类胶囊横滑
                  SizedBox(
                    height: 46,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      itemCount: tabs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (c, i) {
                        final active = _catId == tabs[i]['id'];
                        return GestureDetector(
                          onTap: () => _pickCat(tabs[i]['id'] as int?),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                            decoration: BoxDecoration(
                              color: active ? C.brand : (dark ? C.surface2 : Colors.white.withValues(alpha: .85)),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text('${tabs[i]['name']}', style: TextStyle(
                                fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                                color: active ? Colors.white : C.ink2)),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_catId != null)
                    // 分类结果:两列网格(规范网格卡样式)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: _catList.isEmpty
                          ? const Padding(padding: EdgeInsets.only(top: 60), child: Center(child: CircularProgressIndicator(color: C.brand)))
                          : Column(children: [
                              for (var r = 0; r < _catList.length; r += 2)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(children: [
                                    Expanded(child: _gridCard(_catList[r])),
                                    const SizedBox(width: 12),
                                    Expanded(child: r + 1 < _catList.length ? _gridCard(_catList[r + 1]) : const SizedBox()),
                                  ]),
                                ),
                            ]),
                    )
                  else ...[
                    // 今日主打 Hero(200 高,r24)
                    if (hero != null) _heroCard(hero),
                    // 新剧首发:标题行 + 横滑
                    _sectionHeader(t('newSection'), chip: t('dailyNew')),
                    SizedBox(
                      height: 150,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: freshList.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (c, i) => _newCard(freshList[i]),
                      ),
                    ),
                    // 大家都在看:两列网格
                    _sectionHeader(t('everyoneWatching')),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(children: [
                        for (var r = 0; r < watching.length; r += 2)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(children: [
                              Expanded(child: _gridCard(watching[r])),
                              const SizedBox(width: 12),
                              Expanded(child: r + 1 < watching.length ? _gridCard(watching[r + 1]) : const SizedBox()),
                            ]),
                          ),
                      ]),
                    ),
                  ],
                ]),
        ),
      ),
    );
  }

  // ── 今日主打 Hero:200 高 r24,封面色底 155deg 叠加,左上白chip,左下标题/评分/立即看 ──
  Widget _heroCard(Drama d) {
    final base = coverColor(d.id);
    return GestureDetector(
      onTap: () => context.push('/drama/${d.id}'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        height: 200,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: base.withValues(alpha: .28), blurRadius: 28, offset: const Offset(0, 12))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Colors.white.withValues(alpha: .16), Colors.black.withValues(alpha: .24)],
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100)),
              child: Text(t('todayPick'), style: const TextStyle(color: C.brand, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const Spacer(),
            Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: .5)),
            const SizedBox(height: 6),
            Text.rich(TextSpan(children: [
              TextSpan(text: '★ ${_rating(d.id)}', style: const TextStyle(color: C.gold, fontWeight: FontWeight.w700)),
              TextSpan(text: ' · ${d.plays}${t('playsLabel')} · ${tp('epsAll', {'n': d.eps})}'),
            ]), style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: .85))),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.push('/watch/${d.id}'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: C.brand, borderRadius: BorderRadius.circular(100),
                  boxShadow: [BoxShadow(color: C.brand.withValues(alpha: .4), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.play_arrow, size: 15, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(t('watchNow2'), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── 区块标题行(19/800 + chip + 全部›)──
  Widget _sectionHeader(String title, {String? chip}) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text(title, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: C.ink)),
          if (chip != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: C.tag, borderRadius: BorderRadius.circular(100)),
              child: Text(chip, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: C.tagInk)),
            ),
          ],
          const Spacer(),
          Text(t('allLink'), style: TextStyle(fontSize: 12, color: C.quiet)),
        ]),
      );

  // ── 新剧首发卡:112×150 r18,「新」角标,封面内底部剧名 + ▶播放数 ──
  Widget _newCard(Drama d) => GestureDetector(
        onTap: () => context.push('/drama/${d.id}'),
        child: SizedBox(
          width: 112,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(fit: StackFit.expand, children: [
              Cover(d, showTitle: false),
              Padding(
                padding: const EdgeInsets.all(11),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.title, maxLines: 3, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, height: 1.45)),
                  const SizedBox(height: 5),
                  Text('▶ ${d.plays}', style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 10)),
                ]),
              ),
              Positioned(top: 8, left: 8, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: C.brand, borderRadius: BorderRadius.circular(100)),
                child: Text(t('newBadge'), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              )),
            ]),
          ),
        ),
      );

  // ── 大家都在看网格卡:170 高 r20,右上★评分主色chip,底部剧名+类型·在看 ──
  Widget _gridCard(Drama d) => GestureDetector(
        onTap: () => context.push('/drama/${d.id}'),
        child: SizedBox(
          height: 170,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(fit: StackFit.expand, children: [
              Cover(d, showTitle: false),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, height: 1.4)),
                  const SizedBox(height: 4),
                  Text('${d.genre.isEmpty ? '' : '${d.genre} · '}${tp('watchingN', {'n': d.plays})}',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 11)),
                ]),
              ),
              Positioned(top: 10, right: 10, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(color: C.brand, borderRadius: BorderRadius.circular(100)),
                child: Text('★ ${_rating(d.id)}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              )),
            ]),
          ),
        ),
      );
}
