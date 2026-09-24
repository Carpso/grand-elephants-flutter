import 'package:flutter/material.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/services/api_client.dart';

class SystemHealthModal extends StatefulWidget {
  final bool visible;
  final VoidCallback onClose;

  const SystemHealthModal({
    super.key,
    required this.visible,
    required this.onClose,
  });

  @override
  State<SystemHealthModal> createState() => _SystemHealthModalState();
}

class _SystemHealthModalState extends State<SystemHealthModal> {
  final Map<String, String> _statuses = {
    'db': 'checking',
    'api': 'checking',
    'cache': 'checking',
  };
  int _latency = 0;

  @override
  void didUpdateWidget(covariant SystemHealthModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _runHealthCheck();
    }
  }

  void _runHealthCheck() {
    setState(() {
      _statuses['db'] = 'checking';
      _statuses['api'] = 'checking';
      _statuses['cache'] = 'checking';
      _latency = 0;
    });

    final stopwatch = Stopwatch()..start();
    ApiClient.instance.get('/api/health', withAuth: false).then((res) {
      stopwatch.stop();
      if (!mounted) return;
      var db = 'online';
      var api = 'online';
      var cache = 'online';
      if (res is Map<String, dynamic>) {
        db = _deriveStatus(res['db'], db);
        cache = _deriveStatus(res['cache'], cache);
      }
      setState(() {
        _statuses['db'] = db;
        _statuses['api'] = api;
        _statuses['cache'] = cache;
        _latency = stopwatch.elapsedMilliseconds;
      });
    }).catchError((_) {
      stopwatch.stop();
      if (!mounted) return;
      setState(() {
        _statuses['db'] = 'offline';
        _statuses['api'] = 'offline';
        _statuses['cache'] = 'offline';
        _latency = stopwatch.elapsedMilliseconds;
      });
    });
  }

  String _deriveStatus(dynamic value, String fallback) {
    if (value is bool) return value ? 'online' : 'offline';
    if (value is String) {
      final v = value.toLowerCase();
      if (v == 'ok' || v == 'online' || v == 'healthy' || v == 'up') {
        return 'online';
      }
      return 'offline';
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onClose,
          child: Container(color: Colors.black.withValues(alpha: 0.6)),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: 400,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  _buildBody(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1F2937), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'System Diagnostics',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Real-time server monitoring',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _StatusRow(label: 'Main Database (PostgreSQL)', status: _statuses['db']!),
          const SizedBox(height: 12),
          _StatusRow(label: 'API Gateway (REST)', status: _statuses['api']!),
          const SizedBox(height: 12),
          _StatusRow(label: 'Redis Cache Cluster', status: _statuses['cache']!),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.speed, size: 20, color: Color(0xFF4B5563)),
              const SizedBox(width: 8),
              Text.rich(
                TextSpan(
                  text: 'Global Latency: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B7280),
                  ),
                  children: [
                    TextSpan(
                      text: _latency > 0 ? '${_latency}ms' : '--',
                      style: const TextStyle(color: AppColors.brandPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String status;

  const _StatusRow({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final isChecking = status == 'checking';
    final isOnline = status == 'online';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isChecking
                      ? AppColors.warning
                      : isOnline
                          ? AppColors.success
                          : AppColors.error,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          if (isChecking)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.brandPrimary,
              ),
            )
          else
            Row(
              children: [
                Icon(
                  isOnline ? Icons.check_circle : Icons.cancel,
                  size: 20,
                  color: isOnline ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  isOnline ? 'Operational' : 'Offline',
                  style: TextStyle(
                    color: isOnline
                        ? const Color(0xFF15803D)
                        : AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}