import 'package:flutter/material.dart';
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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

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
    _emailController.dispose();
    _passwordController.dispose();
    _headerController.dispose();
    _formController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  Future<void> _handleSignup() async {
    if (_isLoading) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty) {
      ToastProvider.of(context).show('Please enter your full name', ToastType.error);
      return;
    }
    if (email.isEmpty) {
      ToastProvider.of(context).show('Please enter your email', ToastType.error);
      return;
    }
    if (!_isValidEmail(email)) {
      ToastProvider.of(context).show('Please enter a valid email address', ToastType.error);
      return;
    }
    if (password.isEmpty) {
      ToastProvider.of(context).show('Please enter a password', ToastType.error);
      return;
    }
    final passwordError = AuthProvider.validatePassword(password);
    if (passwordError != null) {
      ToastProvider.of(context).show(passwordError, ToastType.error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.signUp(name, email, password);
      if (!mounted) return;
      ToastProvider.of(context).show('Account created successfully!', ToastType.success);
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      if (!mounted) return;
      ToastProvider.of(context).show(
        e.toString().replaceFirst('Exception: ', ''),
        ToastType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();

    return Scaffold(
      backgroundColor: AppColors.softSurface,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.softSurface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_back,
                        size: 24,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
                          config.appName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            config.appSlogan,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.brandMuted,
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
                        hint: 'John Doe',
                        controller: _nameController,
                      ),
                      SoftInput(
                        label: 'Email Address',
                        hint: 'john@example.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SoftInput(
                        label: 'Password',
                        hint: 'At least 6 characters',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        icon: GestureDetector(
                          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20,
                              color: AppColors.brandMuted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SoftButton(
                        title: 'Create Account',
                        isLoading: _isLoading,
                        onPressed: _handleSignup,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('/login'),
                      child: const Text(
                        'Log In',
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
