import 'package:flutter/material.dart';
import 'package:fsf_league_core/fsf_league_core.dart';
import 'package:get/get.dart';

import '../../../data/core/services/auth_services.dart';
import '../controller/profile_setup_controller.dart';
import '../widgets/auth_widget.dart';

class ProfileSetupView extends GetView<ProfileSetupController> {
  const ProfileSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Choose a username',
      formKey: controller.formKey,
      children: [
        const Text('Pick the name other players will see.'),
        const SizedBox(height: 16),
        TextFormField(
          controller: controller.username,
          decoration: const InputDecoration(
            labelText: 'Username',
            helperText: '3–20 letters, numbers or underscores',
            border: OutlineInputBorder(),
          ),
          validator: Usernames.validate,
          onFieldSubmitted: (_) => controller.submit(),
        ),
        const SizedBox(height: 16),
        ErrorLine(error: controller.error),
        SubmitButton(
          label: 'Continue',
          isLoading: controller.isLoading,
          onPressed: controller.submit,
        ),
        TextButton(
          onPressed: Get.find<AuthService>().signOut,
          child: const Text('Sign out'),
        ),
      ],
    );
  }
}