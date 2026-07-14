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

  // 名次色:1 红、2 橙、3 琥珀,其余灰
  static const _rankColors = [Color(0xFFE8362E), Color(0xFFFF6D00), Color(0xFFFFA000)];
  static const _heat = Color(0xFFE8362E);

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>(); // 主题切换即重建,刷新 C.* 颜色
    context.watch<AppState>(); // 语言切换即重建文案
    // 热度条比例基准:榜内最大播放量
    var maxV = 1;
    for (final d in _list) { if (d.viewCount > maxV) maxV = d.viewCount; }
    return Scaffold(
      // 整页同一条橙色渐变:头部与列表圆角外露处颜色连续,无接缝
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFFF8A2B), Color(0xFFE8480A)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            // 橙色渐变大头部
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t('rankTitle'), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 1)),
                const SizedBox(height: 7),
                Text(t('rankSub'), style: TextStyle(color: Colors.white.withValues(alpha: .78), fontSize: 12.5)),
                const SizedBox(height: 18),
                // 子榜:白字 + 下划线
                Row(children: [
                  for (final tab in _tabs) ...[
                    GestureDetector(
                      onTap: () => _pick(tab),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text(t(tab), style: TextStyle(
                          color: _tab == tab ? Colors.white : Colors.white.withValues(alpha: .78),
                          fontSize: 16.5, fontWeight: _tab == tab ? FontWeight.w700 : FontWeight.w400)),
                        const SizedBox(height: 7),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: _tab == tab ? 44 : 0, height: 3,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 26),
                  ],
                ]),
              ]),
            ),
            // 白色列表卡(上圆角,圆角外露出父级渐变,无接缝)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: C.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                clipBehavior: Clip.antiAlias,
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: C.brand))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
                        itemCount: _list.length,
                        itemBuilder: (c, i) => _row(_list[i], i + 1, maxV),
                      ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // 榜单行:大名次 + 封面 + 标题/标签/热度条 + 看剧按钮
  Widget _row(Drama d, int rank, int maxV) {
    final top3 = rank <= 3;
    final rankColor = top3 ? _rankColors[rank - 1] : C.ink3;
    final frac = (d.viewCount / maxV).clamp(.18, 1.0);
    return InkWell(
      onTap: () => context.push('/drama/${d.id}'),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(children: [
          // 名次(斜体大字)
          SizedBox(
            width: 34,
            child: Text('$rank', textAlign: TextAlign.center,
                style: TextStyle(fontSize: top3 ? 26 : 22, fontStyle: FontStyle.italic, fontWeight: FontWeight.w800, color: rankColor, height: 1)),
          ),
          const SizedBox(width: 6),
          // 封面
          ClipRRect(borderRadius: BorderRadius.circular(13), child: SizedBox(width: 82, height: 110, child: Cover(d))),
          const SizedBox(width: 14),
          // 标题 / 标签 / 热度条
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (d.genre.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(6)),
                child: Text(d.genre, style: TextStyle(color: C.ink2, fontSize: 11)),
              ),
            const SizedBox(height: 12),
            // 热度条 + 热度值
            Row(children: [
              Expanded(
                child: LayoutBuilder(builder: (c, box) => Stack(children: [
                  Container(height: 6, decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(3))),
                  Container(
                    height: 6, width: box.maxWidth * frac,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFF8A2B), Color(0xFFE8362E)]),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ])),
              ),
              const SizedBox(width: 8),
              Text(d.plays, style: const TextStyle(color: _heat, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ]),
          ])),
          const SizedBox(width: 12),
          // 看剧按钮
          GestureDetector(
            onTap: () => context.push('/watch/${d.id}'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFF5222D),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [BoxShadow(color: const Color(0xFFF5222D).withValues(alpha: .3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Text(t('watchBtn'), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}
