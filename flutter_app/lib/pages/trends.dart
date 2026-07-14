import 'package:flutter/material.dart';
import '../api/api.dart';
import '../api/models.dart';
import '../theme.dart';
import '../widgets.dart';

class TrendsPage extends StatefulWidget {
  const TrendsPage({super.key});
  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> {
  final _tabs = ['最热', '最新', '推荐'];
  String _tab = '最热';
  List<Drama> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      List<Drama> rows;
      if (_tab == '最新') {
        rows = await Api.latest();
      } else if (_tab == '推荐') {
        rows = await Api.recommended();
      } else {
        final (r, _, _) = await Api.videos(perPage: 50);
        r.sort((a, b) => b.viewCount - a.viewCount);
        rows = r;
      }
      setState(() => _list = rows);
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('榜单'), centerTitle: false),
      body: Column(children: [
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            itemCount: _tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (c, i) {
              final active = _tab == _tabs[i];
              return GestureDetector(
                onTap: () { setState(() => _tab = _tabs[i]); _load(); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: active ? C.brand.withValues(alpha: .12) : C.surface2,
                    borderRadius: BorderRadius.circular(999),
                    border: active ? Border.all(color: C.brand.withValues(alpha: .4)) : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(_tabs[i], style: TextStyle(color: active ? C.brand : C.ink2, fontWeight: active ? FontWeight.w500 : FontWeight.w400, fontSize: 13)),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: C.brand))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: _list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: C.line),
                  itemBuilder: (c, i) => DramaRow(_list[i], rank: i + 1),
                ),
        ),
      ]),
    );
  }
}
