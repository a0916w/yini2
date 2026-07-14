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
        actions: [TextButton(onPressed: _run, child: const Text('搜索', style: TextStyle(color: C.brand, fontWeight: FontWeight.w500)))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: C.brand))
          : !_done
              ? _hotList()
              : _results.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.search_off, size: 44, color: C.ink3),
                      const SizedBox(height: 12),
                      Text('没有找到「${_ctrl.text.trim()}」相关的剧集', style: TextStyle(color: C.ink3)),
                    ]))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: C.line),
                      itemBuilder: (c, i) => DramaRow(_results[i]),
                    ),
    );
  }

  static const _hot = ['重返都市当女王', '闪婚老公竟是首富', '规则怪谈', '一胎三宝', '龙帝归来', '穿书恶毒女配', '神医赘婿', '末世囤货', '大小姐贴身高手', '万渣朝凰'];

  Widget _hotList() => ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('热搜榜', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
          for (var i = 0; i < _hot.length; i++)
            InkWell(
              onTap: () { _ctrl.text = _hot[i]; _run(); },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(children: [
                  SizedBox(width: 28, child: Text('${i + 1}', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, color: i < 3 ? C.brand : C.ink3))),
                  const SizedBox(width: 8),
                  Text(_hot[i], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
                ]),
              ),
            ),
        ],
      );
}
