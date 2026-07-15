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
  List<Drama> _latest = [], _hot = [];
  int _page = 1, _lastPage = 1;
  bool _loadingMore = false;
  AppState? _app;
  String _lang = Http.lang;

  void _onApp() {
    if (_app!.lang != _lang) {
      _lang = _app!.lang;
      _fetchAll();
    }
  }

  void _fetchAll() {
    Api.latest().then((r) {
      if (mounted) setState(() => _latest = r);
    }).catchError((_) {});
    Api.videos(perPage: 50).then((r) {
      final rows = r.$1..sort((a, b) => b.viewCount - a.viewCount);
      if (mounted) {
        setState(() {
          _hot = rows;
          _page = r.$2;
          _lastPage = r.$3;
        });
      }
      for (final d in rows.take(9)) {
        Api.prefetchDetail(d.id);
      }
    }).catchError((_) {});
  }

  // 触底加载下一页,可一直往下拉
  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _lastPage) return;
    _loadingMore = true;
    try {
      final (rows, page, last) = await Api.videos(perPage: 50, page: _page + 1);
      if (mounted) {
        setState(() {
          _hot = [..._hot, ...rows];
          _page = page;
          _lastPage = last;
        });
      }
    } catch (_) {
    } finally {
      _loadingMore = false;
    }
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

  static String _rating(int id) => (8.8 + (id % 11) / 10).toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<ThemeController>().dark;
    context.watch<AppState>(); // 语言切换即重建文案
    final hero = _hot.isNotEmpty ? _hot.first : null;
    final freshList = _latest.take(8).toList();
    final watching = _hot.length > 1 ? _hot.sublist(1) : <Drama>[];

    return Scaffold(
      body: Container(
        decoration: pageTopGrad(dark),
        child: SafeArea(
          bottom: false,
          child: (_hot.isEmpty && _latest.isEmpty)
              ? const Center(child: CircularProgressIndicator(color: C.brand))
              : NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.pixels > n.metrics.maxScrollExtent - 600) {
                      _loadMore();
                    }
                    return false;
                  },
                  child: ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        // 顶栏:YiniTV logo + 签到有礼 + 搜索圆钮
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                          child: Row(children: [
                            Text.rich(TextSpan(children: [
                              TextSpan(
                                  text: 'Yini',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -.5,
                                      color: C.ink)),
                              const TextSpan(
                                  text: 'TV',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -.5,
                                      color: C.brand)),
                            ])),
                            const Spacer(),
                                                        GestureDetector(
                              onTap: () => context.push('/search'),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                    color: C.surface,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: C.brand.withValues(alpha: .12),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3))
                                    ]),
                                child:
                                    Icon(Icons.search, size: 16, color: C.ink),
                              ),
                            ),
                          ]),
                        ),
                        // 今日主打 Hero(200 高,r24)
                        if (hero != null) _heroCard(hero),
                        // 新剧首发:标题行 + 横滑
                        _sectionHeader(t('newSection'), chip: t('dailyNew')),
                        SizedBox(
                          height: 196,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: freshList.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (c, i) => _newCard(freshList[i]),
                          ),
                        ),
                        // 大家都在看:两列网格(3:4 竖版)
                        _sectionHeader(t('everyoneWatching')),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(children: [
                            for (var r = 0; r < watching.length; r += 2)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: _gridCard(watching[r])),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: r + 1 < watching.length
                                              ? _gridCard(watching[r + 1])
                                              : const SizedBox()),
                                    ]),
                              ),
                          ]),
                        ),
                        if (_page < _lastPage)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                                child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: C.brand))),
                          ),
                      ]),
                ),
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
          boxShadow: [
            BoxShadow(
                color: base.withValues(alpha: .28),
                blurRadius: 28,
                offset: const Offset(0, 12))
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(fit: StackFit.expand, children: [
          // 真实剧照打底(未就绪时为哑光色块)
          Cover(d, showTitle: false),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: .10),
                  Colors.black.withValues(alpha: .38)
                ],
              ),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100)),
                child: Text(t('todayPick'),
                    style: const TextStyle(
                        color: C.brand,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Text(d.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .5)),
              const SizedBox(height: 6),
              Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: '★ ${_rating(d.id)}',
                        style: const TextStyle(
                            color: C.gold, fontWeight: FontWeight.w700)),
                    TextSpan(
                        text:
                            ' · ${d.plays}${t('playsLabel')} · ${tp('epsAll', {
                          'n': d.eps
                        })}'),
                  ]),
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: .85))),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => context.push('/watch/${d.id}'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: C.brand,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                          color: C.brand.withValues(alpha: .4),
                          blurRadius: 14,
                          offset: const Offset(0, 6))
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.play_arrow, size: 15, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(t('watchNow2'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── 区块标题行(19/800 + chip + 全部›)──
  Widget _sectionHeader(String title, {String? chip}) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text(title,
              style: TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w800, color: C.ink)),
          if (chip != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: C.tag, borderRadius: BorderRadius.circular(100)),
              child: Text(chip,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: C.tagInk)),
            ),
          ],
          const Spacer(),
          GestureDetector(
            onTap: () => context.go('/trends'),
            child: Text(t('allLink'), style: TextStyle(fontSize: 12, color: C.quiet)),
          ),
        ]),
      );

  // ── 新剧首发卡:封面干净(仅「新」角标),剧名/播放数在封面下方 ──
  Widget _newCard(Drama d) => GestureDetector(
        onTap: () => context.push('/drama/${d.id}'),
        child: SizedBox(
          width: 112,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              height: 149,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(fit: StackFit.expand, children: [
                  Cover(d, showTitle: false),
                  Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: C.brand, borderRadius: BorderRadius.circular(100)),
                        child: Text(t('newBadge'), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      )),
                ]),
              ),
            ),
            const SizedBox(height: 6),
            Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: C.ink, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text('▶ ${d.plays}', style: TextStyle(color: C.ink3, fontSize: 10)),
          ]),
        ),
      );

  // ── 大家都在看网格卡:封面 3:4 干净无遮挡,剧名/评分/在看数在下方 ──
  Widget _gridCard(Drama d) => GestureDetector(
        onTap: () => context.push('/drama/${d.id}'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Cover(d, showTitle: false),
            ),
          ),
          const SizedBox(height: 7),
          Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: C.ink, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Row(children: [
            const Text('★ ', style: TextStyle(color: C.crown, fontSize: 11, fontWeight: FontWeight.w700)),
            Text(_rating(d.id), style: const TextStyle(color: C.crown, fontSize: 11, fontWeight: FontWeight.w700)),
            Expanded(
              child: Text('  ${d.genre.isEmpty ? '' : '${d.genre} · '}${tp('watchingN', {'n': d.plays})}',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: C.ink3, fontSize: 11)),
            ),
          ]),
        ]),
      );

}
