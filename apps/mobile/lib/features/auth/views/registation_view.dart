import 'package:flutter/material.dart';
import 'package:fsf_league_core/fsf_league_core.dart';
import 'package:get/get.dart';

import '../../../core/utilities/validator.dart';
import '../controller/registration_controller.dart';
import '../widgets/auth_widget.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create account',
      formKey: controller.formKey,
      children: [
        TextFormField(
          controller: controller.email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          validator: Validators.email,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controller.username,
          autofillHints: const [AutofillHints.newUsername],
          decoration: const InputDecoration(
            labelText: 'Username',
            helperText: '3–20 letters, numbers or underscores',
            border: OutlineInputBorder(),
          ),
          validator: Usernames.validate,
        ),
        const SizedBox(height: 16),
        Obx(
              () => TextFormField(
            controller: controller.password,
            obscureText: controller.obscure.value,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(controller.obscure.value
                    ? Icons.visibility
                    : Icons.visibility_off),
                onPressed: controller.toggleObscure,
              ),
            ),
            validator: Validators.newPassword,
          ),
        ),
        const SizedBox(height: 16),
        Obx(
              () => TextFormField(
            controller: controller.confirm,
            obscureText: controller.obscure.value,
            decoration: const InputDecoration(
              labelText: 'Confirm password',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
            v == controller.password.text ? null : 'Passwords do not match',
            onFieldSubmitted: (_) => controller.submit(),
          ),
        ),
        const SizedBox(height: 16),
        ErrorLine(error: controller.error),
        SubmitButton(
          label: 'Create account',
          isLoading: controller.isLoading,
          onPressed: controller.submit,
        ),
      ],
    );
  }
}