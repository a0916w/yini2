import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../api/api.dart';
import '../api/models.dart';
import '../api/media.dart';
import '../history.dart';
import '../i18n.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class PlayerPage extends StatefulWidget {
  final int id;
  const PlayerPage(this.id, {super.key});
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final List<Drama> _feed = [];
  final Map<int, VideoPlayerController> _ctrls = {};
  final Map<int, Drama> _detail = {};
  final Map<int, String> _errs = {}; // 加载/初始化失败原因(可重试)
  final PageController _pc = PageController();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _build();
  }

  Future<void> _build() async {
    _feed.add(Drama(id: widget.id, title: ''));
    try {
      final rec = await Api.recommended();
      final latest = await Api.latest();
      final seen = {widget.id};
      for (final v in [...rec, ...latest]) {
        if (seen.add(v.id)) _feed.add(v);
      }
    } catch (_) {}
    if (mounted) setState(() {});
    _sync();
  }

  bool _dead = false; // 页面已退出:任何 await 之后都不得再注册/播放控制器

  Future<void> _sync() async {
    if (_dead) return;
    for (final i in _ctrls.keys.toList()) {
      if ((i - _index).abs() > 1) _ctrls.remove(i)?.dispose();
    }
    for (var i = _index - 1; i <= _index + 1; i++) {
      if (i < 0 || i >= _feed.length) continue;
      await _ensure(i);
      if (_dead) return;
    }
    _ctrls.forEach((i, c) {
      if (!c.value.isInitialized) return;
      i == _index ? c.play() : c.pause();
    });
    if (mounted) setState(() {});
  }

  Future<void> _ensure(int i) async {
    if (_dead || _ctrls.containsKey(i)) return;
    _errs.remove(i);
    var d = _detail[i];
    if (d == null || d.playUrl == null) {
      try {
        d = await Api.videoDetail(_feed[i].id);
        _detail[i] = d;
      } catch (e) {
        debugPrint('player detail #${_feed[i].id} failed: $e');
        _errs[i] = t('loadFailNet');
        if (mounted) setState(() {});
        return;
      }
    }
    if (_dead) return;
    final locked = !d.free && !d.canPlayFull && d.trialSeconds <= 0;
    if (locked || d.playUrl == null || d.playUrl!.isEmpty) return;
    final url = await Media.signHls(d.playUrl!);
    if (_dead) return;
    debugPrint('player #${d.id} url: $url');
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    _ctrls[i] = c;
    try {
      await c.initialize().timeout(const Duration(seconds: 20));
      if (_dead) { c.dispose(); return; } // 初始化期间退出:立即销毁,禁止出声
      c.setLooping(true);
      if (i == _index) c.play();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('player #${d.id} init failed: $e | ${c.value.errorDescription ?? ''}');
      _errs[i] = t('videoFail');
      _ctrls.remove(i)?.dispose();
      if (mounted && !_dead) setState(() {});
    }
    if (i == _index && !_dead) {
      Api.recordWatch(d.id).catchError((_) {});
      WatchHistory.record(d); // 本地观看历史
    }
  }

  void _retry(int i) {
    _errs.remove(i);
    setState(() {});
    _ensure(i).then((_) => _sync());
  }

  @override
  void dispose() {
    _dead = true;
    for (final c in _ctrls.values) {
      c.dispose();
    }
    _ctrls.clear();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        _feed.isEmpty
            ? const Center(child: CircularProgressIndicator(color: C.brand))
            : PageView.builder(
                scrollDirection: Axis.vertical,
                controller: _pc,
                itemCount: _feed.length,
                onPageChanged: (i) { setState(() => _index = i); _sync(); },
                itemBuilder: (c, i) => VideoSlide(
                  drama: _detail[i] ?? _feed[i],
                  controller: _ctrls[i],
                  active: i == _index,
                  error: _errs[i],
                  onRetry: () => _retry(i),
                ),
              ),
        // 顶栏(规范:返回圆钮 34 黑30% + 居中「推荐」+ 弹幕 chip)
        Positioned(
          top: MediaQuery.of(context).padding.top + 6, left: 16, right: 16,
          child: Stack(alignment: Alignment.center, children: [
            Center(child: Text(t('recommend'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: .3), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 15),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class VideoSlide extends StatefulWidget {
  final Drama drama;
  final VideoPlayerController? controller;
  final bool active;
  final String? error;
  final VoidCallback? onRetry;
  const VideoSlide({super.key, required this.drama, required this.controller, required this.active, this.error, this.onRetry});
  @override
  State<VideoSlide> createState() => VideoSlideState();
}

class VideoSlideState extends State<VideoSlide> with SingleTickerProviderStateMixin {
  bool _liked = false;
  bool _faved = false;
  int _burst = 0;
  late final AnimationController _disc;

  bool get _locked {
    final d = widget.drama;
    return !d.free && !d.canPlayFull && d.trialSeconds <= 0 && d.playUrl != null;
  }

  @override
  void initState() {
    super.initState();
    _disc = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    widget.controller?.addListener(_tick);
  }

  @override
  void didUpdateWidget(VideoSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_tick);
      widget.controller?.addListener(_tick);
    }
  }

  void _tick() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    widget.controller?.removeListener(_tick);
    _disc.dispose();
    super.dispose();
  }

  String _fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  void _togglePlay() {
    final c = widget.controller;
    if (c == null || !c.value.isInitialized) return;
    c.value.isPlaying ? c.pause() : c.play();
    setState(() {});
  }

  void _openEpisodes() {
    showModalBottomSheet(context: context, backgroundColor: C.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (c) => SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Text(t('episodes'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)), const Spacer(), IconButton(onPressed: () => Navigator.pop(c), icon: const Icon(Icons.close))]),
        const SizedBox(height: 8),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (var e = 1; e <= widget.drama.eps; e++)
            Container(width: 46, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: e == 1 ? C.brand.withValues(alpha: .12) : C.surface2, borderRadius: BorderRadius.circular(10), border: e == 1 ? Border.all(color: C.brand.withValues(alpha: .4)) : null), child: Text('$e', style: TextStyle(fontWeight: FontWeight.w500, color: e == 1 ? C.brand : C.ink))),
        ]),
        const SizedBox(height: 12),
      ]))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.drama;
    final c = widget.controller;
    final ready = c != null && c.value.isInitialized;
    return GestureDetector(
      onTap: _locked ? null : _togglePlay,
      onDoubleTap: _locked ? null : () => setState(() { _liked = true; _burst++; }),
      child: Stack(fit: StackFit.expand, children: [
        if (ready)
          // HLS 初始化完成瞬间 size 可能为 0(首帧前),此时先铺满避免"有声无画"
          (c.value.size.width > 0 && c.value.size.height > 0)
              ? FittedBox(fit: BoxFit.cover, clipBehavior: Clip.hardEdge, child: SizedBox(width: c.value.size.width, height: c.value.size.height, child: VideoPlayer(c)))
              : SizedBox.expand(child: VideoPlayer(c))
        else
          Cover(d, fit: BoxFit.cover),
        // 加载中 / 失败重试
        if (!ready && !_locked)
          widget.error != null
              ? Container(color: Colors.black45, alignment: Alignment.center, child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.wifi_off, color: Colors.white70, size: 32),
                  const SizedBox(height: 10),
                  Text(widget.error!, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: widget.onRetry,
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                    child: Text(t('retry')),
                  ),
                ]))
              : const Center(child: CircularProgressIndicator(color: Colors.white54)),

        // 双击爆心
        if (_burst > 0)
          Center(child: TweenAnimationBuilder<double>(
            key: ValueKey(_burst), tween: Tween(begin: .3, end: 1), duration: const Duration(milliseconds: 500),
            builder: (c, v, _) => Opacity(opacity: (1 - (v - .8).abs() * 5).clamp(0, 1), child: Transform.scale(scale: v, child: const Icon(Icons.favorite, color: C.like, size: 100))),
          )),

        // VIP 锁
        if (_locked)
          Container(color: Colors.black54, alignment: Alignment.center, child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.lock_outline, color: Colors.white, size: 34),
            const SizedBox(height: 10),
            Text(d.vipMessage ?? t('vipOnlyMsg'), style: const TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 14),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: C.brand), onPressed: () => context.push('/vip'), child: Text(t('vipWatch'))),
          ]))
        else if (ready && !c.value.isPlaying)
          const Center(child: Icon(Icons.play_arrow, color: Colors.white70, size: 70)),

        // 右栏
        Positioned(right: 10, bottom: 120, child: Column(children: [
          // 创作者头像 46 + 底部主色关注角标(规范)
          Stack(clipBehavior: Clip.none, children: [
            Container(width: 46, height: 46,
                decoration: BoxDecoration(color: coverColor(d.id), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                alignment: Alignment.center,
                child: Text(d.title.isEmpty ? 'Y' : d.title.characters.first, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17))),
            Positioned(bottom: -7, left: 14, child: Container(
              width: 18, height: 18,
              decoration: const BoxDecoration(color: C.brand, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Text('+', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, height: 1)),
            )),
          ]),
          const SizedBox(height: 20),
          _rail(Icons.favorite, '${(d.id % 90) + 1 + (_liked ? 1 : 0)}', color: _liked ? C.like : Colors.white, onTap: () => setState(() => _liked = !_liked)),
          _rail(Icons.star, t('favorite'), color: _faved ? const Color(0xFFFFD233) : Colors.white, onTap: () async { final v = await context.read<AppState>().toggleFavorite(d.id); setState(() => _faved = v); }),
          _rail(Icons.share, t('share'), onTap: () => SharePlus.instance.share(ShareParams(text: '《${d.title}》 https://yini.tv/video/${d.id}'))),
          // 音乐碟
          RotationTransition(turns: _disc, child: Container(width: 44, height: 44, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0xFF333333), Colors.black], stops: [.35, 1])), alignment: Alignment.center, child: const Icon(Icons.music_note, color: Colors.white, size: 16))),
        ])),

        // 左下:作者 + 标题 + 选集 + 音乐
        Positioned(left: 14, right: 84, bottom: 44, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('@${d.genre.isEmpty ? t('appName') : d.genre}${t('theater')}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16, shadows: [Shadow(blurRadius: 4, color: Colors.black54)])),
          const SizedBox(height: 8),
          Text(d.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, shadows: [Shadow(blurRadius: 4, color: Colors.black54)])),
          const SizedBox(height: 8),
          GestureDetector(onTap: _openEpisodes, child: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(7)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.list, size: 13, color: Colors.white), const SizedBox(width: 4), Text(t('episodes'), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400))]))),
          const SizedBox(height: 10),
          Row(children: [const Icon(Icons.music_note, size: 14, color: Colors.white), const SizedBox(width: 6), Expanded(child: Text('${t('origSound')} · ${d.title}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, shadows: [Shadow(blurRadius: 3, color: Colors.black54)])))]),
        ])),

        // 上滑提示(规范:10px 白45%,进度条上方)
        if (ready)
          Positioned(left: 0, right: 0, bottom: 40, child: Center(
            child: Text(t('swipeHint'), style: TextStyle(color: Colors.white.withValues(alpha: .45), fontSize: 10)),
          )),
        // 进度 + 时间(规范:3px 白25%轨道 + 白已播,时间 10px 白60%)
        if (ready)
          Positioned(left: 16, right: 16, bottom: 6, child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(height: 14, child: VideoProgressIndicator(c, allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 5.5),
                colors: VideoProgressColors(playedColor: Colors.white, bufferedColor: Colors.white.withValues(alpha: .35), backgroundColor: Colors.white.withValues(alpha: .25)))),
            const SizedBox(height: 2),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(_fmt(c.value.position), style: TextStyle(color: Colors.white.withValues(alpha: .6), fontSize: 10)),
              Text(_fmt(c.value.duration), style: TextStyle(color: Colors.white.withValues(alpha: .6), fontSize: 10)),
            ]),
          ])),
      ]),
    );
  }

  Widget _rail(IconData icon, String label, {Color color = Colors.white, VoidCallback? onTap}) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: GestureDetector(onTap: onTap, child: Column(children: [
          Icon(icon, color: color, size: 32, shadows: const [Shadow(blurRadius: 4, color: Colors.black54)]),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400, shadows: [Shadow(blurRadius: 4, color: Colors.black54)])),
        ])),
      );
}
