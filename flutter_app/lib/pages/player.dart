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
  final Map<int, Drama> _detail = {}; // index -> detail (with playUrl)
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

  // ensure controllers for [index-1, index, index+1]; dispose others
  Future<void> _sync() async {
    for (final i in _ctrls.keys.toList()) {
      if ((i - _index).abs() > 1) {
        _ctrls.remove(i)?.dispose();
      }
    }
    for (var i = _index - 1; i <= _index + 1; i++) {
      if (i < 0 || i >= _feed.length) continue;
      await _ensure(i);
    }
    // play active, pause others
    _ctrls.forEach((i, c) {
      if (!c.value.isInitialized) return;
      if (i == _index) {
        c.play();
      } else {
        c.pause();
      }
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
    if (i == _index) {
      Api.recordWatch(d.id).catchError((_) {});
    }
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
      body: _feed.isEmpty
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
                onBack: () => context.pop(),
              ),
            ),
    );
  }
}

class _Slide extends StatefulWidget {
  final Drama drama;
  final VideoPlayerController? controller;
  final bool active;
  final VoidCallback onBack;
  const _Slide({required this.drama, required this.controller, required this.active, required this.onBack});
  @override
  State<_Slide> createState() => _SlideState();
}

class _SlideState extends State<_Slide> {
  bool _liked = false;
  bool _faved = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.drama;
    final c = widget.controller;
    final ready = c != null && c.value.isInitialized;
    return GestureDetector(
      onTap: () {
        if (!ready) return;
        c.value.isPlaying ? c.pause() : c.play();
        setState(() {});
      },
      onDoubleTap: () => setState(() => _liked = true),
      child: Stack(fit: StackFit.expand, children: [
        // video / cover
        if (ready)
          FittedBox(fit: BoxFit.cover, child: SizedBox(width: c.value.size.width, height: c.value.size.height, child: VideoPlayer(c)))
        else
          Cover(d, fit: BoxFit.cover),
        if (ready && !c.value.isPlaying)
          const Center(child: Icon(Icons.play_arrow, color: Colors.white70, size: 70)),
        // top back
        Positioned(
          top: MediaQuery.of(context).padding.top + 8, left: 12,
          child: IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white)),
        ),
        // right rail
        Positioned(
          right: 10, bottom: 120,
          child: Column(children: [
            _RailAvatar(d.title),
            const SizedBox(height: 20),
            _rail(_liked ? Icons.favorite : Icons.favorite, '${(d.id % 90) + 1 + (_liked ? 1 : 0)}', color: _liked ? C.like : Colors.white, onTap: () => setState(() => _liked = !_liked)),
            _rail(Icons.chat_bubble_outline, '评论'),
            _rail(_faved ? Icons.star : Icons.star, '收藏', color: _faved ? const Color(0xFFFFD233) : Colors.white, onTap: () async {
              final v = await context.read<AppState>().toggleFavorite(d.id);
              setState(() => _faved = v);
            }),
            _rail(Icons.share, '分享'),
          ]),
        ),
        // caption
        Positioned(
          left: 14, right: 84, bottom: 44,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('@${d.genre.isEmpty ? "橙子" : d.genre}剧场', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, shadows: [Shadow(blurRadius: 4, color: Colors.black54)])),
            const SizedBox(height: 8),
            Text(d.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, shadows: [Shadow(blurRadius: 4, color: Colors.black54)])),
          ]),
        ),
        // progress
        if (ready)
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: VideoProgressIndicator(c, allowScrubbing: true, colors: const VideoProgressColors(playedColor: Colors.white, bufferedColor: Colors.white24, backgroundColor: Colors.white10)),
          ),
      ]),
    );
  }

  Widget _rail(IconData icon, String label, {Color color = Colors.white, VoidCallback? onTap}) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: GestureDetector(
          onTap: onTap,
          child: Column(children: [
            Icon(icon, color: color, size: 32, shadows: const [Shadow(blurRadius: 4, color: Colors.black54)]),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, shadows: [Shadow(blurRadius: 4, color: Colors.black54)])),
          ]),
        ),
      );
}

class _RailAvatar extends StatelessWidget {
  final String title;
  const _RailAvatar(this.title);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(gradient: C.brandGrad, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
      alignment: Alignment.center,
      child: Text(title.isEmpty ? '橙' : title.characters.first, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
    );
  }
}
