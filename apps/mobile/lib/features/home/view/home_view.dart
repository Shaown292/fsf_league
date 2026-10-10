import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/core/services/auth_services.dart';


class HomeView extends GetView<AuthService> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FSF League'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: controller.signOut,
          ),
        ],
      ),
      body: Center(
        child: Obx(
              () => Text('Welcome, ${controller.profile.value?.username ?? ''}'),
        ),
      ),
    );
  }
}