import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../api/api.dart';
import '../api/models.dart';
import '../state.dart';
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

  @override
  Widget build(BuildContext context) {
    final d = _d;
    return Scaffold(
      body: SafeArea(
        child: d == null
            ? const Center(child: CircularProgressIndicator(color: C.brand))
            : Column(children: [
                _header(context),
                Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(14, 8, 14, 28), children: [
                  // hero
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(width: 132, height: 176, child: Cover(d))),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600), maxLines: 3, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 12),
                      Row(children: [const Icon(Icons.play_arrow, size: 15, color: C.ink2), const SizedBox(width: 2), Text(d.plays, style: const TextStyle(color: C.ink2, fontSize: 14))]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Text('全 ${d.eps} 集 · 已完结', style: const TextStyle(color: C.ink2, fontSize: 13)),
                        if (d.genre.isNotEmpty) ...[const SizedBox(width: 8), Text(d.genre, style: const TextStyle(color: Color(0xFF3B76D6), fontSize: 13))],
                      ]),
                      const SizedBox(height: 8),
                      d.free
                          ? Row(children: [
                              Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: const Color(0xFF3B76D6), borderRadius: BorderRadius.circular(4)), child: const Text('FREE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600))),
                              const SizedBox(width: 6), const Text('全集免费', style: TextStyle(color: C.ink2, fontSize: 13)),
                            ])
                          : const Row(children: [Icon(Icons.lock_outline, size: 13, color: C.brand), SizedBox(width: 5), Text('VIP 专享', style: TextStyle(color: C.brand, fontSize: 13, fontWeight: FontWeight.w400))]),
                    ])),
                  ]),
                  // 简介(按钮之上)
                  if (d.desc.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(d.desc, style: const TextStyle(color: C.ink2, height: 1.7, fontSize: 13)),
                  ],
                  // 三按钮:立即观看 / 收藏 / 评论
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(flex: 3, child: _btn(Icons.play_arrow, '立即观看', filled: true, onTap: () => context.push('/watch/${d.id}'))),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: _btn(_faved ? Icons.check : Icons.favorite_border, _faved ? '已收藏' : '收藏', active: _faved, onTap: () async {
                      final v = await context.read<AppState>().toggleFavorite(d.id);
                      setState(() => _faved = v);
                    })),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: _btn(Icons.mode_comment_outlined, '评论', onTap: () => context.push('/watch/${d.id}'))),
                  ]),
                  // 正片
                  const SizedBox(height: 24),
                  _sectionTitle('正片'),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => context.push('/watch/${d.id}'),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.line)),
                      child: Row(children: [
                        const Icon(Icons.play_circle_fill, color: C.brand, size: 20),
                        const SizedBox(width: 8),
                        Text('正片 · $_mins 分钟', style: const TextStyle(fontWeight: FontWeight.w400)),
                        const Spacer(),
                        const Text('播放 ›', style: TextStyle(color: C.brand, fontWeight: FontWeight.w400)),
                      ]),
                    ),
                  ),
                  // 评论
                  const SizedBox(height: 24),
                  _sectionTitle('评论'),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Center(child: Text('还没有评论，去播放页抢沙发吧', style: TextStyle(color: C.ink3)))),
                  // 猜你喜欢
                  if (_related.isNotEmpty) ...[
                    _sectionTitle('猜你喜欢'),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10, mainAxisSpacing: 18, childAspectRatio: .58,
                      children: _related.map((e) => DramaCard(e)).toList(),
                    ),
                  ],
                ])),
              ]),
      ),
    );
  }

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 12, 8),
        child: Row(children: [
          IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new, size: 20)),
          Expanded(child: GestureDetector(
            onTap: () => context.push('/search'),
            child: Container(
              height: 36, padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(999)),
              child: const Row(children: [Icon(Icons.search, size: 15, color: C.ink3), SizedBox(width: 7), Text('搜索', style: TextStyle(color: C.ink3, fontSize: 13))]),
            ),
          )),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => context.go('/me'),
            child: Container(
              height: 30, padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: C.brand.withValues(alpha: .4))),
              alignment: Alignment.center,
              child: const Text('我的', style: TextStyle(color: C.brand, fontWeight: FontWeight.w500, fontSize: 13)),
            ),
          ),
        ]),
      );

  Widget _sectionTitle(String s) => Row(children: [
        Container(width: 4, height: 15, decoration: BoxDecoration(gradient: C.brandGrad, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 7),
        Text(s, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ]);

  Widget _btn(IconData icon, String label, {bool filled = false, bool active = false, VoidCallback? onTap}) {
    final fg = filled ? Colors.white : (active ? C.brand : C.ink2);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: filled ? C.brandGrad : null,
          color: filled ? null : C.surface,
          borderRadius: BorderRadius.circular(999),
          border: filled ? null : Border.all(color: active ? C.brand.withValues(alpha: .5) : C.line),
        ),
        alignment: Alignment.center,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: fg), const SizedBox(width: 5),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w500, fontSize: 14)),
        ]),
      ),
    );
  }
}
