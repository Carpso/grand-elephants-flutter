import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import '../services/database_service.dart';
import '../utils/file_storage.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String _role = 'user';
  String _riderStatus = 'none';
  bool _isLoading = true;

  User? get user => _user;
  String get role => _role;
  String get riderStatus => _riderStatus;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    try {
      final data = await StorageService.get<Map<String, dynamic>>(StorageService.keyUser);
      if (data != null) {
        _user = User.fromJson(data);
        _role = _user!.role;
        _riderStatus = _user!.riderStatus;
      }
    } catch (e) {
      debugPrint('Auth init error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  static bool _isValidPassword(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }

  static String? validatePassword(String password) {
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (!password.contains(RegExp(r'[A-Z]'))) return 'Password must contain an uppercase letter';
    if (!password.contains(RegExp(r'[a-z]'))) return 'Password must contain a lowercase letter';
    if (!password.contains(RegExp(r'[0-9]'))) return 'Password must contain a number';
    return null;
  }

  Future<void> signIn(String email, String pass) async {
    if (!_isValidPassword(pass)) {
      throw Exception('Password must be at least 8 characters with uppercase, lowercase, and number');
    }
    _isLoading = true;
    notifyListeners();
    try {
      await Future.delayed(const Duration(seconds: 1));
      final uid = 'user_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
      final loggedInUser = User(
        uid: uid,
        name: email.split('@').first,
        email: email,
        role: 'user',
        riderStatus: 'none',
      );
      _user = loggedInUser;
      _role = 'user';
      await StorageService.save(StorageService.keyUser, loggedInUser.toJson());
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signUp(String name, String email, String password) async {
    final passwordError = validatePassword(password);
    if (passwordError != null) throw Exception(passwordError);

    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    final uid = 'user_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
    final newUser = User(
      uid: uid,
      name: name,
      email: email,
      role: 'user',
      riderStatus: 'none',
    );
    _user = newUser;
    _role = 'user';
    await StorageService.save(StorageService.keyUser, newUser.toJson());
    await DatabaseService.syncUser(newUser.toJson());
    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await StorageService.remove(StorageService.keyUser);
      _user = null;
      _role = 'user';
      _riderStatus = 'none';
    } catch (e) {
      debugPrint('Logout error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> switchRole(String newRole) async {
    if (_user == null) return;
    if (_user!.role != 'superadmin') return;
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    _user = _user!.copyWith(role: newRole);
    _role = newRole;
    await StorageService.save(StorageService.keyUser, _user!.toJson());
    if (newRole == 'rider' && (_riderStatus == 'none' || _riderStatus.isEmpty)) {
      _riderStatus = 'pending';
    } else if (newRole != 'rider') {
      _riderStatus = 'none';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> requestRiderAccess(Map<String, dynamic> details) async {
    if (_user == null) return;
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    _riderStatus = 'pending';
    _user = _user!.copyWith(
      riderStatus: 'pending',
      bikePhoto: details['bikePhoto'] as String?,
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateUserProfile(String photoUri) async {
    if (_user == null) return;
    final savedUri = await FileStorage.saveImageLocally(photoUri);
    _user = _user!.copyWith(profilePhoto: savedUri);
    await StorageService.save(StorageService.keyUser, _user!.toJson());
    await DatabaseService.syncUser(_user!.toJson());
    notifyListeners();
  }

  Future<void> approveRider() async {
    if (_user == null || (_user!.role != 'admin' && _user!.role != 'superadmin')) return;
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    _riderStatus = 'approved';
    _user = _user!.copyWith(riderStatus: 'approved');
    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleRiderLocation(bool active) async {
    if (_user == null || _user!.role != 'rider' || _riderStatus != 'approved') return;
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    final newLocation = active
        ? const RiderLocation(lat: -26.2041, lng: 28.0473, address: 'Johannesburg, SA')
        : null;
    _user = _user!.copyWith(riderLocation: newLocation);
    _isLoading = false;
    notifyListeners();
  }
}
