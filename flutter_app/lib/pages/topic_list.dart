import 'package:flutter/material.dart';
import '../api/api.dart';
import '../api/models.dart';
import '../i18n.dart';
import '../theme.dart';
import '../widgets.dart';

// 专题详情:该分类下全部剧集(3 列网格 + 加载更多)
class TopicListPage extends StatefulWidget {
  final int id;
  final String name;
  const TopicListPage(this.id, this.name, {super.key});
  @override
  State<TopicListPage> createState() => _TopicListPageState();
}

class _TopicListPageState extends State<TopicListPage> {
  final List<Drama> _list = [];
  int _page = 1, _lastPage = 1;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    setState(() => _loading = true);
    try {
      final (rows, page, last) = await Api.videos(categoryId: widget.id, page: reset ? 1 : _page + 1);
      if (mounted) {
        setState(() {
          if (reset) _list.clear();
          _list.addAll(rows);
          _page = page;
          _lastPage = last;
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: _list.isEmpty && _loading
          ? const Center(child: CircularProgressIndicator(color: C.brand))
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: .57),
              itemCount: _list.length + 1,
              itemBuilder: (c, i) {
                if (i == _list.length) {
                  if (_page < _lastPage) {
                    return Center(child: TextButton(onPressed: _loading ? null : () => _load(), child: Text(_loading ? t('loading') : t('loadMore'))));
                  }
                  return const SizedBox();
                }
                return DramaCard(_list[i]);
              },
            ),
    );
  }
}
