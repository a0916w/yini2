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
  List<Map> _banners = [];
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
    Api.banners().then((b) { if (mounted) setState(() => _banners = b.cast<Map>()); }).catchError((_) {});
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
    Api.banners().then((b) {
      if (mounted) setState(() => _banners = b.cast<Map>());
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

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    final reqCat = _catId;
    setState(() => _loading = true);
    try {
      final (rows, page, last) = await Api.videos(categoryId: reqCat, page: reset ? 1 : (_catPage[reqCat] ?? 1) + 1);
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
    final tabs = [{'id': null, 'name': t('all')}, ..._cats.map((c) => {'id': c['id'], 'name': cleanName(c['name'] as String?)})];
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
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
          // banner:接口有数据用接口;暂有问题时回落到本地写死图
          if (_banners.isNotEmpty)
            BannerCarousel(_banners)
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.asset('assets/banner.png', fit: BoxFit.cover),
                ),
              ),
            ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 18),
              itemBuilder: (c, i) {
                final active = _catId == tabs[i]['id'];
                return GestureDetector(
                  onTap: () => _pickCat(tabs[i]['id'] as int?),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('${tabs[i]['name']}',
                        style: TextStyle(fontSize: active ? 17 : 15, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? C.ink : C.ink3)),
                    const SizedBox(height: 4),
                    Container(width: 18, height: 3, decoration: BoxDecoration(gradient: active ? C.brandGrad : null, borderRadius: BorderRadius.circular(3))),
                  ]),
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
          Expanded(
            child: _list.isEmpty && _loading
                ? const Center(child: CircularProgressIndicator(color: C.brand))
                : RefreshIndicator(
                    color: C.brand,
                    onRefresh: () => _load(reset: true),
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 16, childAspectRatio: .52),
                      itemCount: _list.length + 1,
                      itemBuilder: (c, i) {
                        if (i == _list.length) {
                          if (_page < _lastPage) {
                            return Center(
                              child: TextButton(onPressed: _loading ? null : () => _load(), child: Text(_loading ? t('loading') : t('loadMore'))),
                            );
                          }
                          return const SizedBox();
                        }
                        return DramaCard(_list[i]);
                      },
                    ),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(gradient: C.brandGrad, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: const Text('橙', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/search'),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(999)),
                child: Row(children: [
                  Icon(Icons.search, size: 15, color: C.ink3),
                  const SizedBox(width: 6),
                  Expanded(child: Text(t('searchPh'), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: C.ink3, fontSize: 12))),
                ]),
              ),
            ),
          ),
          _iconBtn(Icons.history, () => _toast(context, '暂无观看记录')),
          _iconBtn(Icons.notifications_none, () => _toast(context, '暂无消息'), dot: true),
          // 会员
          GestureDetector(
            onTap: () => context.push('/vip'),
            child: Container(
              height: 30, padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: C.brand.withValues(alpha: .4))),
              alignment: Alignment.center,
              child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.diamond_outlined, size: 13, color: C.brand), SizedBox(width: 3), Text('会员', style: TextStyle(color: C.brand, fontWeight: FontWeight.w500, fontSize: 12))]),
            ),
          ),
          // 语言
          GestureDetector(
            onTap: () => _pickLang(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.language, size: 18, color: C.ink2),
                const SizedBox(width: 2),
                Text(_langShort(), style: TextStyle(fontSize: 11, color: C.ink2, fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
          _iconBtn(Icons.qr_code_scanner, () => _toast(context, '扫码')),
        ]),
      );

  Widget _iconBtn(IconData icon, VoidCallback onTap, {bool dot = false}) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Stack(clipBehavior: Clip.none, children: [
            Icon(icon, size: 21, color: C.ink2),
            if (dot) Positioned(right: -1, top: -1, child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: C.brand, shape: BoxShape.circle))),
          ]),
        ),
      );

  String _langShort() {
    const m = {'zh': '中', 'en': 'EN', 'vi': 'VI', 'th': 'TH', 'id': 'ID'};
    return m[Http.lang] ?? Http.lang.toUpperCase();
  }

  void _toast(BuildContext c, String s) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(s), duration: const Duration(seconds: 1)));

  void _pickLang(BuildContext context) {
    showModalBottomSheet(context: context, builder: (c) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final l in languages)
          ListTile(
            title: Text(l.$2),
            trailing: Http.lang == l.$1 ? const Icon(Icons.check, color: C.brand) : null,
            onTap: () { context.read<AppState>().setLanguage(l.$1); Navigator.pop(c); },
          ),
      ]),
    ));
  }
}
