import 'package:flutter/material.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/services/api_client.dart';
import 'package:grand_elephants/widgets/soft_button.dart';
import 'package:grand_elephants/widgets/soft_card.dart';
import 'package:grand_elephants/widgets/toast.dart';

/// Admin approval queue for business applications.
///
/// `GET  /api/admin/businesses`
/// `POST /api/admin/businesses/:id/status` with `{status: pending|approved|suspended}`
class BusinessesScreen extends StatefulWidget {
  const BusinessesScreen({super.key});

  @override
  State<BusinessesScreen> createState() => _BusinessesScreenState();
}

class _BusinessesScreenState extends State<BusinessesScreen> {
  List<Map<String, dynamic>> _businesses = [];
  bool _loading = true;
  String? _error;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load(showErrors: false);
  }

  List<Map<String, dynamic>> _extract(dynamic res) {
    if (res is List) {
      return res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (res is Map) {
      for (final key in ['businesses', 'data', 'items']) {
        final value = res[key];
        if (value is List) {
          return value.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    }
    return const [];
  }

  Future<void> _load({bool showErrors = true}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.get('/api/admin/businesses');
      if (!mounted) return;
      setState(() => _businesses = _extract(res));
    } catch (e) {
      if (!mounted) return;
      final message = '$e'.replaceFirst('Exception: ', '');
      setState(() => _error = message);
      if (showErrors) {
        ToastProvider.of(context).show(message, ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setStatus(Map<String, dynamic> business, String status) async {
    final id = '${business['id'] ?? business['_id'] ?? ''}';
    if (id.isEmpty) {
      ToastProvider.of(context).show('Business id missing from payload', ToastType.error);
      return;
    }
    final name = '${business['name'] ?? 'Business'}';
    setState(() => _busyId = id);
    try {
      final res = await ApiClient.instance
          .post('/api/admin/businesses/$id/status', body: {'status': status});
      if (!mounted) return;
      final message = res is Map && res['message'] is String
          ? res['message'] as String
          : '$name ${_statusVerb(status)}';
      ToastProvider.of(context).show(message, ToastType.success);
      await _load(showErrors: false);
    } catch (e) {
      if (!mounted) return;
      ToastProvider.of(context)
          .show('$e'.replaceFirst('Exception: ', ''), ToastType.error);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  String _statusVerb(String status) => switch (status) {
        'approved' => 'approved',
        'suspended' => 'suspended',
        _ => 'moved back to review',
      };

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'suspended':
        return AppColors.error;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _businesses
        .where((b) => '${b['status'] ?? 'pending'}' == 'pending')
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Business Applications')),
      body: RefreshIndicator(
        onRefresh: () => _load(),
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: CircularProgressIndicator(color: AppColors.brandPrimary),
                  ),
                ],
              )
            : _error != null && _businesses.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 100),
                      const Icon(Icons.error_outline,
                          size: 56, color: AppColors.brandMuted),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.brandMuted),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => _load(),
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                  )
                : _businesses.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          Icon(Icons.storefront, size: 56, color: AppColors.brandMuted),
                          SizedBox(height: 12),
                          Text(
                            'No business applications yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.brandMuted),
                          ),
                        ],
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              '$pending awaiting approval',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.brandDark,
                              ),
                            ),
                          ),
                          ..._businesses.map(_buildCard),
                        ],
                      ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> business) {
    final id = '${business['id'] ?? business['_id'] ?? ''}';
    final name = '${business['name'] ?? 'Untitled business'}';
    final slogan = '${business['slogan'] ?? ''}';
    final description = '${business['description'] ?? ''}';
    final owner = '${business['ownerName'] ?? ''}';
    final phone = '${business['phone'] ?? business['ownerPhone'] ?? ''}';
    final address = '${business['address'] ?? ''}';
    final status = '${business['status'] ?? 'pending'}';
    final busy = _busyId == id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.softSurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront,
                      color: AppColors.brandPrimary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.brandDark,
                        ),
                      ),
                      if (slogan.isNotEmpty)
                        Text(
                          slogan,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.brandMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _statusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (owner.isNotEmpty || phone.isNotEmpty || address.isNotEmpty)
              Text(
                [
                  if (owner.isNotEmpty) owner,
                  if (phone.isNotEmpty) phone,
                  if (address.isNotEmpty) address,
                ].join(' • '),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.brandMuted),
              ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.brandMuted,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy
                        ? null
                        : () => _setStatus(
                            business,
                            status == 'suspended' ? 'pending' : 'suspended',
                          ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: status == 'suspended'
                          ? AppColors.brandSecondary
                          : AppColors.error,
                      side: BorderSide(
                          color: status == 'suspended'
                              ? AppColors.brandSecondary
                              : AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      status == 'suspended' ? 'Set Pending' : 'Decline',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (status != 'approved') ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: SoftButton(
                      title: busy ? 'Working...' : 'Approve',
                      variant: SoftButtonVariant.primary,
                      onPressed:
                          !busy ? () => _setStatus(business, 'approved') : null,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
