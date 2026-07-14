import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../api/api.dart';
import '../api/models.dart';
import '../api/media.dart';
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
  final PageController _pc = PageController();
  int _index = 0;
  bool _danmaku = true;

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

  Future<void> _sync() async {
    for (final i in _ctrls.keys.toList()) {
      if ((i - _index).abs() > 1) _ctrls.remove(i)?.dispose();
    }
    for (var i = _index - 1; i <= _index + 1; i++) {
      if (i < 0 || i >= _feed.length) continue;
      await _ensure(i);
    }
    _ctrls.forEach((i, c) {
      if (!c.value.isInitialized) return;
      i == _index ? c.play() : c.pause();
    });
    if (mounted) setState(() {});
  }

  Future<void> _ensure(int i) async {
    if (_ctrls.containsKey(i)) return;
    var d = _detail[i];
    if (d == null || d.playUrl == null) {
      try {
        d = await Api.videoDetail(_feed[i].id);
        _detail[i] = d;
      } catch (_) {
        return;
      }
    }
    final locked = !d.free && !d.canPlayFull && d.trialSeconds <= 0;
    if (locked || d.playUrl == null || d.playUrl!.isEmpty) return;
    final url = await Media.signHls(d.playUrl!);
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    _ctrls[i] = c;
    try {
      await c.initialize();
      c.setLooping(true);
      if (i == _index) c.play();
      if (mounted) setState(() {});
    } catch (_) {
      _ctrls.remove(i)?.dispose();
    }
    if (i == _index) Api.recordWatch(d.id).catchError((_) {});
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
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
                itemBuilder: (c, i) => _Slide(
                  drama: _detail[i] ?? _feed[i],
                  controller: _ctrls[i],
                  active: i == _index,
                  danmaku: _danmaku,
                ),
              ),
        // 顶栏(返回 + 推荐 + 弹幕开关)
        Positioned(
          top: MediaQuery.of(context).padding.top + 6, left: 6, right: 12,
          child: Row(children: [
            IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20)),
            const Spacer(),
            const Text('推荐', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16, shadows: [Shadow(blurRadius: 4, color: Colors.black54)])),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _danmaku = !_danmaku),
              child: Text('弹幕${_danmaku ? '开' : '关'}', style: TextStyle(color: _danmaku ? Colors.white : Colors.white54, fontSize: 13, fontWeight: FontWeight.w400, shadows: const [Shadow(blurRadius: 4, color: Colors.black54)])),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Slide extends StatefulWidget {
  final Drama drama;
  final VideoPlayerController? controller;
  final bool active;
  final bool danmaku;
  const _Slide({required this.drama, required this.controller, required this.active, required this.danmaku});
  @override
  State<_Slide> createState() => _SlideState();
}

class _SlideState extends State<_Slide> with SingleTickerProviderStateMixin {
  bool _liked = false;
  bool _faved = false;
  int _burst = 0;
  late final AnimationController _disc;
  final List<Map<String, String>> _comments = [];

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
  void didUpdateWidget(_Slide old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_tick);
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

