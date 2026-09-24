import 'package:flutter/foundation.dart';
import '../models/business_collection_number.dart';
import '../services/api_client.dart';
import '../services/storage_service.dart';

/// Business-scoped mobile money collection numbers.
///
/// Every read/write goes through `/api/businesses/me/collection-numbers`; the
/// local copy is only a cache used when the server cannot be reached (offline
/// fallback) so the UI never presents unsaved local state as server data.
class CollectionNumberProvider extends ChangeNotifier {
  List<BusinessCollectionNumber> _numbers = [];
  bool _isLoading = false;
  String? _error;
  bool _fromServer = false;

  List<BusinessCollectionNumber> get numbers => _numbers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get fromServer => _fromServer;

  static const _storageKey = 'business_collection_numbers';
  static const _path = '/api/businesses/me/collection-numbers';

  CollectionNumberProvider() {
    _restoreCache();
    load();
  }

  Future<void> _restoreCache() async {
    try {
      final stored = await StorageService.get<List<dynamic>>(_storageKey);
      if (stored == null) return;
      _numbers = stored
          .map((e) => parseNumber(Map<String, dynamic>.from(e as Map)))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Collection number cache restore failed: $e');
    }
  }

  Future<void> _persist() async {
    try {
      await StorageService.save(
        _storageKey,
        _numbers.map((e) => e.toJson()).toList(),
      );
    } catch (e) {
      debugPrint('Collection number cache save failed: $e');
    }
  }

  /// Fetches the server truth for the signed-in business.
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiClient.instance.get(_path);
      _numbers = _extractList(res)
          .map((e) => parseNumber(Map<String, dynamic>.from(e as Map)))
          .toList();
      _fromServer = true;
      await _persist();
    } catch (e) {
      _error = _messageOf(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  Future<bool> addNumber(BusinessCollectionNumber number) =>
      _mutate(() => ApiClient.instance.post(_path, body: toPayload(number)));

  Future<bool> updateNumber(String id, BusinessCollectionNumber updated) =>
      _mutate(() => ApiClient.instance.put('$_path/$id', body: toPayload(updated)));

  Future<bool> removeNumber(String id) =>
      _mutate(() => ApiClient.instance.delete('$_path/$id'));

  Future<bool> toggleActive(String id) async {
    final index = _numbers.indexWhere((n) => n.id == id);
    if (index < 0) return false;
    return updateNumber(
      id,
      _numbers[index].copyWith(
        isActive: !_numbers[index].isActive,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<bool> setDefault(String id) async {
    var ok = true;
    String? failure;
    for (final number in List.of(_numbers)) {
      final shouldBeDefault = number.id == id;
      if (number.isDefault == shouldBeDefault) continue;
      final updated = number.copyWith(
        isDefault: shouldBeDefault,
        updatedAt: DateTime.now(),
      );
      final result = await _mutate(
        () => ApiClient.instance.put('$_path/${number.id}', body: toPayload(updated)),
        refresh: false,
      );
      if (!result) {
        ok = false;
        failure ??= _error;
      }
    }
    await load();
    if (!ok) {
      _error = failure ?? _error;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> _mutate(
    Future<dynamic> Function() request, {
    bool refresh = true,
  }) async {
    try {
      await request();
      if (refresh) {
        await load();
      } else {
        _error = null;
        await _persist();
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = _messageOf(e);
      notifyListeners();
      return false;
    }
  }

  /// Tolerant parser: the server owns the shape, this client only fills in the
  /// fields the model requires so a partial payload can never crash the UI.
  static BusinessCollectionNumber parseNumber(Map<String, dynamic> json) {
    final now = DateTime.now().toIso8601String();
    return BusinessCollectionNumber.fromJson({
      ...json,
      'id': '${json['id'] ?? json['_id'] ?? ''}',
      'businessName': '${json['businessName'] ?? ''}',
      'businessId': '${json['businessId'] ?? ''}',
      'network': '${json['network'] ?? 'mtn'}',
      'phoneNumber': '${json['phoneNumber'] ?? json['phone'] ?? ''}',
      'tillNumber': '${json['tillNumber'] ?? ''}',
      'isActive': json['isActive'] is bool ? json['isActive'] : true,
      'isDefault': json['isDefault'] is bool ? json['isDefault'] : false,
      'createdAt': '${json['createdAt'] ?? now}',
      'updatedAt': '${json['updatedAt'] ?? now}',
      'addedBy': '${json['addedBy'] ?? ''}',
    });
  }

  static Map<String, dynamic> toPayload(BusinessCollectionNumber number) => {
        'network': number.network.name,
        'phoneNumber': number.phoneNumber,
        'tillNumber': number.tillNumber,
        'businessName': number.businessName,
        'businessId': number.businessId,
        'isActive': number.isActive,
        'isDefault': number.isDefault,
        'addedBy': number.addedBy,
      };

  static List<dynamic> _extractList(dynamic res) {
    if (res is List) return res;
    if (res is Map<String, dynamic>) {
      for (final key in ['collectionNumbers', 'numbers', 'data']) {
        final value = res[key];
        if (value is List) return value;
      }
      if (res['collectionNumber'] is Map) return [res['collectionNumber']];
      if (res['number'] is Map) return [res['number']];
    }
    return const [];
  }

  static String _messageOf(Object e) =>
      '$e'.replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
}
