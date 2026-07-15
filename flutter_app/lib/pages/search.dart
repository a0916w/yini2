import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../api/api.dart';
import '../api/models.dart';
import '../i18n.dart';
import '../theme.dart';
import '../widgets.dart';

// 搜索(果橙):圆钮返回 + 暖底输入胶囊;热搜榜为真实热播数据
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _ctrl = TextEditingController();
  List<Drama> _results = [];
  List<Drama> _hot = [];
  bool _loading = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    // 真实热搜:按播放量取 TOP10(命中缓存零等待)
    Api.videos(perPage: 50).then((r) {
      final rows = r.$1..sort((a, b) => b.viewCount - a.viewCount);
      if (mounted) setState(() => _hot = rows.take(10).toList());
    }).catchError((_) {});
  }

  Future<void> _run() async {
    final kw = _ctrl.text.trim();
    if (kw.isEmpty) return;
    setState(() { _loading = true; _done = true; });
    try {
      final (rows, _, _) = await Api.videos(keyword: kw, perPage: 30);
      setState(() => _results = rows);
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<ThemeController>().dark;
    return Scaffold(
      body: Container(
        decoration: pageTopGrad(dark),
        child: SafeArea(
          child: Column(children: [
            // 顶栏:返回圆钮 + 输入胶囊 + 搜索
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
              child: Row(children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(color: C.surface, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: C.brand.withValues(alpha: .12), blurRadius: 10, offset: const Offset(0, 3))]),
                    child: Icon(Icons.arrow_back_ios_new, size: 15, color: C.ink),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: dark ? C.surface2 : Colors.white.withValues(alpha: .9),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(children: [
                      Icon(Icons.search, size: 15, color: C.ink3),
                      const SizedBox(width: 7),
                      Expanded(child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _run(),
                        style: TextStyle(fontSize: 13, color: C.ink),
                        decoration: InputDecoration(
                          hintText: t('typeKeyword'),
                          hintStyle: TextStyle(fontSize: 13, color: C.quiet),
                          isCollapsed: true,
                          border: InputBorder.none,
                        ),
                      )),
                    ]),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _run,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: C.brand, borderRadius: BorderRadius.circular(100),
                      boxShadow: [BoxShadow(color: C.brand.withValues(alpha: .35), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Text(t('search'), style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: C.brand))
                  : !_done
                      ? _hotList()
                      : _results.isEmpty
                          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.search_off, size: 44, color: C.quiet),
                              const SizedBox(height: 12),
                              Text(tp('noResult', {'q': _ctrl.text.trim()}), style: TextStyle(color: C.ink3)),
                            ]))
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                              itemCount: _results.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (c, i) => DramaRow(_results[i]),
                            ),
            ),
          ]),
        ),
      ),
    );
  }

  // 热搜榜:真实热播 TOP10(名次 italic 900 + 小封面 + 播放量)
  Widget _hotList() => ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Text(t('hotSearch'), style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: C.ink)),
              const SizedBox(width: 8),
              const Icon(Icons.local_fire_department, size: 16, color: C.brand),
            ]),
          ),
          if (_hot.isEmpty)
            const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: CircularProgressIndicator(color: C.brand)))
          else
            for (var i = 0; i < _hot.length; i++)
              GestureDetector(
                onTap: () => context.push('/drama/${_hot[i].id}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    SizedBox(width: 24, child: Text('${i + 1}', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, fontWeight: FontWeight.w900,
                            color: i < 3 ? const Color(0xFFFF4D1F) : const Color(0xFFC9B8A6)))),
                    const SizedBox(width: 10),
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 36, height: 48, child: Cover(_hot[i], showTitle: false))),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_hot[i].title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.ink))),
                    const SizedBox(width: 8),
                    Text('▶ ${_hot[i].plays}', style: TextStyle(fontSize: 11, color: C.ink3)),
                  ]),
                ),
              ),
        ],
      );
}
