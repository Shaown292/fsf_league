import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/core/services/auth_services.dart';


class ProfileLoadFailedView extends GetView<AuthService> {
  const ProfileLoadFailedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'We could not load your profile. Check your connection.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: controller.refreshProfile,
                child: const Text('Retry'),
              ),
              TextButton(
                onPressed: controller.signOut,
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}