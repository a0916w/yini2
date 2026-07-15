import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../api/api.dart';
import '../api/http.dart';
import '../api/media.dart';
import '../api/models.dart';
import '../history.dart';
import '../i18n.dart';
import '../state.dart';
import '../theme.dart';
import 'player.dart';

// 当前底栏激活 tab(剧场用它在切走时自动暂停)
final ValueNotifier<int> activeTab = ValueNotifier(0);
const theaterTabIndex = 0; // 视频流在首页 tab

// 剧场:随机排列剧集,抖音式上下滑视频流(常驻 tab)
class TheaterPage extends StatefulWidget {
  const TheaterPage({super.key});
  @override
  State<TheaterPage> createState() => _TheaterPageState();
}

class _TheaterPageState extends State<TheaterPage> {
  final List<Drama> _feed = [];
  final Map<int, VideoPlayerController> _ctrls = {};
  final Map<int, Drama> _detail = {};
  final Map<int, String> _errs = {};
  final PageController _pc = PageController();
  int _index = 0;
  bool _dead = false;
  AppState? _app;
  String _lang = Http.lang;

  bool get _visible => activeTab.value == theaterTabIndex;

  void _onTab() {
    if (_dead) return;
    if (_visible) {
      _sync(); // 回到剧场:恢复播放
    } else {
      for (final c in _ctrls.values) {
        if (c.value.isInitialized) c.pause(); // 切走:全部暂停
      }
    }
  }

  void _onApp() {
    if (_app!.lang != _lang) { _lang = _app!.lang; _reload(); }
  }

  @override
  void initState() {
    super.initState();
    _app = context.read<AppState>();
    _app!.addListener(_onApp);
    activeTab.addListener(_onTab);
    _reload();
  }

  Future<void> _reload() async {
    for (final c in _ctrls.values) { c.dispose(); }
    _ctrls.clear(); _detail.clear(); _errs.clear();
    _feed.clear();
    _index = 0;
    if (_pc.hasClients) _pc.jumpToPage(0);
    try {
      final (rows, _, _) = await Api.videos(perPage: 50);
      rows.shuffle(Random()); // 随机排列
      _feed.addAll(rows);
    } catch (_) {}
    if (mounted) setState(() {});
    if (_visible) _sync();
  }

  Future<void> _sync() async {
    if (_dead || !_visible) return;
    for (final i in _ctrls.keys.toList()) {
      if ((i - _index).abs() > 1) _ctrls.remove(i)?.dispose();
    }
    for (var i = _index - 1; i <= _index + 1; i++) {
      if (i < 0 || i >= _feed.length) continue;
      await _ensure(i);
      if (_dead) return;
    }
    if (!_visible) return;
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
      } catch (_) {
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
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    _ctrls[i] = c;
    try {
      await c.initialize().timeout(const Duration(seconds: 20));
      if (_dead) { c.dispose(); return; }
      c.setLooping(true);
      if (i == _index && _visible) c.play();
      if (mounted) setState(() {});
    } catch (_) {
      _errs[i] = t('videoFail');
      _ctrls.remove(i)?.dispose();
      if (mounted && !_dead) setState(() {});
    }
    if (i == _index && !_dead && _visible) {
      Api.recordWatch(d.id).catchError((_) {});
      WatchHistory.record(d);
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
    activeTab.removeListener(_onTab);
    _app?.removeListener(_onApp);
    for (final c in _ctrls.values) { c.dispose(); }
    _ctrls.clear();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>(); // 语言切换重建文案
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
        // 顶栏(规范:居中「推荐」+ 右侧弹幕 chip)
        Positioned(
          top: MediaQuery.of(context).padding.top + 10, left: 16, right: 16,
          child: Stack(alignment: Alignment.center, children: [
            Center(child: Text(t('recommend'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
          ]),
        ),
      ]),
    );
  }
}
