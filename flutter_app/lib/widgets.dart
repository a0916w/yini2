import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'api/media.dart';
import 'api/models.dart';
import 'theme.dart';

const _grads = [
  [Color(0xFFFF8A2B), Color(0xFFE8480A)], [Color(0xFF5B8BFF), Color(0xFF2A3F8F)],
  [Color(0xFF38C172), Color(0xFF0F5C3A)], [Color(0xFFB06BFF), Color(0xFF5A2A9A)],
  [Color(0xFFFF6A3D), Color(0xFF8A2010)], [Color(0xFF4DD0E1), Color(0xFF0E5560)],
];

// 封面:先渐变占位,取到 base64 图后淡入(cover 填满)
class Cover extends StatefulWidget {
  final Drama drama;
  final BoxFit fit;
  const Cover(this.drama, {super.key, this.fit = BoxFit.cover});
  @override
  State<Cover> createState() => _CoverState();
}

class _CoverState extends State<Cover> {
  Uint8List? _bytes;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(Cover old) {
    super.didUpdateWidget(old);
    if (old.drama.cover != widget.drama.cover) _load();
  }

  void _load() {
    if (widget.drama.cover == null) return;
    Media.resolveCover(widget.drama.cover).then((b) {
      if (mounted) setState(() => _bytes = b);
    });
  }

  @override
  Widget build(BuildContext context) {
    final g = _grads[widget.drama.id % _grads.length];
    return Stack(fit: StackFit.expand, children: [
      DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: g)),
        child: _bytes == null
            ? Padding(
                padding: const EdgeInsets.all(8),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(widget.drama.title,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              )
            : null,
      ),
      if (_bytes != null)
        AnimatedOpacity(
          opacity: 1, duration: const Duration(milliseconds: 180),
          child: Image.memory(_bytes!, fit: widget.fit, gaplessPlayback: true, width: double.infinity, height: double.infinity),
        ),
    ]);
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
          aspectRatio: 16 / 9,
          child: Stack(fit: StackFit.expand, children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Cover(d)),
            Positioned(top: 8, left: 8, child: _pill(d.free ? '免费' : 'VIP', d.free ? C.ok : C.brand)),
            Positioned(
              left: 8, bottom: 8,
              child: _pill('▶ ${d.plays}', Colors.black.withValues(alpha: .55)),
            ),
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
          ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 104, height: 68, child: Cover(d))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 4),
            Text('▶ ${d.plays} · ${d.genre}', style: const TextStyle(color: C.ink3, fontSize: 12)),
          ])),
        ]),
      ),
    );
  }
}