  void _openComments() {
    final ctrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: C.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (c) => StatefulBuilder(builder: (c, setSheet) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
        child: SizedBox(height: MediaQuery.of(c).size.height * .6, child: Column(children: [
          Padding(padding: const EdgeInsets.all(16), child: Row(children: [Text('讨论 ${_comments.length}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)), const Spacer(), IconButton(onPressed: () => Navigator.pop(c), icon: const Icon(Icons.close))])),
          Expanded(child: _comments.isEmpty
              ? Center(child: Text('还没有评论，快来抢沙发吧', style: TextStyle(color: C.ink3)))
              : ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: _comments.map((m) => ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(backgroundColor: C.surface2, child: const Text('我')), title: const Text('我'), subtitle: Text(m['t']!))).toList())),
          Padding(padding: const EdgeInsets.all(12), child: Row(children: [
            Expanded(child: TextField(controller: ctrl, decoration: InputDecoration(hintText: '说点什么…', filled: true, fillColor: C.surface2, isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none)))),
            const SizedBox(width: 8),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: C.brand), onPressed: () { if (ctrl.text.trim().isNotEmpty) { setSheet(() => _comments.insert(0, {'t': ctrl.text.trim()})); ctrl.clear(); } }, child: const Text('发送')),
          ])),
        ])),
      )),
    );
  }

  void _openEpisodes() {
    showModalBottomSheet(context: context, backgroundColor: C.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (c) => SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Text('选集', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)), const Spacer(), IconButton(onPressed: () => Navigator.pop(c), icon: const Icon(Icons.close))]),
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
          FittedBox(fit: BoxFit.cover, child: SizedBox(width: c.value.size.width, height: c.value.size.height, child: VideoPlayer(c)))
        else
          Cover(d, fit: BoxFit.cover),
        if (!ready && !_locked) const SizedBox.shrink(),

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
            Text(d.vipMessage ?? '本片为会员专享', style: const TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 14),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: C.brand), onPressed: () => context.push('/vip'), child: const Text('开通会员观看')),
          ]))
        else if (ready && !c.value.isPlaying)
          const Center(child: Icon(Icons.play_arrow, color: Colors.white70, size: 70)),

        // 弹幕
        if (widget.danmaku && !_locked && ready && c.value.isPlaying)
          const Positioned(top: 90, left: 16, child: Text('这段太上头了', style: TextStyle(color: Colors.white, fontSize: 13, shadows: [Shadow(blurRadius: 3, color: Colors.black87)]))),

        // 右栏
        Positioned(right: 10, bottom: 120, child: Column(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(gradient: C.brandGrad, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), alignment: Alignment.center, child: Text(d.title.isEmpty ? '橙' : d.title.characters.first, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18))),
          const SizedBox(height: 20),
          _rail(Icons.favorite, '${(d.id % 90) + 1 + (_liked ? 1 : 0)}', color: _liked ? C.like : Colors.white, onTap: () => setState(() => _liked = !_liked)),
          _rail(Icons.mode_comment, '${_comments.length}', onTap: _openComments),
          _rail(Icons.star, '收藏', color: _faved ? const Color(0xFFFFD233) : Colors.white, onTap: () async { final v = await context.read<AppState>().toggleFavorite(d.id); setState(() => _faved = v); }),
          _rail(Icons.share, '分享'),
          // 音乐碟
          RotationTransition(turns: _disc, child: Container(width: 44, height: 44, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0xFF333333), Colors.black], stops: [.35, 1])), alignment: Alignment.center, child: const Icon(Icons.music_note, color: Colors.white, size: 16))),
        ])),

        // 左下:作者 + 标题 + 选集 + 音乐
        Positioned(left: 14, right: 84, bottom: 44, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('@${d.genre.isEmpty ? "橙子" : d.genre}剧场', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16, shadows: [Shadow(blurRadius: 4, color: Colors.black54)])),
          const SizedBox(height: 8),
          Text(d.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, shadows: [Shadow(blurRadius: 4, color: Colors.black54)])),
          const SizedBox(height: 8),
          GestureDetector(onTap: _openEpisodes, child: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(7)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.list, size: 13, color: Colors.white), SizedBox(width: 4), Text('选集', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400))]))),
          const SizedBox(height: 10),
          Row(children: [const Icon(Icons.music_note, size: 14, color: Colors.white), const SizedBox(width: 6), Expanded(child: Text('原声 · ${d.title}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, shadows: [Shadow(blurRadius: 3, color: Colors.black54)])))]),
        ])),

        // 进度 + 时间
        if (ready)
          Positioned(left: 0, right: 0, bottom: 0, child: Row(children: [
            const SizedBox(width: 10),
            Text(_fmt(c.value.position), style: const TextStyle(color: Colors.white70, fontSize: 11)),
            Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: VideoProgressIndicator(c, allowScrubbing: true, colors: const VideoProgressColors(playedColor: Colors.white, bufferedColor: Colors.white24, backgroundColor: Colors.white10)))),
            Text(_fmt(c.value.duration), style: const TextStyle(color: Colors.white70, fontSize: 11)),
            const SizedBox(width: 10),
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
