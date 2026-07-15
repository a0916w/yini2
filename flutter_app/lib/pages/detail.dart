import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../api/api.dart';
import '../api/models.dart';
import '../state.dart';
import '../i18n.dart';
import '../theme.dart';
import '../widgets.dart';

class DetailPage extends StatefulWidget {
  final int id;
  const DetailPage(this.id, {super.key});
  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Drama? _d;
  List<Drama> _related = [];
  bool _faved = false;

  @override
  void initState() {
    super.initState();
    Api.videoDetail(widget.id).then((d) {
      if (!mounted) return;
      setState(() { _d = d; _faved = d.isFavorited; });
    }).catchError((_) {});
    Api.recommended().then((r) {
      if (mounted) setState(() => _related = r.where((v) => v.id != widget.id).take(4).toList());
    }).catchError((_) {});
  }

  int get _mins => ((_d?.duration ?? 0) / 60).round();
  static String _rating(int id) => (8.8 + (id % 11) / 10).toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<ThemeController>().dark;
    final d = _d;
    return Scaffold(
      body: Container(
        decoration: pageTopGrad(dark),
        child: SafeArea(
          child: d == null
              ? const Center(child: CircularProgressIndicator(color: C.brand))
              : Column(children: [
                  _header(context, dark),
                  Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(20, 10, 20, 28), children: [
                    // hero:封面 + 信息
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        width: 116, height: 155,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: coverColor(d.id).withValues(alpha: .28), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Cover(d),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(d.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.35, color: C.ink), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 10),
                        Row(children: [
                          const Text('★ ', style: TextStyle(color: C.crown, fontSize: 13, fontWeight: FontWeight.w700)),
                          Text(_rating(d.id), style: const TextStyle(color: C.crown, fontSize: 13, fontWeight: FontWeight.w700)),
                          Text('  ·  ▶ ${d.plays}', style: TextStyle(color: C.ink3, fontSize: 12)),
                        ]),
                        const SizedBox(height: 10),
                        // chips 行
                        Wrap(spacing: 6, runSpacing: 6, children: [
                          _chip(tp('epsDone', {'n': d.eps})),
                          if (d.genre.isNotEmpty) _chip(d.genre, accent: true),
                          d.free ? _chip(t('freeAll'), accent: true) : _chip(t('vipOnly'), accent: true),
                        ]),
                      ])),
                    ]),
                    // 简介
                    if (d.desc.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(d.desc, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: C.ink3, height: 1.7, fontSize: 12.5)),
                    ],
                    // 三按钮
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(flex: 3, child: _btn(Icons.play_arrow, t('watchNow'), filled: true, onTap: () => context.push('/watch/${d.id}'))),
                      const SizedBox(width: 10),
                      Expanded(flex: 2, child: _btn(_faved ? Icons.favorite : Icons.favorite_border, _faved ? t('faved') : t('favorite'), active: _faved, onTap: () async {
                        final v = await context.read<AppState>().toggleFavorite(d.id);
                        setState(() => _faved = v);
                      })),
                      const SizedBox(width: 10),
                      Expanded(flex: 2, child: _btn(Icons.mode_comment_outlined, t('comments'), onTap: () => context.push('/watch/${d.id}'))),
                    ]),
                    // 正片
                    _sectionTitle(t('feature')),
                    GestureDetector(
                      onTap: () => context.push('/watch/${d.id}'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(16)),
                        child: Row(children: [
                          Container(
                            width: 30, height: 30,
                            decoration: const BoxDecoration(color: C.brand, shape: BoxShape.circle),
                            child: const Icon(Icons.play_arrow, color: Colors.white, size: 17),
                          ),
                          const SizedBox(width: 12),
                          Text(tp('featureMins', {'n': _mins}), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: C.ink)),
                          const Spacer(),
                          Text(t('play'), style: const TextStyle(color: C.brand, fontWeight: FontWeight.w700, fontSize: 13)),
                        ]),
                      ),
                    ),
                    // 评论
                    _sectionTitle(t('comments')),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 26),
                      decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(16)),
                      child: Center(child: Text(t('noCommentGo'), style: TextStyle(color: C.ink3, fontSize: 12.5))),
                    ),
                    // 猜你喜欢
                    if (_related.isNotEmpty) ...[
                      _sectionTitle(t('guessLike')),
                      GridView.count(
                        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12, mainAxisSpacing: 16, childAspectRatio: .60,
                        children: _related.map((e) => DramaCard(e)).toList(),
                      ),
                    ],
                  ])),
                ]),
        ),
      ),
    );
  }

  // 顶栏:返回圆钮 + 搜索胶囊 + 我的 chip(白底+主色阴影)
  Widget _header(BuildContext context, bool dark) => Padding(
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
          Expanded(child: GestureDetector(
            onTap: () => context.push('/search'),
            child: Container(
              height: 34, padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: dark ? C.surface2 : Colors.white.withValues(alpha: .85),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(children: [Icon(Icons.search, size: 14, color: C.ink3), const SizedBox(width: 7), Text(t('search'), style: TextStyle(color: C.ink3, fontSize: 12.5))]),
            ),
          )),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => context.go('/me'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(100),
                  boxShadow: [BoxShadow(color: C.brand.withValues(alpha: .12), blurRadius: 10, offset: const Offset(0, 3))]),
              child: Text(t('me'), style: const TextStyle(color: C.brand, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ),
        ]),
      );

  // 信息 chip(暖底/主色浅底)
  Widget _chip(String s, {bool accent = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: accent ? C.tag : C.surface2, borderRadius: BorderRadius.circular(100)),
        child: Text(s, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent ? C.tagInk : C.ink2)),
      );

  // 区块标题(19/800)
  Widget _sectionTitle(String s) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
        child: Text(s, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: C.ink)),
      );

  Widget _btn(IconData icon, String label, {bool filled = false, bool active = false, VoidCallback? onTap}) {
    final fg = filled ? Colors.white : (active ? C.brand : C.ink2);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: filled ? C.brand : C.surface,
          borderRadius: BorderRadius.circular(100),
          border: filled ? null : Border.all(color: active ? C.brand.withValues(alpha: .5) : C.line),
          boxShadow: filled
              ? [BoxShadow(color: C.brand.withValues(alpha: .4), blurRadius: 14, offset: const Offset(0, 6))]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 15, color: fg), const SizedBox(width: 5),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ),
    );
  }
}
