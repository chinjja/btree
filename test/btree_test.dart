import 'package:btree/btree/btree.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('key size 4', () {
    final tree = BTree<int>(m: 5);
    tree.put(150);
    tree.put(100);
    tree.put(200);
    tree.put(50);

    expect(tree.level, 0);
    expect(tree.root.keys, [50, 100, 150, 200]);
    expect(tree.root.isLeaf, true);

    tree.put(120);
    tree.put(130);
    tree.put(140);

    expect(tree.level, 1);
    expect(tree.root.keys, [120]);
    expect(tree.root.children[0].keys, [50, 100]);
    expect(tree.root.children[0].parent, tree.root);
    expect(tree.root.children[1].keys, [130, 140, 150, 200]);
    expect(tree.root.children[1].parent, tree.root);
    expect(tree.root.children.length, 2);
    expect(tree.root.children.every((e) => e.isLeaf), true);

    tree.put(180);

    expect(tree.level, 1);
    expect(tree.root.keys, [120, 150]);
    expect(tree.root.children[0].keys, [50, 100]);
    expect(tree.root.children[1].keys, [130, 140]);
    expect(tree.root.children[2].keys, [180, 200]);
    expect(tree.root.children.length, 3);
    expect(tree.root.children.every((e) => e.isLeaf), true);
    expect(tree.root.children.every((e) => e.parent == tree.root), true);

    tree.put(60);
    tree.put(70);
    tree.put(80);

    expect(tree.level, 1);
    expect(tree.root.keys, [70, 120, 150]);
    expect(tree.root.children[0].keys, [50, 60]);
    expect(tree.root.children[1].keys, [80, 100]);
    expect(tree.root.children[2].keys, [130, 140]);
    expect(tree.root.children[3].keys, [180, 200]);
    expect(tree.root.children.length, 4);
    expect(tree.root.children.every((e) => e.isLeaf), true);
    expect(tree.root.children.every((e) => e.parent == tree.root), true);

    tree.put(81);
    tree.put(82);
    tree.put(83);

    expect(tree.level, 1);
    expect(tree.root.keys, [70, 82, 120, 150]);
    expect(tree.root.children[0].keys, [50, 60]);
    expect(tree.root.children[1].keys, [80, 81]);
    expect(tree.root.children[2].keys, [83, 100]);
    expect(tree.root.children[3].keys, [130, 140]);
    expect(tree.root.children[4].keys, [180, 200]);
    expect(tree.root.children.length, 5);
    expect(tree.root.children.every((e) => e.isLeaf), true);
    expect(tree.root.children.every((e) => e.parent == tree.root), true);

    expect(tree.put(180), 180);

    expect(tree.put(131), isNull);
    tree.put(132);
    tree.put(133);

    expect(tree.level, 2);
    expect(tree.root.keys, [120]);
    expect(tree.root.children[0].keys, [70, 82]);
    expect(tree.root.children[1].keys, [132, 150]);
    expect(tree.root.children[0].children[0].keys, [50, 60]);
    expect(tree.root.children[0].children[1].keys, [80, 81]);
    expect(tree.root.children[0].children[2].keys, [83, 100]);
    expect(tree.root.children[1].children[0].keys, [130, 131]);
    expect(tree.root.children[1].children[1].keys, [133, 140]);
    expect(tree.root.children[1].children[2].keys, [180, 200]);
    expect(tree.root.children.every((e) => e.parent == tree.root), true);
    expect(
      tree.root.children[0].children
          .every((e) => e.parent == tree.root.children[0]),
      true,
    );
    expect(
      tree.root.children[1].children
          .every((e) => e.parent == tree.root.children[1]),
      true,
    );
  });

  test('key size 3', () {
    final tree = BTree(m: 4);
    for (int i = 0; i <= 10; i++) {
      tree.put(i);
    }
    expect(tree.level, 1);
    expect(tree.root.keys, [2, 5, 8]);
    expect(tree.root.children[0].keys, [0, 1]);
    expect(tree.root.children[1].keys, [3, 4]);
    expect(tree.root.children[2].keys, [6, 7]);
    expect(tree.root.children[3].keys, [9, 10]);

    for (int i = 11; i <= 20; i++) {
      tree.put(i);
    }

    expect(tree.level, 2);
    expect(tree.root.keys, [8]);
    expect(tree.root.children[0].keys, [2, 5]);
    expect(tree.root.children[1].keys, [11, 14, 17]);
    expect(tree.root.children[0].children[0].keys, [0, 1]);
    expect(tree.root.children[0].children[1].keys, [3, 4]);
    expect(tree.root.children[0].children[2].keys, [6, 7]);
    expect(tree.root.children[1].children[0].keys, [9, 10]);
    expect(tree.root.children[1].children[1].keys, [12, 13]);
    expect(tree.root.children[1].children[2].keys, [15, 16]);
    expect(tree.root.children[1].children[3].keys, [18, 19, 20]);
    expect(tree.root.children.every((e) => e.parent == tree.root), true);
    expect(
      tree.root.children[0].children
          .every((e) => e.parent == tree.root.children[0]),
      true,
    );
    expect(
      tree.root.children[1].children
          .every((e) => e.parent == tree.root.children[1]),
      true,
    );
  });

  group('with tree', () {
    late BTree<int> tree;
    late List<int> source;
    setUp(() {
      source = [
        50,
        60,
        70,
        80,
        81,
        82,
        83,
        100,
        150,
        120,
        130,
        131,
        132,
        133,
        140,
        180,
        200,
        141,
      ];
      tree = BTree<int>(m: 5);
      for (final value in source) {
        tree.put(value);
      }
    });

    test('structure', () {
      expect(tree.root.keys, [120]);
      expect(tree.root.children[0].keys, [70, 82]);
      expect(tree.root.children[1].keys, [132, 150]);
      expect(tree.root.children[0].children[0].keys, [50, 60]);
      expect(tree.root.children[0].children[1].keys, [80, 81]);
      expect(tree.root.children[0].children[2].keys, [83, 100]);
      expect(tree.root.children[1].children[0].keys, [130, 131]);
      expect(tree.root.children[1].children[1].keys, [133, 140, 141]);
      expect(tree.root.children[1].children[2].keys, [180, 200]);
    });

    test('first', () {
      expect(tree.first, 50);
    });

    test('last', () {
      expect(tree.last, 200);
    });

    test('when not exists then should return null', () {
      expect(tree.find(77), isNull);
    });

    test('when not contains then should return false', () {
      expect(tree.contains(77), false);
    });

    test('when exists then should return non-null', () {
      expect(tree.find(133), 133);
    });

    test('when exists then should return true', () {
      expect(tree.contains(133), true);
    });

    test('remove internal node', () {
      tree.remove(120);

      expect(tree.root.keys, [70, 100, 132, 150]);
      expect(tree.root.children[0].keys, [50, 60]);
      expect(tree.root.children[1].keys, [80, 81, 82, 83]);
      expect(tree.root.children[2].keys, [130, 131]);
      expect(tree.root.children[3].keys, [133, 140, 141]);
      expect(tree.root.children[4].keys, [180, 200]);
      expect(tree.root.children.every((e) => e.parent == tree.root), true);
    });

    test('remove leaf node', () {
      tree.remove(140);

      expect(tree.root.keys, [120]);
      expect(tree.root.children[0].keys, [70, 82]);
      expect(tree.root.children[1].keys, [132, 150]);
      expect(tree.root.children[0].children[0].keys, [50, 60]);
      expect(tree.root.children[0].children[1].keys, [80, 81]);
      expect(tree.root.children[0].children[2].keys, [83, 100]);
      expect(tree.root.children[1].children[0].keys, [130, 131]);
      expect(tree.root.children[1].children[1].keys, [133, 141]);
      expect(tree.root.children[1].children[2].keys, [180, 200]);
    });

    test('when sibling node have extra key then should rotate to right', () {
      tree.remove(130);

      expect(tree.root.children[1].keys, [133, 150]);
      expect(tree.root.children[1].children[0].keys, [131, 132]);
      expect(tree.root.children[1].children[1].keys, [140, 141]);
      expect(tree.root.children[1].children[2].keys, [180, 200]);
    });

    test('when sibling node have extra key then should rotate to left', () {
      tree.remove(180);

      expect(tree.root.children[1].keys, [132, 141]);
      expect(tree.root.children[1].children[0].keys, [130, 131]);
      expect(tree.root.children[1].children[1].keys, [133, 140]);
      expect(tree.root.children[1].children[2].keys, [150, 200]);
    });

    test("remove all", () {
      for (final k in source) {
        tree.remove(k);
      }
      expect(tree.isEmpty, true);
    });

    test("search range leaf 1", () {
      final res = tree.search(min: 100, max: 150);
      expect(res, [100, 120, 130, 131, 132, 133, 140, 141, 150]);
    });

    test("search range leaf 2", () {
      final res = tree.search(min: 99, max: 150);
      expect(res, [100, 120, 130, 131, 132, 133, 140, 141, 150]);
    });

    test("search range internal", () {
      final res = tree.search(min: 82, max: 150);
      expect(res, [82, 83, 100, 120, 130, 131, 132, 133, 140, 141, 150]);
    });

    test("search range min only", () {
      final res = tree.search(min: 100);
      expect(res, [100, 120, 130, 131, 132, 133, 140, 141, 150, 180, 200]);
    });

    test("search range max only", () {
      final res = tree.search(max: 100);
      expect(res, [50, 60, 70, 80, 81, 82, 83, 100]);
    });

    test("search range all", () {
      final res = tree.search();
      expect(res, source..sort());
    });

    test("search range empty", () {
      final res = tree.search(min: 98, max: 99);
      expect(res, []);
    });

    test("search range 100", () {
      final res = tree.search(min: 100, max: 100);
      expect(res, [100]);
    });
  });
}
