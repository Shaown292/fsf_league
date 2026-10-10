/// Must stay in sync with validUsername() in firebase/firestore.rules.
final RegExp _usernamePattern = RegExp(r'^[A-Za-z0-9_]{3,20}$');

abstract final class Usernames {
  static bool isValid(String value) => _usernamePattern.hasMatch(value);

  static String? validate(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Choose a username';
    if (v.length < 3 || v.length > 20) return 'Use 3 to 20 characters';
    if (!isValid(v)) return 'Letters, numbers and underscores only';
    return null;
  }
}
