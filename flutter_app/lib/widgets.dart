import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'api/media.dart';
import 'api/models.dart';
import 'theme.dart';

// 首页 Banner 轮播(图片走鉴权 CDN 的 .txt base64 解析)
class BannerCarousel extends StatefulWidget {
  final List<Map> banners;
  const BannerCarousel(this.banners, {super.key});
  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final _pc = PageController();
  int _i = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    if (widget.banners.length > 1) {
      _t = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!_pc.hasClients) return;
        _i = (_i + 1) % widget.banners.length;
        _pc.animateToPage(_i, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
      });
    }
  }

  @override
  void dispose() { _t?.cancel(); _pc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final bs = widget.banners;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(children: [
            PageView.builder(
              controller: _pc,
              itemCount: bs.length,
              onPageChanged: (i) => setState(() => _i = i),
              itemBuilder: (c, i) => _BannerImage('${bs[i]['mobile'] ?? bs[i]['desktop'] ?? ''}', i),
            ),
            if (bs.length > 1)
              Positioned(bottom: 8, right: 10, child: Row(children: [
                for (var k = 0; k < bs.length; k++)
                  Container(width: k == _i ? 16 : 6, height: 6, margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: k == _i ? .95 : .5), borderRadius: BorderRadius.circular(3))),
              ])),
          ]),
        ),
      ),
    );
  }
}

class _BannerImage extends StatefulWidget {
  final String url;
  final int idx;
  const _BannerImage(this.url, this.idx);
  @override
  State<_BannerImage> createState() => _BannerImageState();
}

class _BannerImageState extends State<_BannerImage> {
  Uint8List? _bytes;
  @override
  void initState() {
    super.initState();
    if (widget.url.isNotEmpty) {
      Media.resolveCover(widget.url).then((b) { if (mounted) setState(() => _bytes = b); });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes != null) {
      return Image.memory(_bytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity, gaplessPlayback: true);
    }
    final g = _grads[widget.idx % _grads.length];
    return DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: g)));
  }
}

const _grads = [
  [Color(0xFFFF8A2B), Color(0xFFE8480A)], [Color(0xFF5B8BFF), Color(0xFF2A3F8F)],
  [Color(0xFF38C172), Color(0xFF0F5C3A)], [Color(0xFFB06BFF), Color(0xFF5A2A9A)],
  [Color(0xFFFF6A3D), Color(0xFF8A2010)], [Color(0xFF4DD0E1), Color(0xFF0E5560)],
  [Color(0xFFFF4D6D), Color(0xFF8A1030)], [Color(0xFF9AE66E), Color(0xFF3A6A1A)],
  [Color(0xFF7C9CFF), Color(0xFF2A3A8F)], [Color(0xFFFFB86B), Color(0xFFA05A10)],
];
// 题材标签配色(循环)
const _tagColors = [
  (Color(0xFFEFE9FF), Color(0xFF6A4BD8)),
  (Color(0xFFE3F1FF), Color(0xFF2F6FD0)),
  (Color(0xFFE2F7E9), Color(0xFF1F8A4D)),
];

// 占位封面:渐变底 + 剧名(暂不拉真实封面)。3:4 竖版。
class Cover extends StatelessWidget {
  final Drama drama;
  final BoxFit fit;
  const Cover(this.drama, {super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final g = _grads[drama.id % _grads.length];
    return LayoutBuilder(builder: (ctx, box) {
      final big = box.maxHeight >= 130;
      return DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: g)),
        child: Stack(fit: StackFit.expand, children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight, end: Alignment.bottomLeft,
                colors: [Colors.white.withValues(alpha: .16), Colors.transparent, Colors.black.withValues(alpha: .30)],
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
                  fontWeight: FontWeight.w500, // 收敛字重
                  fontSize: big ? 16 : 12,
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
    final tc = _tagColors[d.id % _tagColors.length];
    return GestureDetector(
      onTap: () => context.push('/drama/${d.id}'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Stack(fit: StackFit.expand, children: [
            ClipRRect(borderRadius: BorderRadius.circular(10), child: Cover(d)),
            // 左上:已完结(深色半透明)
            Positioned(top: 6, left: 6, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: .5), borderRadius: BorderRadius.circular(7)),
              child: const Text('已完结', style: TextStyle(color: Colors.white, fontSize: 10)),
            )),
            // 左下:▶ 全N集
            Positioned(left: 6, bottom: 6, child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.play_arrow, size: 12, color: Colors.white),
              const SizedBox(width: 2),
              Text('全${d.eps}集', style: const TextStyle(color: Colors.white, fontSize: 11, shadows: [Shadow(blurRadius: 4, color: Colors.black54)])),
            ])),
          ]),
        ),
        const SizedBox(height: 6),
        Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: C.ink)),
        if (d.genre.isNotEmpty) ...[
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: tc.$1, borderRadius: BorderRadius.circular(6)),
              child: Text(d.genre, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: tc.$2, fontWeight: FontWeight.w400)),
            ),
          ),
        ],
      ]),
    );
  }
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
            SizedBox(width: 28, child: Text('$rank', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, color: rank! <= 3 ? C.brand : C.ink3))),
          ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 62, height: 82, child: Cover(d))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14)),
            const SizedBox(height: 4),
            Text('▶ ${d.plays} · ${d.genre}', style: const TextStyle(color: C.ink3, fontSize: 12)),
          ])),
        ]),
      ),
    );
  }
}
