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

  AdminRoute get current => stack.last;
  bool get canPop => stack.length > 1;
  int get section => stack.isEmpty ? 0 : stack.first.section;

  void goRoot(AdminRoute route) => stack.assignAll([route]);
  void push(AdminRoute route) => stack.add(route);
  void pop() {
    if (canPop) stack.removeLast();
  }
}