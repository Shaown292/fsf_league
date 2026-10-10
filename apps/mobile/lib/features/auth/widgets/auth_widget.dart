import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.formKey,
    required this.children,
    this.title,
  });

  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title == null ? null : AppBar(title: Text(title!)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ErrorLine extends StatelessWidget {
  const ErrorLine({super.key, required this.error});
  final RxnString error;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final message = error.value;
      if (message == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    });
  }
}

class SubmitButton extends StatelessWidget {
  const SubmitButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final RxBool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => FilledButton(
        onPressed: isLoading.value ? null : onPressed,
        child: isLoading.value
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : Text(label),
      ),
    );
  }
}