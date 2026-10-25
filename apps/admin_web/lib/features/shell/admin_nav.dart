import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class AdminRoute {
  const AdminRoute(this.title, this.builder, {this.section = 0});
  final String title;
  final Widget Function() builder;

  /// Which navigation-rail item is highlighted (used on root routes).
  final int section;
}

class AdminNav extends GetxController {
  final stack = <AdminRoute>[].obs;
  Future<bool> Function()? _guard;

  AdminRoute get current => stack.last;
  bool get canPop => stack.length > 1;
  int get section => stack.isEmpty ? 0 : stack.first.section;

  /// A page with unsaved work registers a guard; it returns true to allow
  /// leaving. Only one page at a time uses this.
  void setGuard(Future<bool> Function() guard) => _guard = guard;
  void clearGuard() => _guard = null;

  void _leave(void Function() action) {
    final guard = _guard;
    if (guard == null) {
      action();
      return;
    }
    guard().then((ok) {
      if (!ok) return;
      _guard = null;
      action();
    });
  }

  void goRoot(AdminRoute route) => _leave(() => stack.assignAll([route]));
  void push(AdminRoute route) => stack.add(route);
  void pop() {
    if (!canPop) return;
    _leave(stack.removeLast);
  }
}