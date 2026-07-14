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

  void _reloadAll() {
    _catCache.clear(); _catPage.clear(); _catLast.clear();
    Api.categories().then((c) { if (mounted) { setState(() => _cats = c.cast<Map>()); _prefetchCats(); } }).catchError((_) {});
    Api.marquees().then((m) {
      final txt = m.map((e) => '${(e as Map)['content']}').where((s) => s.isNotEmpty).join('　　');
      if (mounted) setState(() => _marquee = txt);
    }).catchError((_) {});
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
    Api.marquees().then((m) {
      final txt = m.map((e) => '${(e as Map)['content']}').where((s) => s.isNotEmpty).join('　　');
      if (mounted && txt.isNotEmpty) setState(() => _marquee = txt);
    }).catchError((_) {});
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

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>(); // 主题切换即重建,刷新 C.* 颜色
    context.watch<AppState>(); // 语言切换即重建文案
    final tabs = [{'id': null, 'name': t('all')}, ..._cats.map((c) => {'id': c['id'], 'name': cleanName(c['name'] as String?)})];
    // 顶部(头/跑马灯/banner/分类)不置顶,随内容一起滚动
    final top = Column(children: [
      _header(context),
      if (_marquee.isNotEmpty)
        Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: C.brand.withValues(alpha: .10), borderRadius: BorderRadius.circular(999)),
          child: Row(children: [
            const Icon(Icons.campaign_outlined, size: 15, color: C.brand),
            const SizedBox(width: 8),
            Expanded(child: Text(_marquee, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: C.ink2, fontSize: 12))),
          ]),
        ),
      // 分类胶囊(与全站胶囊语言一致:选中橙渐变填充)
      SizedBox(
        height: 46,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
      // 区块标题(当前分类)
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 2),
        child: Row(children: [
          Container(width: 4, height: 15, decoration: BoxDecoration(gradient: C.brandGrad, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 7),
          Text('${tabs.firstWhere((e) => e['id'] == _catId, orElse: () => tabs[0])['name']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
      ),
    ]);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: C.brand,
          onRefresh: () => _load(reset: true, fresh: true), // 下拉强制拉最新
          child: CustomScrollView(slivers: [
            SliverToBoxAdapter(child: top),
            if (_list.isEmpty && _loading)
              const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator(color: C.brand)))
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
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

  // 统一设计语言头部:大标题 + 副题 + 右侧圆形操作钮(与榜单/专题一致)
  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t('cinema'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(t('cinemaSub'), style: TextStyle(color: C.ink3, fontSize: 12.5)),
            ]),
          ),
          _circleBtn(Icons.search, () => context.push('/search')),
          const SizedBox(width: 10),
          _circleBtn(Icons.history, () => context.push('/history')),
        ]),
      );

  Widget _circleBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: C.surface2, shape: BoxShape.circle),
          child: Icon(icon, size: 19, color: C.ink2),
        ),
      );
}
