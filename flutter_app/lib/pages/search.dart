import 'package:flutter/material.dart';
import '../api/api.dart';
import '../api/models.dart';
import '../theme.dart';
import '../widgets.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _ctrl = TextEditingController();
  List<Drama> _results = [];
  bool _loading = false;
  bool _done = false;

  Future<void> _run() async {
    final kw = _ctrl.text.trim();
    if (kw.isEmpty) return;
    setState(() { _loading = true; _done = true; });
    try {
      final (rows, _, _) = await Api.videos(keyword: kw, perPage: 30);
      setState(() => _results = rows);
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextField(
            controller: _ctrl,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _run(),
            decoration: InputDecoration(
              hintText: '输入关键词',
              filled: true,
              fillColor: C.surface2,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
              isDense: true,
            ),
          ),
        ),
        actions: [TextButton(onPressed: _run, child: const Text('搜索', style: TextStyle(color: C.brand, fontWeight: FontWeight.w700)))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: C.brand))
          : !_done
              ? const SizedBox()
              : _results.isEmpty
                  ? const Center(child: Text('没有找到相关的剧集', style: TextStyle(color: C.ink3)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: C.line),
                      itemBuilder: (c, i) => DramaRow(_results[i]),
                    ),
    );
  }
}
