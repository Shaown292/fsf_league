import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/config/env.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (Env.useEmulator) {
    await FirebaseAuth.instance.useAuthEmulator(Env.emulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(Env.emulatorHost, 8080);
  }

  runApp(const FsfLeagueApp());
}