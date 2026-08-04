import 'package:flutter/foundation.dart';
import '../models/business_collection_number.dart';
import '../services/storage_service.dart';

class CollectionNumberProvider extends ChangeNotifier {
  List<BusinessCollectionNumber> _numbers = [];
  bool _isLoading = false;
  String? _error;

  List<BusinessCollectionNumber> get numbers => _numbers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const _storageKey = 'business_collection_numbers';

  CollectionNumberProvider() {
    _loadNumbers();
  }

  Future<void> _loadNumbers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final stored = await StorageService.get<List<dynamic>>(_storageKey);
      if (stored != null) {
        _numbers = stored
            .map((e) =>
                BusinessCollectionNumber.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _error = 'Failed to load collection numbers: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _persist() async {
    await StorageService.save(
      _storageKey,
      _numbers.map((e) => e.toJson()).toList(),
    );
  }

  List<BusinessCollectionNumber> getActiveNumbers() =>
      _numbers.where((n) => n.isActive).toList();

  BusinessCollectionNumber? getDefaultNumber() {
    final defaults = _numbers.where((n) => n.isActive && n.isDefault).toList();
    if (defaults.isNotEmpty) return defaults.first;
    final active = _numbers.where((n) => n.isActive).toList();
    return active.isNotEmpty ? active.first : null;
  }

  List<BusinessCollectionNumber> getNumbersByNetwork(
          MobileMoneyNetwork network) =>
      _numbers.where((n) => n.isActive && n.network == network).toList();

  Future<void> addNumber(BusinessCollectionNumber number) async {
    _numbers.add(number);
    await _persist();
    notifyListeners();
  }

  Future<void> updateNumber(String id, BusinessCollectionNumber updated) async {
    final index = _numbers.indexWhere((n) => n.id == id);
    if (index >= 0) {
      _numbers[index] = updated;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> removeNumber(String id) async {
    _numbers.removeWhere((n) => n.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> toggleActive(String id) async {
    final index = _numbers.indexWhere((n) => n.id == id);
    if (index >= 0) {
      _numbers[index] = _numbers[index].copyWith(
        isActive: !_numbers[index].isActive,
        updatedAt: DateTime.now(),
      );
      await _persist();
      notifyListeners();
    }
  }

  Future<void> setDefault(String id) async {
    for (var i = 0; i < _numbers.length; i++) {
      _numbers[i] = _numbers[i].copyWith(
        isDefault: _numbers[i].id == id,
        updatedAt: DateTime.now(),
      );
    }
    await _persist();
    notifyListeners();
  }
}