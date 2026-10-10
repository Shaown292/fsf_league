import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/error/app_failure.dart';
import '../../../data/core/services/auth_services.dart';
import '../../../data/repository/auth_repository.dart';
import '../../../data/repository/user_repository.dart';



class ProfileSetupController extends GetxController {
  ProfileSetupController(this._users, this._service);

  final UserRepository _users;
  final AuthService _service;

  final formKey = GlobalKey<FormState>();
  final username = TextEditingController();
  final isLoading = false.obs;
  final error = RxnString();

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    final uid = Get.find<AuthRepository>().currentUser?.uid;
    if (uid == null) return;

    isLoading.value = true;
    error.value = null;
    try {
      await _users.create(uid: uid, username: username.text.trim());
      await _service.refreshProfile();
    } on AppFailure catch (e) {
      error.value = e.message;
      // A timed-out write may still have reached the server; re-check.
      await _service.refreshProfile();
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    username.dispose();
    super.onClose();
  }
}