import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../core/error/app_failure.dart';
import '../../models/user_profile.dart';
import '../../repository/auth_repository.dart';
import '../../repository/user_repository.dart';



enum AuthStatus { initializing, signedOut, needsProfile, signedIn, loadFailed }

class AuthService extends GetxService {
  AuthService({required AuthRepository auth, required UserRepository users})
      : _auth = auth,
        _users = users;

  final AuthRepository _auth;
  final UserRepository _users;

  final status = AuthStatus.initializing.obs;
  final profile = Rxn<UserProfile>();

  StreamSubscription<User?>? _subscription;
  int _loadTicket = 0;

  @override
  void onInit() {
    super.onInit();
    _subscription = _auth.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      _loadTicket++; // invalidate any in-flight profile load
      profile.value = null;
      status.value = AuthStatus.signedOut;
      return;
    }
    await refreshProfile();
  }

  Future<void> refreshProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ticket = ++_loadTicket;
    try {
      final loaded = await _users.fetch(user.uid);
      if (ticket != _loadTicket) return; // a newer load superseded this one
      profile.value = loaded;
      status.value =
      loaded == null ? AuthStatus.needsProfile : AuthStatus.signedIn;
    } on AppFailure {
      if (ticket != _loadTicket) return;
      status.value = AuthStatus.loadFailed;
    }
  }

  Future<void> signOut() => _auth.signOut();

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}