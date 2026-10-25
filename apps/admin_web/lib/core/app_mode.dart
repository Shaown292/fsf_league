import 'package:flutter/foundation.dart';

/// Debug builds use the emulators by default, so forgetting a flag can no
/// longer point you at the real project. Release builds (what you deploy)
/// never do. Override with --dart-define=USE_EMULATOR=false.
const useEmulator =
bool.fromEnvironment('USE_EMULATOR', defaultValue: kDebugMode);