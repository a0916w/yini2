import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api.dart';
import '../api/http.dart';
import '../api/models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class TrendsPage extends StatefulWidget {
  const TrendsPage({super.key});
  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> {
  final _tabs = ['最热', '最新', '推荐'];
  String _tab = '最热';
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
    if (tab == '最新') return Api.latest();
    if (tab == '推荐') return Api.recommended();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('榜单'), centerTitle: false),
      body: Column(children: [
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            itemCount: _tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (c, i) {
              final active = _tab == _tabs[i];
              return GestureDetector(
                onTap: () => _pick(_tabs[i]),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: active ? C.brand.withValues(alpha: .12) : C.surface2,
                    borderRadius: BorderRadius.circular(999),
                    border: active ? Border.all(color: C.brand.withValues(alpha: .4)) : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(_tabs[i], style: TextStyle(color: active ? C.brand : C.ink2, fontWeight: active ? FontWeight.w500 : FontWeight.w400, fontSize: 13)),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: C.brand))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: _list.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: C.line),
                  itemBuilder: (c, i) => DramaRow(_list[i], rank: i + 1),
                ),
        ),
      ]),
    );
  }
}
