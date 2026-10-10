import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../data/core/services/auth_services.dart';
import '../data/repository/auth_repository.dart';
import '../data/repository/user_repository.dart';
import '../features/auth/controller/login_controller.dart';
import '../features/auth/controller/profile_setup_controller.dart';



class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // App-lifetime: never deleted.
    Get.put(AuthRepository(FirebaseAuth.instance), permanent: true);
    Get.put(UserRepository(FirebaseFirestore.instance), permanent: true);
    Get.put(
      AuthService(auth: Get.find(), users: Get.find()),
      permanent: true,
    );

    // Shown by AuthGate (not by routes), so they are created on first use
    // and recreated if GetX ever deletes them.
    Get.lazyPut(() => LoginController(Get.find(), Get.find()), fenix: true);
    Get.lazyPut(
          () => ProfileSetupController(Get.find(), Get.find()),
      fenix: true,
    );
  }
}