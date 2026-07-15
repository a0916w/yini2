import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'api/media.dart';
import 'api/models.dart';
import 'i18n.dart';
import 'theme.dart';

// 页面大标题(规范:24px/800)+ 可选副标题(12px 暖灰)
class PageTitle extends StatelessWidget {
  final String text;
  final String? sub;
  final Color? color; // 文字色,默认随主题
  const PageTitle(this.text, {super.key, this.sub, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(text, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.15, color: color ?? C.ink)),
      if (sub != null) ...[
        const SizedBox(height: 4),
        Text(sub!, style: TextStyle(fontSize: 12, color: C.ink3)),
      ],
    ]);
  }
}

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
        _pc.animateToPage(_i,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic);
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bs = widget.banners;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 220),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(children: [
              PageView.builder(
                controller: _pc,
                itemCount: bs.length,
                onPageChanged: (i) => setState(() => _i = i),
                itemBuilder: (c, i) => _BannerImage(
                    '${bs[i]['mobile'] ?? bs[i]['desktop'] ?? ''}', i),
              ),
              if (bs.length > 1)
                Positioned(
                    bottom: 8,
                    right: 10,
                    child: Row(children: [
                      for (var k = 0; k < bs.length; k++)
                        Container(
                            width: k == _i ? 16 : 6,
                            height: 6,
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                                color: Colors.white
                                    .withValues(alpha: k == _i ? .95 : .5),
                                borderRadius: BorderRadius.circular(3))),
                    ])),
            ]),
          ),
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
      Media.resolveCover(widget.url).then((b) {
        if (mounted) setState(() => _bytes = b);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes != null) {
      return Image.memory(_bytes!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true);
    }
    final g = _grads[widget.idx % _grads.length];
    return DecoratedBox(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: g)));
  }
}

// 封面色板(规范:哑光深色,白字可读)
const coverPalette = [
  Color(0xFF33635C), Color(0xFF4A5A8A), Color(0xFF5E7050), Color(0xFF2E6B72),
  Color(0xFF3D4E81), Color(0xFF8A4A5E), Color(0xFFA05540), Color(0xFF6B4E36),
  Color(0xFF8A6B3A), Color(0xFF3F7053), Color(0xFF6B4E9E),
];
Color coverColor(int id) => coverPalette[id % coverPalette.length];

// banner 渐变兜底(沿用封面板)
const _grads = [
  [Color(0xFF33635C), Color(0xFF224440)], [Color(0xFF4A5A8A), Color(0xFF313D61)],
  [Color(0xFF8A4A5E), Color(0xFF5E3140)], [Color(0xFF3D4E81), Color(0xFF283356)],
];

// 封面:优先真实剧照(鉴权 CDN base64,内存+磁盘缓存);未就绪时为
// 规范占位(哑光色块 + 165deg 白14→黑叠加 + 左下白色剧名)
class Cover extends StatefulWidget {
  final Drama drama;
  final BoxFit fit;
  final bool showTitle;
  const Cover(this.drama, {super.key, this.fit = BoxFit.cover, this.showTitle = true});

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
    if (old.drama.cover != widget.drama.cover) { _bytes = null; _load(); }
  }

  void _load() {
    final url = widget.drama.cover;
    if (url == null || url.isEmpty) return;
    Media.resolveCover(url).then((b) {
      if (mounted && b != null) setState(() => _bytes = b);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes != null) {
      // 低端机优化:按实际布局宽度限尺寸解码,避免全分辨率解码+大纹理上传
      final dpr = MediaQuery.of(context).devicePixelRatio;
      return LayoutBuilder(builder: (ctx, box) {
        final w = box.maxWidth.isFinite ? (box.maxWidth * dpr).ceil().clamp(120, 1080) : 720;
        return Image.memory(_bytes!, fit: widget.fit, width: double.infinity, height: double.infinity,
            gaplessPlayback: true, cacheWidth: w);
      });
    }
    final drama = widget.drama;
    final showTitle = widget.showTitle;
    final base = coverColor(drama.id);
    return LayoutBuilder(builder: (ctx, box) {
      final h = box.maxHeight;
      final fs = h < 70 ? 8.0 : (h < 130 ? 11.0 : 12.0);
      final pad = h < 70 ? 5.0 : (h < 130 ? 9.0 : 12.0);
      return DecoratedBox(
        decoration: BoxDecoration(color: base),
        child: Stack(fit: StackFit.expand, children: [
          // 统一叠加 linear-gradient(165deg, 白0.14 → 黑0.2~0.36)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white.withValues(alpha: .14), Colors.black.withValues(alpha: h >= 130 ? .34 : .24)],
              ),
            ),
          ),
          if (showTitle)
            Padding(
              padding: EdgeInsets.all(pad),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  drama.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: fs, height: 1.45),
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
            ClipRRect(borderRadius: BorderRadius.circular(16), child: Cover(d)),
            // 左上:「新」主色角标(规范)
            Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: C.brand,
                      borderRadius: BorderRadius.circular(100)),
                  child: Text(t('newBadge'),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                )),
          ]),
        ),
        const SizedBox(height: 6),
        Text(d.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: C.ink)),
        if (d.genre.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('${d.genre} · ${d.plays}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: C.ink3)),
        ],
      ]),
    );
  }
}

// 列表行(果橙:暖底卡 r16 + 3:4 缩略 + 看剧胶囊)
class DramaRow extends StatelessWidget {
  final Drama d;
  final int? rank;
  const DramaRow(this.d, {super.key, this.rank});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/drama/${d.id}'),
      child: Container(
        decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          if (rank != null) ...[
            SizedBox(
                width: 22,
                child: Text('$rank',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w900,
                        color: rank! <= 3 ? C.brand : const Color(0xFFC9B8A6)))),
            const SizedBox(width: 12),
          ],
          ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: SizedBox(width: 44, height: 58, child: Cover(d, showTitle: false))),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(d.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14, color: C.ink)),
                const SizedBox(height: 4),
                Text('${d.genre.isEmpty ? '' : '${d.genre} · '}▶ ${d.plays}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: C.ink3, fontSize: 11)),
              ])),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => context.push('/watch/${d.id}'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: C.brand, borderRadius: BorderRadius.circular(100)),
              child: Text(t('watchBtn'), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}
