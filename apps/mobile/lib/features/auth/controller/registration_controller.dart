import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/error/app_failure.dart';
import '../../../data/core/services/auth_services.dart';
import '../../../data/repository/auth_repository.dart';
import '../../../data/repository/user_repository.dart';



class RegisterController extends GetxController {
  RegisterController(this._auth, this._users, this._service);

  final AuthRepository _auth;
  final UserRepository _users;
  final AuthService _service;

  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();

  final isLoading = false.obs;
  final obscure = true.obs;
  final error = RxnString();

  void toggleObscure() => obscure.toggle();

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;
    error.value = null;
    try {
      final uid = await _auth.register(
        email: email.text.trim(),
        password: password.text,
      );
      try {
        await _users.create(uid: uid, username: username.text.trim());
      } on AppFailure {
        // The account exists but the profile write failed. AuthService will
        // route to the "choose username" screen so nothing is lost.
        Get.snackbar('Almost there',
            'Your account was created, but we could not save your username.');
      }
      await _service.refreshProfile();
      Get.until((route) => route.isFirst); // reveal AuthGate underneath
    } on AppFailure catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    email.dispose();
    username.dispose();
    password.dispose();
    confirm.dispose();
    super.onClose();
  }
}