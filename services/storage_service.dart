import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // Keys for SharedPreferences
  static const String _accessTokenKey = 'access_token';
  static const String _userIdKey = 'user_id';
  static const String _userPhoneNumberKey = 'user_phone_number';

  /// Saves the access token to SharedPreferences
  static Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, token);
  }

  /// Retrieves the access token from SharedPreferences
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// Saves the user phone number to SharedPreferences
  static Future<void> saveUserPhone(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userPhoneNumberKey, phoneNumber);
  }

  /// Retrieves the user phone number from SharedPreferences
  static Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPhoneNumberKey);
  }

  /// Saves the user ID to SharedPreferences
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  /// Retrieves the user ID from SharedPreferences
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// Clears all stored data (both token and user ID)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userPhoneNumberKey); // Clear user phone number as well
    // Alternatively, to clear everything:
    // await prefs.clear();
  }
}
