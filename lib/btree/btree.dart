import 'dart:collection';

import 'package:flutter/foundation.dart';

class BTree<K extends Comparable> {
  final int m;
  final int _mergeThreshold;
  var root = BNode<K>();

  BTree({
    this.m = 3,
  })  : assert(m > 2),
        _mergeThreshold = (m - 1) ~/ 2;

  K? put(K key) {
    return _put(root, key);
  }

  K? find(K key) {
    return _find(root, key);
  }

  bool contains(K key) => find(key) != null;

  Iterable<K> search({
    K? min,
    K? max,
  }) sync* {
    if (min != null && max != null) {
      assert(min.compareTo(max) <= 0);
    }
    _foundMinKey = false;
    for (final i in _search(root, min)) {
      if (max != null && i.compareTo(max) > 0) break;
      yield i;
    }
  }

  K? remove(K key) {
    return _remove(root, key);
  }

  void clear() {
    root = BNode<K>();
  }

  bool get isEmpty => root.keys.isEmpty;
  bool get isNotEmpty => !isEmpty;

  K get first {
    var node = root;
    while (true) {
      if (node.isLeaf) {
        return node.keys.first;
      }
      node = node.children.first;
    }
  }

  K get last {
    var node = root;
    while (true) {
      if (node.isLeaf) {
        return node.keys.last;
      }
      node = node.children.last;
    }
  }

  @override
  int get hashCode => Object.hash(m, root);

  @override
  bool operator ==(Object other) {
    return other is BTree<K> && m == other.m && root == other.root;
  }

  Iterable<BNode<K>> dfs() {
    return _dfs(root);
  }

  Iterable<BNode<K>> _dfs(BNode<K> node) sync* {
    yield node;
    for (final child in node.children) {
      yield* _dfs(child);
    }
  }

  Iterable<BNode<K>> bfs() sync* {
    final queue = Queue<BNode<K>>();
    queue.add(root);
    yield root;

    while (queue.isNotEmpty) {
      final node = queue.removeFirst();
      queue.addAll(node.children);
      yield* node.children;
    }
  }

  int get level {
    int lev = 0;
    BNode<K> node = root;
    while (true) {
      if (node.isLeaf) break;
      lev++;
      node = node.children.first;
    }
    return lev;
  }

  K? _put(BNode<K> node, K key) {
    K? old;
    var idx = node._indexOf(key);
    if (idx >= 0) {
      old = node.keys[idx];
      node.keys[idx] = key;
      return old;
    } else {
      idx = -(idx + 1);
      if (node.isLeaf) {
        node.keys.insert(idx, key);
        _split(node);
        return null;
      } else {
        return _put(node.children[idx], key);
      }
    }
  }

  K? _find(BNode<K> node, K key) {
    var idx = node._indexOf(key);
    if (idx >= 0) {
      return node.keys[idx];
    } else {
      if (node.isLeaf) return null;
      idx = -(idx + 1);
      return _find(node.children[idx], key);
    }
  }

  bool _foundMinKey = false;

  Iterable<K> _search(BNode<K> node, K? min) sync* {
    if (min == null || _foundMinKey) {
      if (node.isLeaf) {
        yield* node.keys;
      } else {
        for (int i = 0; i < node.children.length; i++) {
          final child = node.children[i];

          yield* _search(child, min);
          if (i < node.keys.length) {
            yield node.keys[i];
          }
        }
      }
    } else {
      var index = node._indexOf(min);
      if (index >= 0) {
        _foundMinKey = true;
        if (node.isLeaf) {
          yield* node.keys.sublist(index);
        } else {
          yield node.keys[index];
          for (int i = index + 1; i < node.children.length; i++) {
            final child = node.children[i];

            yield* _search(child, min);
            if (i < node.keys.length) {
              yield node.keys[i];
            }
          }
        }
      } else {
        index = -(index + 1);
        if (node.isLeaf) {
          _foundMinKey = true;
          yield* node.keys.sublist(index);
        } else {
          for (int i = index; i < node.children.length; i++) {
            final child = node.children[i];

            yield* _search(child, min);
            if (i < node.keys.length) {
              yield node.keys[i];
            }
          }
        }
      }
    }
  }

  K? _remove(BNode<K> node, K key) {
    var idx = node._indexOf(key);
    if (idx >= 0) {
      var old = node.keys[idx];
      if (node.isLeaf) {
        node.keys.removeAt(idx);
      } else {
        final pre = _pre(node.children[idx]);
        node.keys[idx] = pre.keys.removeLast();
        node = pre;
      }
      _merge(node, old);
      return old;
    } else {
      if (node.isLeaf) return null;
      idx = -(idx + 1);
      return _remove(node.children[idx], key);
    }
  }

