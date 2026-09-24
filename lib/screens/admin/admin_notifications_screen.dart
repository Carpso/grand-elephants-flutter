import 'package:flutter/material.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/services/api_client.dart';
import 'package:grand_elephants/widgets/soft_button.dart';
import 'package:grand_elephants/widgets/soft_card.dart';
import 'package:grand_elephants/widgets/soft_input.dart';
import 'package:grand_elephants/widgets/toast.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _target = 'all';
  bool _loading = true;
  List<Map<String, dynamic>> _auditLogs = [];
  List<Map<String, dynamic>> _lipilaLogs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
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
      if (mounted) {
        setState(() {
          _auditLogs = [];
          _lipilaLogs = [];
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleSend() {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ToastProvider.of(context).show('Please enter both a title and a message body.', ToastType.error);
      return;
    }
    ToastProvider.of(context).show(
      'Push broadcasting is handled server-side. There is no admin push endpoint yet.',
      ToastType.info,
    );
  }

  String _logTitle(Map<String, dynamic> item) {
    final candidates = ['action', 'type', 'message', 'description', 'id'];
    for (final key in candidates) {
      final value = item[key];
      if (value != null && '$value'.isNotEmpty) return '$value';
    }
    return 'Event';
  }

  String _logDetail(Map<String, dynamic> item) {
    final candidates = ['createdAt', 'time', 'phone', 'details', 'amount', 'email'];
    for (final key in candidates) {
      final value = item[key];
      if (value != null && '$value'.isNotEmpty) return '$value';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Push Notifications')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Compose Message',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brandDark),
              ),
              const SizedBox(height: 16),
              SoftCard(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: ['all', 'customers', 'riders'].map((t) {
                          final isSelected = _target == t;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _target = t),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    t[0].toUpperCase() + t.substring(1),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? AppColors.brandDark : AppColors.brandMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SoftInput(
                      label: 'Title',
                      controller: _titleController,
                      hint: 'e.g. Weekend Special',
                      icon: const Icon(Icons.title, size: 20, color: AppColors.brandMuted),
                    ),
                    SoftInput(
                      label: 'Message Body',
                      controller: _bodyController,
                      hint: 'Type your alert message here...',
                      maxLines: 4,
                      icon: const Icon(Icons.message, size: 20, color: AppColors.brandMuted),
                    ),
                    SoftButton(
                      title: 'Send Notification',
                      variant: SoftButtonVariant.primary,
                      icon: const Icon(Icons.send, size: 20, color: AppColors.brandDark),
                      onPressed: _handleSend,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Broadcasts are handled server-side; this screen only shows backend activity.',
                      style: TextStyle(color: AppColors.brandMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Recent Activity',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brandDark),
              ),
              const SizedBox(height: 16),
              if (_loading)
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
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandMuted, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text('Nothing recorded yet.', style: TextStyle(color: AppColors.brandMuted, fontSize: 12)),
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
                            Text(_logTitle(item), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandDark, fontSize: 13)),
                            if (_logDetail(item).isNotEmpty)
                              Text(_logDetail(item), style: const TextStyle(color: AppColors.brandMuted, fontSize: 11)),
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