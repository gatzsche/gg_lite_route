import 'dart:async';
import 'package:gg_value/gg_value.dart';
import 'package:flutter/foundation.dart';

/// RouteNode represents a node in a route tree.
class GgRouteNode {
  // ########################
  // Constructor & Destructor
  // ########################

  GgRouteNode({
    required this.name,
    this.parent,
  }) {
    _initParent();
    _initChildren();
    _initIsActive();
    _initActiveChild();
    _initActiveDescendands();
  }

  // ...........................................................................
  /// Call this function when the node is about to be disposed.
  dispose() => _dispose.reversed.forEach((d) => d());

  // ######################
  // Name & Parent
  // ######################

  // ...........................................................................
  /// The name of the node. The name will appear as path segment in the URI.
  final String name;

  // ...........................................................................
  /// The parent node.
  final GgRouteNode? parent;

  // ######################
  // isActive
  // ######################

  // ...........................................................................
  /// Marks this node as active or inactive.
  ///
  /// - [isActive] = true: Also the parent nodes are set to active.
  /// - [isActive] = false: Also all child nodes are set to inactive.
  set isActive(bool isActive) {
    if (_isActive.value == isActive) {
      return;
    }

    _isActive.value = isActive;

    // Mark also ancestors to be active
    if (isActive) {
      parent?._childBecameActive(this);
    }
    // Mark also children to be inactive
    else {
      _children.values.forEach((child) => child.isActive = false);
      parent?._childBecameInactive(this);
    }
  }

  // ...........................................................................
  /// Returns true if this node is active.
  bool get isActive => _isActive.value;

  // ...........................................................................
  /// Returns a stream informing when isActive changes.
  Stream<bool> get onIsActive => _isActive.stream;

  // ######################
  // Children
  // ######################

  // ...........................................................................
  Iterable<GgRouteNode> get children => _children.values;

  // ...........................................................................
  /// Returns a child node with [name]. If none exists, one is created.
  GgRouteNode child({required String name}) {
    var child = _children[name];
    if (child == null) {
      child = GgRouteNode(name: name, parent: this);
      _children[name] = child;
    }
    return child;
  }

  // ...........................................................................
  /// Returns descendand that matches the path. Creates the node when needed.
  GgRouteNode descendand({required List<String> path}) {
    var result = this;
    path.forEach((element) {
      result = result.child(name: element);
    });

    return result;
  }

  // ######################
  // Active child
  // ######################

  // ...........................................................................
  /// Returns the active child or null, if no child is active.
  GgRouteNode? get activeChild => _activeChild.value;

  // ...........................................................................
  /// Informs if the active child did change.
  Stream<GgRouteNode?> get activeChildDidChange => _activeChild.stream;

  // ######################
  // Active Descendands
  // ######################

  // ...........................................................................
  /// Returns a list containing all active descendands.
  List<GgRouteNode> get activeDescendands {
    GgRouteNode? activeChild = _activeChild.value;

    final List<GgRouteNode> result = [];
    while (activeChild != null) {
      result.add(activeChild);
      activeChild = activeChild.activeChild;
    }

    return result;
  }

  // ...........................................................................
  /// A stream informing when the active descendands change.
  Stream<List<GgRouteNode>> get activeDescendandsDidChange =>
      _activeDescendands.stream;

  // ######################
  // Path
  // ######################

  // ...........................................................................
  /// Returns the path of active children.
  List<String> get activeChildPath =>
      activeDescendands.map((e) => e.name).toList();

  // ...........................................................................
  /// Creates and activates children according to the segments in [path]
  set activeChildPath(List<String> path) {
    final node = descendand(path: path);
    node.isActive = true;
    if (path.isEmpty) {
      activeChild?.isActive = false;
    }
  }

  // ######################
  // Private
  // ######################

  final List<Function()> _dispose = [];

  // ########
  // parent
  _initParent() {
    parent?._children[name] = this;
  }

  // ########
  // children

  // ...........................................................................
  /// Returns a list with the node's children.
  final _children = Map<String, GgRouteNode>();
  _initChildren() {
    _dispose.add(() {
      List.from(_children.values).forEach((child) {
        child.dispose();
      });
      parent?._removeChild(this);
    });
  }

  // ...........................................................................
  /// Removes the child
  void _removeChild(GgRouteNode child) {
    final existingChild = _children[child.name];
    assert(identical(child, existingChild));
    _children.remove(child.name);
  }

  // ########
  // isActive

  // ...........................................................................
  final _isActive = GgValue(seed: false);

  // ...........................................................................
  _initIsActive() {
    _dispose.add(() => _isActive.dispose());
  }

  // ###########
  // activeChild
  // ...........................................................................
  final _activeChild = GgValue<GgRouteNode?>(seed: null);
  _initActiveChild() {
    _dispose.add(() => _activeChild.dispose());
  }

  // ...........................................................................
  _childBecameActive(GgRouteNode child) {
    if (_activeChild.value == child) {
      return;
    }

    isActive = true;
    _activeChild.value?.isActive = false;
    _activeChild.value = child;
    _updateActiveDescendands();
  }

  // ...........................................................................
  _childBecameInactive(GgRouteNode child) {
    if (_activeChild.value != child) {
      return;
    }
    _activeChild.value = null;
    _updateActiveDescendands();
  }

  // #################
  // activeDescendands

  // ...........................................................................
  final _activeDescendands =
      GgValue<List<GgRouteNode>>(seed: [], compare: listEquals);

  _initActiveDescendands() {
    _dispose.add(() => _activeDescendands.dispose());
  }

  _updateActiveDescendands() {
    _activeDescendands.value = activeDescendands;
    parent?._updateActiveDescendands();
  }
}

// #############################################################################
/// Creates an lite route sample node.
final exampleRouteNode = ({
  String? name,
  GgRouteNode? parent,
}) =>
    GgRouteNode(
      name: name ?? 'node',
      parent: parent,
    );