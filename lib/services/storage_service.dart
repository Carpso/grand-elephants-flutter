import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String keyCart = 'cart';
  static const String keyWishlist = 'wishlist';
  static const String keyUserPreferences = 'userPreferences';
  static const String keyAuthToken = 'authToken';
  static const String keyUser = 'user';
  static const String keyRole = 'role';

  static Future<void> save<T>(String key, T value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonValue = jsonEncode(value);
      await prefs.setString(key, jsonValue);
    } catch (e) {
      rethrow;
    }
  }

  static Future<T?> get<T>(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonValue = prefs.getString(key);
      if (jsonValue == null) return null;
      return jsonDecode(jsonValue) as T;
    } catch (e) {
      return null;
    }
  }

  static Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<String>> getAllKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getKeys().toList();
    } catch (e) {
      return [];
    }
  }
}
