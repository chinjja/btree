import 'dart:math';

import 'package:btree/btree/btree.dart';
import 'package:flutter/material.dart';

const _kNodeVerticalSpace = 56.0;
const _kNodeHorizontalSpace = 4.0;
const _kKeyHorizontalMargin = 2.0;
const _kNodeHeight = 20.0;

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

  void _delKey(int key) {
    latest = key;
    tree.remove(key);
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
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            children: [
              Column(
                children: [
                  Text("최대 자식 수: ${tree.m}"),
                  Text("최대 키 수: ${tree.m - 1}"),
                ],
              ),
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
                    child: Text("키 추가"),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final key = await showIntegerDialog(
                        context,
                        title: Text("키 입력"),
                        label: Text("키를 입력하세요."),
                      );
                      if (key == null) return;
                      _delKey(key);
                    },
                    child: Text("키 삭제"),
                  ),
                  FilledButton(
                    onPressed: () {
                      final key = random.nextInt(1000);
                      _putKey(key);
                    },
                    child: Text("랜덤 추가"),
                  ),
                ],
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
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 2000,
                        child: CustomPaint(
                          painter: BTreeViewPainter(tree, latest: latest),
                        ),
                      ),
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

  static final _paint = Paint()
    ..color = Colors.red
    ..isAntiAlias = false;
  static final _paint2 = Paint()
    ..color = Colors.blue
    ..isAntiAlias = false;
  static final _stroke = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  static final _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );

  final _childrenRect = <BNode<int>, Rect>{};
  final _nodeRect = <BNode<int>, Rect>{};

  @override
  void paint(Canvas canvas, Size size) {
    if (tree.isEmpty) return;

    _childrenRect.clear();
    _nodeRect.clear();

    var nodesByDepth = <int, List<BNode<int>>>{};
    for (final node in tree.bfs()) {
      nodesByDepth.putIfAbsent(node.depth, () => []).add(node);
    }
    for (int i = tree.level; i >= 0; i--) {
      final nodes = nodesByDepth[i]!;
      final childrenByParent = <BNode<int>?, List<BNode<int>>>{};
      for (final node in nodes) {
        childrenByParent.putIfAbsent(node.parent, () => []).add(node);
      }
      var offset = Offset(0, i * _kNodeVerticalSpace);
      for (final e in childrenByParent.entries) {
        final bound = _drawNodes(canvas, e.value, offset);
        final parent = e.key;
        if (parent != null) {
          _childrenRect[parent] = bound;
        }
        offset += Offset(bound.width + _kNodeHorizontalSpace, 0);
      }
    }

    for (final node in tree.bfs()) {
      _drawLink(canvas, node);
    }
  }

  void _drawLink(Canvas canvas, BNode<int> node) {
    final nodeRect = _nodeRect[node]!;
    for (final child in node.children) {
      final bound = _nodeRect[child]!;
      canvas.drawLine(
        nodeRect.bottomCenter,
        bound.topCenter,
        _stroke,
      );
    }
  }

  Rect _drawNodes(Canvas canvas, List<BNode<int>> nodes, Offset offset) {
    var width = 0.0;
    Rect? bound;
    for (final node in nodes) {
      final childrenBound = _childrenRect[node];
      var origin = offset + Offset(width, 0);
      if (childrenBound != null) {
        final nodeWidth = _widthNode(node);
        origin += Offset(childrenBound.width - nodeWidth, 0) / 2;
      }
      var nodeBound = _drawNode(canvas, node, origin);
      if (childrenBound != null) {
        nodeBound = nodeBound.expandToInclude(childrenBound);
        nodeBound =
            nodeBound.topLeft & Size(nodeBound.width, childrenBound.height);
      }
      if (bound != null) {
        bound = bound.expandToInclude(nodeBound);
      } else {
        bound = nodeBound;
      }
      width += nodeBound.width + _kNodeHorizontalSpace;
    }
    return bound!;
  }

  Rect _drawNode(Canvas canvas, BNode<int> node, Offset offset) {
    final pad = _kKeyHorizontalMargin * 2;
    var width = 0.0;
    final height = _kNodeHeight;
    final textStyle = TextStyle(color: Colors.white);
    for (final key in node.keys) {
      _textPainter.text = TextSpan(
        text: key.toString(),
        style: textStyle,
      );
      _textPainter.layout();

      final origin = (offset + Offset(width, 0));
      final size = Size(_textPainter.width + pad, height);
      final rect = origin & size;
      canvas.drawRect(rect, key == latest ? _paint2 : _paint);
      canvas.drawRect(rect, _stroke);
      _textPainter.paint(
          canvas,
          (offset +
              Offset(width + pad / 2, (height - _textPainter.height) / 2)));
      width += _textPainter.width + pad;
    }
    final bound = offset & Size(width, height);
    _nodeRect[node] = bound;
    return bound;
  }

  double _widthNode(BNode<int> node) {
    var width = 0.0;
    for (final key in node.keys) {
      _textPainter.text = TextSpan(text: key.toString());
      _textPainter.layout();
      width += _textPainter.width;
    }
    return width;
  }

  @override
  bool shouldRepaint(BTreeViewPainter oldDelegate) {
    return tree != oldDelegate.tree || latest != oldDelegate.latest;
  }
}
