import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/utilities/validator.dart';
import '../../../data/core/services/auth_services.dart';
import '../../../data/repository/auth_repository.dart';



class LoginController extends GetxController {
  LoginController(this._auth, this._service);

  final AuthRepository _auth;
  final AuthService _service;

  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();

  final isLoading = false.obs;
  final obscure = true.obs;
  final error = RxnString();

  Worker? _statusWorker;

  @override
  void onInit() {
    super.onInit();
    // This controller outlives sign-out, so clear the form when it happens.
    _statusWorker = ever<AuthStatus>(_service.status, (s) {
      if (s == AuthStatus.signedOut) _reset();
    });
  }

  void toggleObscure() => obscure.toggle();

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;
    error.value = null;
    try {
      await _auth.signIn(email: email.text.trim(), password: password.text);
      // No navigation here: AuthService reacts to the auth stream.
    } on AppFailure catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> forgotPassword() async {
    final problem = Validators.email(email.text);
    if (problem != null) {
      error.value = 'Enter your email above, then tap "Forgot password?"';
      return;
    }
    try {
      await _auth.sendPasswordReset(email.text.trim());
      Get.snackbar('Check your email',
          'If an account exists for that address, a reset link was sent.');
    } on AppFailure catch (e) {
      error.value = e.message;
    }
  }

  void _reset() {
    password.clear();
    error.value = null;
    isLoading.value = false;
  }

  @override
  void onClose() {
    _statusWorker?.dispose();
    email.dispose();
    password.dispose();
    super.onClose();
  }
}