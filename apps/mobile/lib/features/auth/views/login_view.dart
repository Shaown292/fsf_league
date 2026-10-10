import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/app_routes.dart';
import '../../../core/utilities/validator.dart';
import '../controller/login_controller.dart';
import '../widgets/auth_widget.dart';


class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      formKey: controller.formKey,
      children: [
        Text(
          'FSF League',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
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
        Obx(
              () => TextFormField(
            controller: controller.password,
            obscureText: controller.obscure.value,
            autofillHints: const [AutofillHints.password],
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
            validator: Validators.required,
            onFieldSubmitted: (_) => controller.submit(),
          ),
        ),
        const SizedBox(height: 16),
        ErrorLine(error: controller.error),
        SubmitButton(
          label: 'Sign in',
          isLoading: controller.isLoading,
          onPressed: controller.submit,
        ),
        TextButton(
          onPressed: controller.forgotPassword,
          child: const Text('Forgot password?'),
        ),
        TextButton(
          onPressed: () => Get.toNamed(AppRoutes.register),
          child: const Text('Create an account'),
        ),
      ],
    );
  }
}