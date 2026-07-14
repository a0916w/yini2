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
  List<Map> _cats = [];
  int? _catId; // null = 全部
  final List<Drama> _list = [];
  List<Drama> _latest = [], _hot = [];
  int _page = 1, _lastPage = 1;
  bool _loading = false;
  String _marquee = '';
  AppState? _app;
  String _lang = Http.lang;

  // 分类数据分桶缓存(按 categoryId,null=全部),切换即时命中
  final Map<int?, List<Drama>> _catCache = {};
  final Map<int?, int> _catPage = {}, _catLast = {};

  void _onApp() {
    if (_app!.lang != _lang) { _lang = _app!.lang; _reloadAll(); }
  }

  void _fetchSections() {
    Api.latest().then((r) { if (mounted) setState(() => _latest = r); }).catchError((_) {});
    Api.videos(perPage: 50).then((r) {
      final rows = r.$1..sort((a, b) => b.viewCount - a.viewCount);
      if (mounted) setState(() => _hot = rows);
    }).catchError((_) {});
    Api.marquees().then((m) {
      final txt = m.map((e) => '${(e as Map)['content']}').where((s) => s.isNotEmpty).join('　　');
      if (mounted && txt.isNotEmpty) setState(() => _marquee = txt);
    }).catchError((_) {});
  }

  void _reloadAll() {
    _catCache.clear(); _catPage.clear(); _catLast.clear();
    Api.categories().then((c) { if (mounted) { setState(() => _cats = c.cast<Map>()); _prefetchCats(); } }).catchError((_) {});
    _fetchSections();
    setState(() { _catId = null; _list.clear(); });
    _load(reset: true);
  }

  @override
  void initState() {
    super.initState();
    _app = context.read<AppState>();
    _app!.addListener(_onApp);
    Api.categories().then((c) {
      if (mounted) { setState(() => _cats = c.cast<Map>()); _prefetchCats(); }
    }).catchError((_) {});
    _fetchSections();
    _load(reset: true);
  }

  // 后台预取每个分类首页,点 tab 时已在内存缓存里 → 零等待
  void _prefetchCats() {
    for (final c in _cats) {
      final id = c['id'] as int?;
      if (id == null || _catCache.containsKey(id)) continue;
      Api.videos(categoryId: id).then((r) {
        if (!mounted) return;
        _catCache[id] = r.$1; _catPage[id] = r.$2; _catLast[id] = r.$3;
        for (final d in r.$1.take(9)) { Api.prefetchDetail(d.id); }
      }).catchError((_) {});
    }
  }

  Future<void> _load({bool reset = false, bool fresh = false}) async {
    if (_loading) return;
    final reqCat = _catId;
    setState(() => _loading = true);
    try {
      final (rows, page, last) = await Api.videos(categoryId: reqCat, page: reset ? 1 : (_catPage[reqCat] ?? 1) + 1, fresh: fresh);
      final full = reset ? <Drama>[] : List<Drama>.of(_catCache[reqCat] ?? _list);
      full.addAll(rows);
      _catCache[reqCat] = full; _catPage[reqCat] = page; _catLast[reqCat] = last;
      if (mounted && _catId == reqCat) {
        setState(() {
          _list..clear()..addAll(full);
          _page = page;
          _lastPage = last;
        });
      }
      // 预取前若干部详情,点进详情/播放秒开
      for (final d in rows.take(9)) {
        Api.prefetchDetail(d.id);
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _app?.removeListener(_onApp);
    super.dispose();
  }

  void _pickCat(int? id) {
    if (_catId == id) return;
    _catId = id;
    final cached = _catCache[id];
    if (cached != null) {
      // 命中缓存:即时渲染,不转圈
      setState(() {
        _list..clear()..addAll(cached);
        _page = _catPage[id] ?? 1;
        _lastPage = _catLast[id] ?? 1;
        _loading = false;
      });
    } else {
      setState(() => _list.clear());
      _load(reset: true);
    }
  }

  // 伪评分(按 id 稳定生成 8.8~9.8)
  static String _rating(int id) => (8.8 + (id % 11) / 10).toStringAsFixed(1);

  // 设计色
  static const _accent = Color(0xFF9E1B2E); // 深红强调
  static const _badge = Color(0xFF7A1420);  // 「新」徽标

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
    final tabs = [{'id': null, 'name': t('all')}, ..._cats.map((c) => {'id': c['id'], 'name': cleanName(c['name'] as String?)})];
    final hero = _hot.isNotEmpty ? _hot.first : null;
    final fresh3 = _latest.take(3).toList();
    final watching = _hot.skip(1).take(4).toList();

    // 顶部整块随内容滚动
    final top = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // 暗红头部区(标题浮于其上,hero 卡一半压在暗区一半压在页面底色上)
      Stack(children: [
        Positioned.fill(
          child: Column(children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [const Color(0xFF33070F), const Color(0xFF33070F).withValues(alpha: .0)],
                    stops: const [0, 1],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 90), // hero 下半段露出页面底色
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 标题行(白字,暗区上)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 2),
                Text(t('cinema'), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
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
          // 今日主打 hero 卡
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
          child: Row(children: [
            for (var i = 0; i < fresh3.length; i++) ...[
              Expanded(child: _newCard(fresh3[i])),
              if (i < fresh3.length - 1) const SizedBox(width: 12),
            ],
          ]),
        ),
      ],
      // 大家都在看
      if (watching.isNotEmpty) ...[
        _sectionTitle(t('everyoneWatching')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            for (var r = 0; r < watching.length; r += 2)
              Padding(
                padding: EdgeInsets.only(bottom: r + 2 < watching.length + 1 ? 12 : 0),
                child: Row(children: [
                  Expanded(child: _hotCard(watching[r])),
                  const SizedBox(width: 12),
                  Expanded(child: r + 1 < watching.length ? _hotCard(watching[r + 1]) : const SizedBox()),
                ]),
              ),
          ]),
        ),
      ],
      // 全部剧集(分类胶囊 + 网格)
      _sectionTitle(t('allDramas')),
      SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: tabs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 9),
          itemBuilder: (c, i) {
            final active = _catId == tabs[i]['id'];
            return GestureDetector(
              onTap: () => _pickCat(tabs[i]['id'] as int?),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: active ? C.brandGrad : null,
                  color: active ? null : C.surface2,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: active ? [BoxShadow(color: C.brand.withValues(alpha: .3), blurRadius: 10, offset: const Offset(0, 3))] : null,
                ),
                child: Text('${tabs[i]['name']}',
                    style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? Colors.white : C.ink2)),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 4),
    ]);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: C.brand,
          onRefresh: () async { _fetchSections(); await _load(reset: true, fresh: true); },
          child: CustomScrollView(slivers: [
            SliverToBoxAdapter(child: top),
            if (_list.isEmpty && _loading)
              const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator(color: C.brand)))
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: .57),
                  delegate: SliverChildBuilderDelegate((c, i) => DramaCard(_list[i]), childCount: _list.length),
                ),
              ),
              SliverToBoxAdapter(
                child: _page < _lastPage
                    ? Center(child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextButton(onPressed: _loading ? null : () => _load(), child: Text(_loading ? t('loading') : t('loadMore'))),
                      ))
                    : const SizedBox(height: 16),
              ),
            ],
          ]),
        ),
      ),
    );
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
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: g[1].withValues(alpha: .45), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // 今日主打 chip
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
                // 立即看按钮
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
          Container(width: 4, height: 17, decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
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
              ClipRRect(borderRadius: BorderRadius.circular(13), child: Cover(d)),
              Positioned(top: 0, left: 0, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: const BoxDecoration(color: _badge, borderRadius: BorderRadius.only(topLeft: Radius.circular(13), bottomRight: Radius.circular(11))),
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

  // ── 大家都在看卡:评分徽标 ──
  Widget _hotCard(Drama d) => GestureDetector(
        onTap: () => context.push('/drama/${d.id}'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(fit: StackFit.expand, children: [
              ClipRRect(borderRadius: BorderRadius.circular(14), child: Cover(d)),
              Positioned(top: 8, right: 8, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: .45), borderRadius: BorderRadius.circular(8)),
                child: Text('★${_rating(d.id)}', style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 12, fontWeight: FontWeight.w700)),
              )),
            ]),
          ),
          const SizedBox(height: 7),
          Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: C.ink)),
        ]),
      );
}
