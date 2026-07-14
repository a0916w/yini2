import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'api/models.dart';
import 'theme.dart';

const _grads = [
  [Color(0xFFFF8A2B), Color(0xFFE8480A)], [Color(0xFF5B8BFF), Color(0xFF2A3F8F)],
  [Color(0xFF38C172), Color(0xFF0F5C3A)], [Color(0xFFB06BFF), Color(0xFF5A2A9A)],
  [Color(0xFFFF6A3D), Color(0xFF8A2010)], [Color(0xFF4DD0E1), Color(0xFF0E5560)],
  [Color(0xFFFF4D6D), Color(0xFF8A1030)], [Color(0xFF9AE66E), Color(0xFF3A6A1A)],
  [Color(0xFF7C9CFF), Color(0xFF2A3A8F)], [Color(0xFFFFB86B), Color(0xFFA05A10)],
];

// 占位封面:渐变底 + 剧名(暂不拉真实封面)。用于 3:4 竖版卡片。
class Cover extends StatelessWidget {
  final Drama drama;
  final BoxFit fit; // 保留签名兼容,占位图不使用
  const Cover(this.drama, {super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final g = _grads[drama.id % _grads.length];
    return LayoutBuilder(builder: (ctx, box) {
      final big = box.maxHeight >= 120; // 大卡放大字号
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: g),
        ),
        child: Stack(fit: StackFit.expand, children: [
          // 顶部高光 + 底部压暗,增强层次
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight, end: Alignment.bottomLeft,
                colors: [Colors.white.withValues(alpha: .18), Colors.transparent, Colors.black.withValues(alpha: .28)],
                stops: const [0, .5, 1],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(big ? 12 : 8),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                drama.title,
                textAlign: TextAlign.center,
                maxLines: big ? 4 : 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: big ? 17 : 12,
                  height: 1.3,
                  shadows: const [Shadow(blurRadius: 8, color: Colors.black45, offset: Offset(0, 1))],
                ),
              ),
            ),
          ),
        ]),
      );
    });
  }
}

class DramaCard extends StatelessWidget {
  final Drama d;
  const DramaCard(this.d, {super.key});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/drama/${d.id}'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Stack(fit: StackFit.expand, children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Cover(d)),
            Positioned(top: 8, left: 8, child: _pill(d.free ? '免费' : 'VIP', d.free ? C.ok : C.brand)),
            Positioned(left: 8, bottom: 8, child: _pill('▶ ${d.plays}', Colors.black.withValues(alpha: .55))),
          ]),
        ),
        const SizedBox(height: 8),
        Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.ink)),
        if (d.genre.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: C.tag, borderRadius: BorderRadius.circular(7)),
            child: Text(d.genre, style: const TextStyle(fontSize: 11, color: C.tagInk, fontWeight: FontWeight.w600)),
          ),
        ],
      ]),
    );
  }

  static Widget _pill(String s, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      );
}

class DramaRow extends StatelessWidget {
  final Drama d;
  final int? rank;
  const DramaRow(this.d, {super.key, this.rank});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/drama/${d.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          if (rank != null)
            SizedBox(width: 28, child: Text('$rank', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic, fontWeight: FontWeight.w900, color: rank! <= 3 ? C.brand : C.ink3))),
          ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 62, height: 82, child: Cover(d))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 4),
            Text('▶ ${d.plays} · ${d.genre}', style: const TextStyle(color: C.ink3, fontSize: 12)),
          ])),
        ]),
      ),
    );
  }
}
