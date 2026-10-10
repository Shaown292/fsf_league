import 'package:get/get.dart';

import '../controller/registration_controller.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    // Route-scoped: deleted automatically when the route is popped.
    Get.lazyPut(() => RegisterController(Get.find(), Get.find(), Get.find()));
  }
}