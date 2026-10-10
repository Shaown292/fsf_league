abstract final class Env {
  static const useEmulator = bool.fromEnvironment('USE_EMULATOR');
  // 10.0.2.2 is the host PC as seen from the Android emulator.
  static const emulatorHost =
  String.fromEnvironment('EMULATOR_HOST', defaultValue: '10.0.2.2');
}