import 'package:lipila_flutter/lipila_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/business_collection_number.dart';

class LipilaPaymentResult {
  final bool success;
  final String? transactionId;
  final String? referenceId;
  final String? message;
  final String? status;

  const LipilaPaymentResult({
    required this.success,
    this.transactionId,
    this.referenceId,
    this.message,
    this.status,
  });
}

class LipilaPaymentService {
  LipilaClient? _client;
  bool _initialized = false;

  static const _secureKey = 'lipila_api_key';
  static const _envKey = 'lipila_environment';
  final _secureStorage = const FlutterSecureStorage();

  bool get isInitialized => _initialized;

  Future<void> initialize({String? apiKey, bool useSandbox = true}) async {
    try {
      final key = apiKey ?? await _secureStorage.read(key: _secureKey);
      if (key == null || key.isEmpty) {
        _initialized = false;
        return;
      }

      _client = useSandbox
          ? LipilaClient.sandbox(key)
          : LipilaClient.production(key);

      await _secureStorage.write(key: _secureKey, value: key);
      await _secureStorage.write(
          key: _envKey, value: useSandbox ? 'sandbox' : 'production');
      _initialized = true;
    } catch (e) {
      _initialized = false;
    }
  }

  Future<LipilaPaymentResult> collectMobileMoney({
    required double amount,
    required String customerPhone,
    required String orderReference,
    required BusinessCollectionNumber collectionNumber,
  }) async {
    try {
      if (_client == null) {
        return const LipilaPaymentResult(
          success: false,
          message: 'Lipila client not initialized',
        );
      }

      final normalizedPhone = _normalizePhone(customerPhone);
      final collection = await _client!.collections.createCollection(
        referenceId: orderReference,
        amount: amount,
        accountNumber: normalizedPhone,
        currency: 'ZMW',
        narration:
            'Payment to ${collectionNumber.businessName} (${collectionNumber.network.displayName})',
      );

      return LipilaPaymentResult(
        success: collection.status == 'pending' || collection.status == 'successful',
        transactionId: collection.identifier,
        referenceId: collection.referenceId,
        message: collection.message ?? 'Payment prompt sent to $customerPhone',
        status: collection.status,
      );
    } on ValidationException catch (e) {
      return LipilaPaymentResult(
        success: false,
        message: 'Validation error: ${e.message}',
      );
    } on NetworkException catch (e) {
      return LipilaPaymentResult(
        success: false,
        message: 'Network error: ${e.message}',
      );
    } on AuthException catch (e) {
      return LipilaPaymentResult(
        success: false,
        message: 'Authentication failed: ${e.message}',
      );
    } on ApiException catch (e) {
      return LipilaPaymentResult(
        success: false,
        message: 'Payment error: ${e.message}',
      );
    } catch (e) {
      return LipilaPaymentResult(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  Future<LipilaPaymentResult> checkPaymentStatus(String referenceId) async {
    try {
      if (_client == null) {
        return const LipilaPaymentResult(
          success: false,
          message: 'Lipila client not initialized',
        );
      }

      final status = await _client!.status.checkCollectionStatus(referenceId);

      return LipilaPaymentResult(
        success: status.status == 'successful',
        referenceId: referenceId,
        message: status.message,
        status: status.status,
      );
    } catch (e) {
      return LipilaPaymentResult(
        success: false,
        message: 'Status check failed: $e',
      );
    }
  }

  Future<LipilaPaymentResult> disburseToBusiness({
    required double amount,
    required BusinessCollectionNumber collectionNumber,
    required String referenceId,
  }) async {
    try {
      if (_client == null) {
        return const LipilaPaymentResult(
          success: false,
          message: 'Lipila client not initialized',
        );
      }

      final normalizedPhone = _normalizePhone(collectionNumber.phoneNumber);
      final disbursement =
          await _client!.disbursements.createMobileDisbursement(
        referenceId: referenceId,
        amount: amount,
        accountNumber: normalizedPhone,
        currency: 'ZMW',
        narration:
            'Settlement for ${collectionNumber.businessName} (${collectionNumber.network.displayName})',
      );

      return LipilaPaymentResult(
        success: disbursement.status == 'successful',
        transactionId: disbursement.identifier,
        referenceId: disbursement.referenceId,
        message: 'Disbursement initiated to ${collectionNumber.businessName}',
        status: disbursement.status,
      );
    } catch (e) {
      return LipilaPaymentResult(
        success: false,
        message: 'Disbursement failed: $e',
      );
    }
  }

  Future<LipilaPaymentResult> checkBalance() async {
    try {
      if (_client == null) {
        return const LipilaPaymentResult(
          success: false,
          message: 'Lipila client not initialized',
        );
      }

      final balance = await _client!.balance.getBalance();
      final bal = balance.data?.balance?.toDouble() ?? 0;
      return LipilaPaymentResult(
        success: balance.success ?? false,
        message: 'Balance: $bal ZMW',
        status: 'ZMW',
      );
    } catch (e) {
      return LipilaPaymentResult(
        success: false,
        message: 'Balance check failed: $e',
      );
    }
  }

  String _normalizePhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('260')) {
      if (cleaned.length != 12) return '';
      return cleaned;
    }
    if (cleaned.startsWith('0')) {
      final result = '260${cleaned.substring(1)}';
      if (result.length != 12) return '';
      return result;
    }
    final result = '260$cleaned';
    if (result.length != 12) return '';
    return result;
  }

  void dispose() {
    _client?.close();
    _client = null;
    _initialized = false;
  }
}