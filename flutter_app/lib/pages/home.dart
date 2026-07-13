import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../api/api.dart';
import '../api/models.dart';
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

  @override
  void initState() {
    super.initState();
    Api.categories().then((c) {
      if (mounted) setState(() => _cats = c.cast<Map>());
    }).catchError((_) {});
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final (rows, page, last) = await Api.videos(categoryId: _catId, page: reset ? 1 : _page + 1);
      setState(() {
        if (reset) _list.clear();
        _list.addAll(rows);
        _page = page;
        _lastPage = last;
      });
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _pickCat(int? id) {
    setState(() => _catId = id);
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [{'id': null, 'name': t('all')}, ..._cats.map((c) => {'id': c['id'], 'name': cleanName(c['name'] as String?)})];
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          _header(context),
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
                  child: Center(
                    child: Text('${tabs[i]['name']}',
                        style: TextStyle(fontSize: active ? 17 : 15, fontWeight: active ? FontWeight.w800 : FontWeight.w500, color: active ? C.ink : C.ink3)),
                  ),
                );
              },
            ),
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
                        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 18, childAspectRatio: .82),
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
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(gradient: C.brandGrad, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: const Text('橙', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/search'),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(999)),
                child: Row(children: [
                  const Icon(Icons.search, size: 15, color: C.ink3),
                  const SizedBox(width: 7),
                  Text(t('searchPh'), style: const TextStyle(color: C.ink3, fontSize: 13)),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => context.push('/vip'),
            child: Container(
              height: 30, padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: C.brand.withValues(alpha: .4))),
              alignment: Alignment.center,
              child: Row(children: [const Icon(Icons.diamond_outlined, size: 14, color: C.brand), const SizedBox(width: 4), Text(t('vip'), style: const TextStyle(color: C.brand, fontWeight: FontWeight.w700, fontSize: 13))]),
            ),
          ),
        ]),
      );
}
