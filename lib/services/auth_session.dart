import 'package:shared_preferences/shared_preferences.dart';

/// Tracks backend (API) login so the app knows the user is logged in
/// even when there is no Firebase user.
class AuthSession {
  static const String _keyBackendLoggedIn = 'backend_logged_in';
  static const String _keyBackendEmail = 'backend_email';
  static const String _keyBackendUsername = 'backend_username';
  static const String _keyBackendUserId = 'backend_user_id';
  static const String _keyBackendPhoneNumber = 'backend_phone_number';
  static const String _keyBackendLocation = 'backend_location';
  static const String _keyBackendProfilePicture = 'backend_profile_picture';

  static Future<void> setBackendLoggedIn({
    required String email,
    String? username,
    String? userId,
    String? phoneNumber,
    String? location,
    String? profilePicture,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBackendLoggedIn, true);
    await prefs.setString(_keyBackendEmail, email);
    if (username != null && username.isNotEmpty) {
      await prefs.setString(_keyBackendUsername, username);
    }
    if (userId != null && userId.isNotEmpty) {
      await prefs.setString(_keyBackendUserId, userId);
    }
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      await prefs.setString(_keyBackendPhoneNumber, phoneNumber);
    } else {
      await prefs.remove(_keyBackendPhoneNumber);
    }
    if (location != null && location.isNotEmpty) {
      await prefs.setString(_keyBackendLocation, location);
    } else {
      await prefs.remove(_keyBackendLocation);
    }
    if (profilePicture != null && profilePicture.isNotEmpty) {
      await prefs.setString(_keyBackendProfilePicture, profilePicture);
    } else {
      await prefs.remove(_keyBackendProfilePicture);
    }
  }

  static Future<void> clearBackendSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBackendLoggedIn);
    await prefs.remove(_keyBackendEmail);
    await prefs.remove(_keyBackendUsername);
    await prefs.remove(_keyBackendUserId);
    await prefs.remove(_keyBackendPhoneNumber);
    await prefs.remove(_keyBackendLocation);
    await prefs.remove(_keyBackendProfilePicture);
  }

  static Future<bool> isBackendLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBackendLoggedIn) ?? false;
  }

  static Future<String?> getBackendEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBackendEmail);
  }

  static Future<String?> getBackendUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBackendUsername);
  }

  static Future<String?> getBackendUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBackendUserId);
  }

  static Future<String?> getBackendPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBackendPhoneNumber);
  }

  static Future<String?> getBackendLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBackendLocation);
  }

  static Future<String?> getBackendProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBackendProfilePicture);
  }
}