  void _split(BNode<K> node) {
    if (node.keys.length < m) return;

    final keys = node.keys;
    final children = node.isLeaf ? null : node.children;
    final midIdx = keys.length >> 1;
    final midKey = keys[midIdx];

    node.keys = [midKey];
    node.children = [
      BNode(
        parent: node,
        keys: keys.sublist(0, midIdx),
        children: children?.sublist(0, midIdx + 1),
      ),
      BNode(
        parent: node,
        keys: keys.sublist(midIdx + 1),
        children: children?.sublist(midIdx + 1),
      ),
    ];

    final parent = node.parent;
    if (parent == null) return;

    var index = parent._indexOf(midKey);
    assert(index < 0);

    index = -(index + 1);
    parent.keys.insert(index, midKey);
    parent.children.replaceRange(index, index + 1, node.children);
    for (final e in node.children) {
      e.parent = parent;
    }

    _split(parent);
  }

  void _merge(BNode<K> node, K removedKey) {
    if (node.keys.length >= _mergeThreshold) return;
    final parent = node.parent;
    if (parent == null) return;

    int? lSiblingIdx;
    int? rSiblingIdx;
    var nodeChildIdx = parent._indexOf(removedKey);
    assert(nodeChildIdx < 0);
    nodeChildIdx = -(nodeChildIdx + 1);

    if (nodeChildIdx > 0) {
      lSiblingIdx = nodeChildIdx - 1;
    }
    if (nodeChildIdx < parent.keys.length) {
      rSiblingIdx = nodeChildIdx + 1;
    }

    if (lSiblingIdx != null) {
      final sibling = parent.children[lSiblingIdx];
      if (sibling.keys.length > _mergeThreshold) {
        node.keys.insert(0, parent.keys[lSiblingIdx]);
        parent.keys[lSiblingIdx] = sibling.keys.removeLast();
        return;
      }
    }
    if (rSiblingIdx != null) {
      final sibling = parent.children[rSiblingIdx];
      if (sibling.keys.length > _mergeThreshold) {
        node.keys.add(parent.keys[rSiblingIdx - 1]);
        parent.keys[rSiblingIdx - 1] = sibling.keys.removeAt(0);
        return;
      }
    }

    BNode<K> mergedNode;
    if (lSiblingIdx != null) {
      final sibling = parent.children[lSiblingIdx];
      removedKey = parent.keys.removeAt(lSiblingIdx);
      parent.children.removeAt(lSiblingIdx + 1);
      mergedNode = sibling;
      mergedNode.keys = [
        ...sibling.keys,
        removedKey,
        ...node.keys,
      ];
      mergedNode.children.addAll(node.children);
      for (var e in node.children) {
        e.parent = mergedNode;
      }
    } else {
      final sibling = parent.children[rSiblingIdx!];
      removedKey = parent.keys.removeAt(rSiblingIdx - 1);
      parent.children.removeAt(rSiblingIdx);
      mergedNode = node;
      mergedNode.keys = [
        ...node.keys,
        removedKey,
        ...sibling.keys,
      ];
      mergedNode.children.addAll(sibling.children);
      for (var e in node.children) {
        e.parent = mergedNode;
      }
    }
    if (parent.parent == null) {
      mergedNode.parent = null;
      root = mergedNode;
      return;
    }
    _merge(parent, removedKey);
  }

  BNode<K> _pre(BNode<K> node) {
    BNode<K> cur = node;
    while (!cur.isLeaf) {
      cur = cur.children.last;
    }
    return cur;
  }
}

class BNode<K extends Comparable> {
  List<K> keys;
  BNode<K>? parent;
  List<BNode<K>> children;

  BNode({
    List<K>? keys,
    this.parent,
    List<BNode<K>>? children,
  })  : keys = keys ?? [],
        children = children ?? [] {
    for (var e in this.children) {
      e.parent = this;
    }
  }

  bool get isLeaf => children.isEmpty;
  bool get isRoot => parent == null;
  int get depth {
    var p = parent;
    int d = 0;
    while (true) {
      if (p == null) break;
      d++;
      p = p.parent;
    }
    return d;
  }

  int _indexOf(K key) {
    return BUtils.binarySearch(keys, key);
  }

  @override
  int get hashCode => Object.hash(parent, keys, children);

  @override
  bool operator ==(Object other) {
    return other is BNode<K> &&
        parent == other.parent &&
        listEquals(keys, other.keys) &&
        listEquals(children, other.children);
  }

  @override
  String toString() {
    return keys.join(":");
  }
}

class BUtils {
  static int binarySearch<T extends Comparable>(List<T> sortedList, T value) {
    int min = 0;
    int max = sortedList.length;
    while (min < max) {
      final int mid = min + ((max - min) >> 1);
      final T element = sortedList[mid];
      final int comp = element.compareTo(value);
      if (comp == 0) {
        return mid;
      }
      if (comp < 0) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    return -min - 1;
  }
}
