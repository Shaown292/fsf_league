import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../data/core/services/auth_services.dart';
import '../../home/view/home_view.dart';
import 'login_view.dart';
import 'profile_load_failed_view.dart';
import 'profile_setup_view.dart';
import 'splash_view.dart';

class AuthGate extends GetView<AuthService> {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => switch (controller.status.value) {
        AuthStatus.initializing => const SplashView(),
        AuthStatus.signedOut => const LoginView(),
        AuthStatus.needsProfile => const ProfileSetupView(),
        AuthStatus.loadFailed => const ProfileLoadFailedView(),
        AuthStatus.signedIn => const HomeView(),
      },
    );
  }
}