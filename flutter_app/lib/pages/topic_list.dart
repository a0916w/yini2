import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
    final dark = context.watch<ThemeController>().dark;
    return Scaffold(
      body: Container(
        decoration: pageTopGrad(dark),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
              child: Row(children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(color: C.surface, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: C.brand.withValues(alpha: .12), blurRadius: 10, offset: const Offset(0, 3))]),
                    child: Icon(Icons.arrow_back_ios_new, size: 15, color: C.ink),
                  ),
                ),
                const SizedBox(width: 12),
                Text(widget.name, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: C.ink)),
                const Spacer(),
                const SizedBox(),
              ]),
            ),
            Expanded(
              child: _list.isEmpty && _loading
                  ? const Center(child: CircularProgressIndicator(color: C.brand))
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 14, childAspectRatio: .60),
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
            ),
          ]),
        ),
      ),
    );
  }
}
