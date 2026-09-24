import 'package:flutter/material.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/services/api_client.dart';
import 'package:grand_elephants/widgets/soft_card.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _auditLogs = [];
  List<Map<String, dynamic>> _lipilaLogs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiClient.instance.get('/api/admin/actions'),
        ApiClient.instance.get('/api/admin/lipila-logs'),
      ]);
      if (!mounted) return;
      setState(() {
        _auditLogs = (results[0] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _lipilaLogs = (results[1] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _auditLogs = [];
        _lipilaLogs = [];
        _error = '$e'.replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _logTitle(Map<String, dynamic> item) {
    final action = '${item['action'] ?? item['kind'] ?? ''}';
    if (action.isNotEmpty) return action.replaceAll('_', ' ');
    final message = '${item['message'] ?? ''}';
    if (message.isNotEmpty) return message;
    return 'Event';
  }

  String _logDetail(Map<String, dynamic> item) {
    final entity = '${item['entity_type'] ?? ''}';
    final entityId = '${item['entity_id'] ?? ''}';
    final reference = '${item['reference_id'] ?? ''}';
    final amountCents = item['amount_cents'];
    final status = '${item['status'] ?? item['lipila_status'] ?? ''}';
    final time = '${item['created_at'] ?? ''}';
    final parts = <String>[
      if (entity.isNotEmpty) entity + (entityId.isNotEmpty ? ' #$entityId' : ''),
      if (reference.isNotEmpty) reference,
      if (amountCents is num) 'K ${(amountCents / 100).toStringAsFixed(2)}',
      if (status.isNotEmpty) status,
      if (time.isNotEmpty) time,
    ];
    return parts.join('  ·  ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity & Alerts')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Backend Activity',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brandDark),
              ),
              const SizedBox(height: 4),
              const Text(
                'Audit and mobile-money events written by the server as it happens.',
                style: TextStyle(color: AppColors.brandMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                SoftCard(
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off, color: AppColors.error, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.brandDark, fontSize: 13),
                        ),
                      ),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              else if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                _buildLogSection('AUDIT LOG (${_auditLogs.length})', _auditLogs, Icons.admin_panel_settings),
                const SizedBox(height: 24),
                _buildLogSection('LIPILA LOGS (${_lipilaLogs.length})', _lipilaLogs, Icons.swap_horiz),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogSection(String title, List<Map<String, dynamic>> items, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.brandMuted,
                fontSize: 10,
                letterSpacing: 1)),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text('Nothing recorded yet.',
                  style: TextStyle(color: AppColors.brandMuted, fontSize: 12)),
            ),
          )
        else
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SoftCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.softSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 18, color: AppColors.brandPrimary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_logTitle(item),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.brandDark,
                                    fontSize: 13)),
                            if (_logDetail(item).isNotEmpty)
                              Text(_logDetail(item),
                                  style: const TextStyle(
                                      color: AppColors.brandMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}
