class DatabaseService {
  static Future<void> syncUser(Map<String, dynamic> user) async {
    try {
      if (user['uid'] == null) {
        throw Exception('User ID is required to sync user data');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> updateUser(
      String uid, Map<String, dynamic> data) async {
    try {
    } catch (e) {
      rethrow;
    }
  }
}
