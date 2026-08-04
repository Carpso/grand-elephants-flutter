import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/providers/collection_number_provider.dart';
import 'package:sell_on_app/services/lipila_payment_service.dart';
import 'package:sell_on_app/widgets/soft_button.dart';

class MobileMoneyOverlay extends StatefulWidget {
  final bool visible;
  final double amount;
  final String orderReference;
  final VoidCallback onClose;
  final VoidCallback onSuccess;

  const MobileMoneyOverlay({
    super.key,
    required this.visible,
    required this.amount,
    required this.orderReference,
    required this.onClose,
    required this.onSuccess,
  });

  @override
  State<MobileMoneyOverlay> createState() => _MobileMoneyOverlayState();
}

class _MobileMoneyOverlayState extends State<MobileMoneyOverlay> {
  final _phoneController = TextEditingController();
  String _status = 'idle';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant MobileMoneyOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      setState(() {
        _status = 'idle';
        _errorMessage = null;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handlePay() async {
    if (_phoneController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid ZM number.')),
      );
      return;
    }

    setState(() {
      _status = 'pending';
      _errorMessage = null;
    });

    try {
      final lipila = context.read<LipilaPaymentService>();
      final collectionProvider = context.read<CollectionNumberProvider>();
      final collectionNumber = collectionProvider.getDefaultNumber();

      if (collectionNumber == null) {
        setState(() {
          _status = 'idle';
          _errorMessage = 'No collection number configured. Contact support.';
        });
        return;
      }

      final result = await lipila.collectMobileMoney(
        amount: widget.amount,
        customerPhone: _phoneController.text,
        orderReference: widget.orderReference,
        collectionNumber: collectionNumber,
      );

      if (result.success) {
        setState(() => _status = 'success');
        Future.delayed(const Duration(seconds: 1), () {
          widget.onSuccess();
          setState(() {
            _status = 'idle';
            _phoneController.clear();
          });
        });
      } else {
        setState(() {
          _status = 'idle';
          _errorMessage = result.message;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Payment failed')),
        );
      }
    } catch (e) {
      setState(() {
        _status = 'idle';
        _errorMessage = 'Payment error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onClose,
          child: Container(color: Colors.black.withValues(alpha: 0.8)),
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildBody(),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFCD34D), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mobile Money Payment',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: AppColors.brandDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Powered by Lipila Funnel',
                style: TextStyle(
                  color: AppColors.brandDark.withValues(alpha: 0.8),
                  fontSize: 13,
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
              child: const Icon(Icons.close, size: 24, color: Color(0xFF333333)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'K ${widget.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 32),
          if (_status == 'idle') _buildIdleState(),
          if (_status == 'pending') _buildPendingState(),
          if (_status == 'success') _buildSuccessState(),
        ],
      ),
    );
  }

  Widget _buildIdleState() {
    final collectionProvider = context.watch<CollectionNumberProvider>();
    final defaultNumber = collectionProvider.getDefaultNumber();

    return Column(
      children: [
        if (defaultNumber != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.brandPrimary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.business,
                    size: 20, color: AppColors.brandPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paying: ${defaultNumber.businessName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.brandDark,
                        ),
                      ),
                      Text(
                        '${defaultNumber.network.displayName} • ${defaultNumber.phoneNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.brandMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['Airtel', 'MTN', 'Zamtel'].map((n) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                n,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B7280),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Phone Number',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  '+260',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '97 1234567',
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.smartphone, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    size: 16, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        SoftButton(
          title: 'Pay via Lipila',
          variant: SoftButtonVariant.primary,
          onPressed: _handlePay,
          icon: const Icon(Icons.send, size: 20, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildPendingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          CircularProgressIndicator(color: AppColors.brandPrimary),
          SizedBox(height: 16),
          Text(
            'Check your phone...',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.brandDark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "We've sent a payment prompt to your phone via Lipila. Enter your PIN to confirm.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Color(0xFFDCFCE7),
            child: Icon(Icons.check, size: 40, color: Color(0xFF16A34A)),
          ),
          SizedBox(height: 16),
          Text(
            'Payment Successful!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Color(0xFF15803D),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Processed via Lipila Funnel',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.brandMuted,
            ),
          ),
        ],
      ),
    );
  }
}