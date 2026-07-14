import 'package:flutter/material.dart';
import '../theme.dart';

class WishesPage extends StatefulWidget {
  const WishesPage({super.key});
  @override
  State<WishesPage> createState() => _WishesPageState();
}

class _WishesPageState extends State<WishesPage> {
  final _wishes = [
    {'title': '重返都市当女王', 'dir': '换个结局：女主称帝', 'votes': 3820, 'mine': false},
    {'title': '龙帝归来', 'dir': '群像扩写：兄弟七人番外', 'votes': 2910, 'mine': true},
    {'title': '神医赘婿', 'dir': '反派翻盘：岳父洗白线', 'votes': 2455, 'mine': false},
    {'title': '穿书恶毒女配', 'dir': '换个结局：女配和女主双赢', 'votes': 1980, 'mine': false},
    {'title': '末世重生囤货', 'dir': '群像扩写：末世基地日常', 'votes': 1560, 'mine': false},
  ];

  void _vote(int i) {
    setState(() {
      if (_wishes[i]['mine'] as bool) return;
      _wishes[i]['votes'] = (_wishes[i]['votes'] as int) + 1;
      _wishes[i]['mine'] = true;
    });
    _wishes.sort((a, b) => (b['votes'] as int) - (a['votes'] as int));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('魔改愿望榜'), centerTitle: false),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: C.brand.withValues(alpha: .10), borderRadius: BorderRadius.circular(14), border: Border.all(color: C.brand.withValues(alpha: .35))),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(Icons.auto_awesome, color: C.brand, size: 17), SizedBox(width: 6), Text('你想看的改编，由你决定', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15))]),
            SizedBox(height: 6),
            Text('为心仪的改编方向投票，人气最高的将进入制作评估。', style: TextStyle(color: C.ink3, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 16),
        const Row(children: [
          Text('心愿榜', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          Spacer(),
          Text('累计票数排序', style: TextStyle(color: C.ink3, fontSize: 12)),
        ]),
        ...List.generate(_wishes.length, (i) {
          final w = _wishes[i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(children: [
              SizedBox(width: 28, child: Text('${i + 1}', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic, fontWeight: FontWeight.w900, color: i < 3 ? C.brand : C.ink3))),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(w['title'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 3),
                Text(w['dir'] as String, style: const TextStyle(color: C.ink3, fontSize: 12)),
                const SizedBox(height: 3),
                Text('🔥 ${w['votes']} 票', style: const TextStyle(color: C.ink3, fontSize: 12)),
              ])),
              OutlinedButton(
                onPressed: (w['mine'] as bool) ? null : () => _vote(i),
                style: OutlinedButton.styleFrom(foregroundColor: C.brand, side: BorderSide(color: C.brand.withValues(alpha: .5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
                child: Text((w['mine'] as bool) ? '已投' : '投票'),
              ),
            ]),
          );
        }),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('提名功能开发中'), duration: Duration(seconds: 1))),
            icon: const Icon(Icons.add),
            label: const Text('我要提名'),
            style: ElevatedButton.styleFrom(backgroundColor: C.brand, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
          ),
        ),
      ]),
    );
  }
}
