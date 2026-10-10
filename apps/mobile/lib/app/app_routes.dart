import 'package:get/get.dart';

import '../features/auth/bindings/register_bindings.dart';
import '../features/auth/views/registation_view.dart';


abstract final class AppRoutes {
  static const register = '/register';
}

abstract final class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterView(),
      binding: RegisterBinding(),
    ),
  ];
}