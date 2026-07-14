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

  @override
  Widget build(BuildContext context) {
    final d = _d;
    return Scaffold(
      appBar: AppBar(title: const Text('剧集详情')),
      body: d == null
          ? const Center(child: CircularProgressIndicator(color: C.brand))
          : ListView(padding: const EdgeInsets.all(14), children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(width: 132, height: 176, child: Cover(d))),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800), maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  Text('▶ ${d.plays}', style: const TextStyle(color: C.ink2)),
                  const SizedBox(height: 6),
                  Text('时长 ${(d.duration / 60).round()} 分钟 · ${d.genre}', style: const TextStyle(color: C.ink2, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(d.free ? 'FREE 全集免费' : 'VIP 专享', style: TextStyle(color: d.free ? C.ok : C.brand, fontWeight: FontWeight.w700, fontSize: 12)),
                ])),
              ]),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(flex: 3, child: _btn(Icons.play_arrow, '立即观看', filled: true, onTap: () => context.push('/watch/${d.id}'))),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _btn(_faved ? Icons.check : Icons.favorite, _faved ? '已收藏' : '收藏', active: _faved, onTap: () async {
                  final v = await context.read<AppState>().toggleFavorite(d.id);
                  setState(() => _faved = v);
                })),
              ]),
              if (d.desc.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(d.desc, style: const TextStyle(color: C.ink2, height: 1.7, fontSize: 13)),
              ],
              if (_related.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('猜你喜欢', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10, mainAxisSpacing: 18, childAspectRatio: .58,
                  children: _related.map((e) => DramaCard(e)).toList(),
                ),
              ],
            ]),
    );
  }

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
          Icon(icon, size: 17, color: fg), const SizedBox(width: 6),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
      ),
    );
  }
}
