import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../features/auth/views/auth_gate.dart';
import 'app_routes.dart';
import 'initial_bindings.dart';

class FsfLeagueApp extends StatelessWidget {
  const FsfLeagueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'FSF League',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      initialBinding: InitialBinding(),
      getPages: AppPages.pages,
      home: const AuthGate(),
    );
  }
}