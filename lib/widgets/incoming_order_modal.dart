import 'dart:async';
import 'package:flutter/material.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/models/cart_item.dart';

class IncomingOrderModal extends StatefulWidget {
  final bool visible;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final Order? order;
  final double? fare;

  const IncomingOrderModal({
    super.key,
    required this.visible,
    required this.onAccept,
    required this.onDecline,
    this.order,
    this.fare,
  });

  @override
  State<IncomingOrderModal> createState() => _IncomingOrderModalState();
}

class _IncomingOrderModalState extends State<IncomingOrderModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnim;
  late Animation<double> _progressAnim;
  late Animation<double> _slideAnim;

  int _timeLeft = 15;
  Timer? _timer;

  static const double _slideWidth = 250;
  static const double _buttonWidth = 60;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.linear),
    );

    _slideAnim = Tween<double>(begin: 0, end: _slideWidth - _buttonWidth).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant IncomingOrderModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _startAnimations();
    } else if (!widget.visible && oldWidget.visible) {
      _stopAnimations();
    }
  }

  void _startAnimations() {
    setState(() => _timeLeft = 15);
    _progressController.reset();
    _slideController.reset();
    _pulseController.repeat(reverse: true);
    _progressController.forward();
    _startTimer();
  }

  void _stopAnimations() {
    _pulseController.stop();
    _progressController.stop();
    _slideController.stop();
    _timer?.cancel();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          timer.cancel();
          widget.onDecline();
        }
      });
    });
  }

  void _handleSlideComplete() {
    _slideController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 300), widget.onAccept);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    _slideController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return Stack(
      children: [
        GestureDetector(
          onTap: () {},
          child: Container(color: Colors.black.withValues(alpha: 0.95)),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AnimatedBuilder(
              animation: _progressAnim,
              builder: (context, child) {
                return Container(
                  height: 8,
                  color: const Color(0xFF1F2937),
                  child: FractionallySizedBox(
                    widthFactor: _progressAnim.value,
                    child: Container(
                      color: _timeLeft < 5
                          ? AppColors.error
                          : const Color(0xFF14B8A6),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildContent(),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ],
    );
  }

  Widget _buildContent() {
    final order = widget.order;
    final fare = widget.fare ?? order?.total;
    final businessName = (order?.businessName ?? '').trim();
    final pickUp = businessName.isNotEmpty ? businessName : 'Pick Up';
    final dropOff = (order?.deliveryAddress ?? '').trim().isNotEmpty
        ? order!.deliveryAddress.trim()
        : 'Drop Off';

    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnim.value,
              child: child,
            );
          },
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFF14B8A6).withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF14B8A6)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.5),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_active,
              size: 48,
              color: Color(0xFF14B8A6),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          fare != null ? 'K ${fare.toStringAsFixed(2)}' : 'Incoming delivery',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          order != null ? '#${order.id}' : 'New delivery request',
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 48),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            children: [
              _RoutePoint(label: 'Pick Up', sub: pickUp, color: Colors.white),
              Expanded(
                child: Container(height: 1, color: const Color(0xFF6B7280)),
              ),
              _RoutePoint(
                  label: 'Drop Off', sub: dropOff, color: const Color(0xFF14B8A6)),
            ],
          ),
        ),
        const SizedBox(height: 48),
        _buildSlider(),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: widget.onDecline,
          child: const Text(
            'Decline Request',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        children: [
          const Center(
            child: Text(
              'SLIDE TO ACCEPT',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _slideAnim,
            builder: (context, child) {
              return Positioned(
                left: _slideAnim.value + 4,
                top: 4,
                child: child!,
              );
            },
            child: GestureDetector(
              onTap: _handleSlideComplete,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF14B8A6),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF14B8A6).withValues(alpha: 0.8),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chevron_right,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                '${_timeLeft}s',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePoint extends StatelessWidget {
  final String label;
  final String sub;
  final Color color;

  const _RoutePoint({
    required this.label,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 110),
          child: Text(
            sub,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
