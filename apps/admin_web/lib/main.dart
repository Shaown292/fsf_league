import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'admin_gate.dart';
import 'core/app_mode.dart';
import 'data/contest_repository.dart';
import 'data/player_library_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (useEmulator) {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }

  Get.put(ContestRepository(FirebaseFirestore.instance), permanent: true);
  Get.put(PlayerLibraryRepository(FirebaseFirestore.instance), permanent: true);
  runApp(const FsfLeagueAdminApp());
}

class FsfLeagueAdminApp extends StatelessWidget {
  const FsfLeagueAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'FSF League Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const AdminGate(),
    );
  }
}