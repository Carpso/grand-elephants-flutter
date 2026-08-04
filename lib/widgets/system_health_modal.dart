import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sell_on_app/constants/app_theme.dart';

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
      _resetAndSimulate();
    }
  }

  void _resetAndSimulate() {
    setState(() {
      _statuses['db'] = 'checking';
      _statuses['api'] = 'checking';
      _statuses['cache'] = 'checking';
      _latency = 0;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _statuses['db'] = 'online');
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _statuses['api'] = 'online');
    });
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() {
          _statuses['cache'] = 'online';
          _latency = Random().nextInt(50) + 10;
        });
      }
    });
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
          if (_latency > 0) ...[
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
                        text: '${_latency}ms',
                        style: const TextStyle(color: AppColors.brandPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
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
                  color: isChecking ? AppColors.warning : AppColors.success,
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
            const Row(
              children: [
                Icon(Icons.check_circle, size: 20, color: AppColors.success),
                SizedBox(width: 4),
                Text(
                  'Operational',
                  style: TextStyle(
                    color: Color(0xFF15803D),
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
