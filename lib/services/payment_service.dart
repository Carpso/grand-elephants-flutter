import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_config.dart';

class PaymentService {
  static const double _devFee = 0.04;
  static const double _platformTotal = 0.05;
  static const double _clientRevenue = 0.95;

  static Future<Map<String, dynamic>> initiateCollection({
    required double amount,
    required String userEmail,
    required String tenantId,
  }) async {
    final totalAmount = amount;
    final platformCut = totalAmount * _platformTotal;
    final clientShare = totalAmount * _clientRevenue;

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.lencoBaseUrl}/collections/initialize'),
        headers: {
          'Authorization': 'Bearer ${AppConfig.lencoSecretKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': (totalAmount * 100).toInt(),
          'email': userEmail,
          'reference': 'tx_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
          'currency': 'ZMW',
          'channels': ['card', 'mobile_money', 'ussd', 'bank_transfer'],
          'metadata': {
            'tenant_id': tenantId,
            'platform_fee': platformCut,
            'client_share': clientShare,
            'split_logic': '1_lenco_4_dev_95_client',
          },
        }),
      );

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> initiatePayout({
    required double amount,
    required String phoneNumber,
    required String network,
    required String tenantId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.lencoBaseUrl}/payouts'),
        headers: {
          'Authorization': 'Bearer ${AppConfig.lencoSecretKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': (amount * 100).toInt(),
          'account_number': phoneNumber,
          'account_name': 'Client App Admin Payout',
          'bank_code': network,
          'currency': 'ZMW',
          'reference': 'payout_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
          'metadata': {
            'tenant_id': tenantId,
            'note': 'Revenue share payout minus 5% app fees',
          },
        }),
      );

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  static Map<String, dynamic>? handleWebhook(Map<String, dynamic> payload, {String? signature}) {
    if (signature == null || signature.isEmpty) return null;

    final metadata =
        payload['metadata'] as Map<String, dynamic>? ??
        (payload['data'] as Map<String, dynamic>?)?['metadata']
            as Map<String, dynamic>?;
    final tenantId = metadata?['tenant_id'];

    if (payload['event'] == 'collection.success') {
      final data = payload['data'] as Map<String, dynamic>?;
      final total = ((data?['amount'] as num?)?.toDouble() ?? 0) / 100;
      final devFee = total * _devFee;
      final clientShare = total * _clientRevenue;

      return {
        'tenantId': tenantId,
        'total': total,
        'devFee': devFee,
        'clientShare': clientShare,
        'verified': true,
      };
    }
    return null;
  }
}
