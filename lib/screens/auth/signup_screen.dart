import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/providers/auth_provider.dart';
import 'package:sell_on_app/providers/config_provider.dart';
import 'package:sell_on_app/utils/spring_curve.dart';
import 'package:sell_on_app/widgets/logo.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_input.dart';
import 'package:sell_on_app/widgets/toast.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;
  int _resendIn = 0;

  late final AnimationController _headerController;
  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerOffset;

  late final AnimationController _formController;
  late final Animation<double> _formOpacity;
  late final Animation<double> _formScale;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _headerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeInOut),
    );
    _headerOffset = Tween<Offset>(
      begin: const Offset(0, -0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerController, curve: Curves.easeInOut));
    _headerController.forward();

    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _formOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeInOut),
    );
    _formScale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _formController,
        curve: const SpringCurve(),
      ),
    );
    Future.delayed(const Duration(milliseconds: 200), _formController.forward);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _headerController.dispose();
    _formController.dispose();
    super.dispose();
  }

  String get _normalizedPhone {
    final digits = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) return digits;
    if (digits.startsWith('260') && digits.length == 12) return digits;
    return '0$digits';
  }

  Future<void> _handleSendCode() async {
    if (_isLoading) return;
    final phone = _normalizedPhone;
    if (phone.length < 10) {
      ToastProvider.of(context).show('Enter a valid Zambian phone number', ToastType.error);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().requestOtp(phone);
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _resendIn = 60;
      });
      _tickResend();
      ToastProvider.of(context).show('Verification code sent to $phone', ToastType.success);
    } catch (e) {
      if (!mounted) return;
      ToastProvider.of(context).show('$e'.replaceFirst('Exception: ', ''), ToastType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _tickResend() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_resendIn > 0) {
        setState(() => _resendIn--);
        _tickResend();
      }
    });
  }

  Future<void> _handleVerify() async {
    if (_isLoading) return;
    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    if (name.isEmpty) {
      ToastProvider.of(context).show('Please enter your full name', ToastType.error);
      return;
    }
    if (code.length != 6) {
      ToastProvider.of(context).show('Enter the 6-digit verification code', ToastType.error);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.verifyOtp(_normalizedPhone, code, name: name);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ToastProvider.of(context).show('Welcome, $name!', ToastType.success);
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      if (!mounted) return;
      ToastProvider.of(context).show('$e'.replaceFirst('Exception: ', ''), ToastType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.softSurface,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 32,
              vertical: screenSize.height * 0.06,
            ),
            child: Column(
              children: [
                FadeTransition(
                  opacity: _headerOpacity,
                  child: SlideTransition(
                    position: _headerOffset,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: config.appLogo.isNotEmpty
                              ? Image.network(
                                  config.appLogo,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.contain,
                                )
                              : const Logo(size: 100),
                        ),
                        Text(
                          'Create Account',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandDark,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Verify your mobile number to get started',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.brandMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                AnimatedBuilder(
                  animation: _formController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _formOpacity.value,
                      child: Transform.scale(
                        scale: _formScale.value,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      SoftInput(
                        label: 'Full Name',
                        hint: 'e.g. John Banda',
                        controller: _nameController,
                        enabled: !_otpSent,
                      ),
                      const SizedBox(height: 16),
                      SoftInput(
                        label: 'Mobile Number',
                        hint: '097xxxxxxx',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        enabled: !_otpSent,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                      ),
                      if (_otpSent) ...[
                        const SizedBox(height: 16),
                        SoftInput(
                          label: 'Verification Code',
                          hint: '6-digit code from SMS',
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: _resendIn > 0 ? null : _handleSendCode,
                            child: Text(
                              _resendIn > 0 ? 'Resend in ${_resendIn}s' : 'Resend code',
                              style: TextStyle(
                                color: _resendIn > 0
                                    ? AppColors.brandMuted
                                    : AppColors.brandPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      SoftButton(
                        title: _otpSent ? 'Verify & Create Account' : 'Send Code',
                        isLoading: _isLoading,
                        onPressed: _otpSent ? _handleVerify : _handleSendCode,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushReplacementNamed('/login'),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
