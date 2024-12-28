import 'dart:math';

import 'package:btree/btree/btree.dart';
import 'package:flutter/material.dart';

class BTreeView extends StatefulWidget {
  const BTreeView({super.key});

  @override
  State<BTreeView> createState() => _BTreeViewState();
}

class _BTreeViewState extends State<BTreeView> {
  final random = Random();
  late BTree<int> tree;
  int? latest;

  @override
  void initState() {
    super.initState();
    tree = BTree(m: 4);
  }

  void _putKey(int key) {
    latest = key;
    tree.put(key);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("B-Tree"),
        actions: [
          IconButton(
            onPressed: () async {
              final m = await showIntegerDialog(
                context,
                value: tree.m,
                title: Text("초기화"),
                label: Text("최대 자식 수"),
              );
              if (m == null) return;
              tree = BTree(m: m);
              setState(() {});
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Text("최대 자식 수: ${tree.m}"),
          Text("최대 키 수: ${tree.m - 1}"),
          Wrap(
            spacing: 10,
            children: [
              FilledButton(
                onPressed: () async {
                  final key = await showIntegerDialog(
                    context,
                    title: Text("키 입력"),
                    label: Text("키를 입력하세요."),
                  );
                  if (key == null) return;
                  _putKey(key);
                },
                child: Text("지정 키 추가"),
              ),
              FilledButton(
                onPressed: () {
                  final key = random.nextInt(1000);
                  _putKey(key);
                },
                child: Text("랜덤 키 추가"),
              ),
            ],
          ),
          Divider(),
          Expanded(
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: tree.isEmpty
                  ? Center(child: Text("B-Tree가 비었습니다."))
                  : CustomPaint(
                      painter: BTreeViewPainter(tree, latest: latest),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<int?> showIntegerDialog(
  BuildContext context, {
  int? value,
  required Text title,
  required Text label,
}) async {
  return await showDialog(
    context: context,
    builder: (context) => _ResetAlert(
      value: value,
      title: title,
      label: label,
    ),
  ) as int?;
}

class _ResetAlert extends StatefulWidget {
  final Text title;
  final Text label;
  final int? value;
  const _ResetAlert({
    required this.title,
    required this.label,
    this.value,
  });

  @override
  State<_ResetAlert> createState() => __ResetAlertState();
}

class __ResetAlertState extends State<_ResetAlert> {
  late final controller = TextEditingController(text: widget.value?.toString());

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.title,
      content: TextFormField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          label: widget.label,
        ),
        keyboardType: TextInputType.number,
        onFieldSubmitted: (value) {
          Navigator.pop(context, int.tryParse(value));
        },
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: Text("취소"),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, int.tryParse(controller.text)),
          child: Text("확인"),
        ),
      ],
    );
  }
}

class BTreeViewPainter extends CustomPainter {
  final BTree<int> tree;
  final int? latest;

  BTreeViewPainter(this.tree, {this.latest});

  static final _paint = Paint()..color = Colors.red;
  static final _paint2 = Paint()..color = Colors.blue;
  static final _stroke = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke;
  static final _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (tree.isEmpty) return;
    int depth = 0;
    canvas.save();
    for (final node in tree.bfs()) {
      final d = node.depth;
      if (depth != d) {
        depth = d;
        canvas.restore();
        canvas.save();
        canvas.translate(0, depth * 28);
      }
      for (final key in node.keys) {
        _textPainter.text = TextSpan(text: key.toString());
        _textPainter.textAlign = TextAlign.center;
        _textPainter.layout();

        final size = Offset(0, 0) & Size(_textPainter.width, 20);
        canvas.drawRect(size, key == latest ? _paint2 : _paint);
        canvas.drawRect(size, _stroke);
        _textPainter.paint(canvas, Offset.zero);
        canvas.translate(_textPainter.width, 0);
      }
      canvas.translate(4, 0);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BTreeViewPainter oldDelegate) {
    return tree != oldDelegate.tree || latest != oldDelegate.latest;
  }
}
