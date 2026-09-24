import 'package:flutter/material.dart';
import 'package:grand_elephants/constants/app_theme.dart';

enum ToastType { success, error, info }

class ToastMessage {
  final String message;
  final ToastType type;
  final int id;

  ToastMessage({required this.message, required this.type, required this.id});
}

class ToastProvider extends StatefulWidget {
  final Widget child;

  const ToastProvider({super.key, required this.child});

  @override
  State<ToastProvider> createState() => _ToastProviderState();

  static ToastContext of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<_InheritedToast>();
    if (result != null) return result.toastContext;
    // No ToastProvider mounted in this subtree yet: fall back to the app's
    // ScaffoldMessenger so showing a message never throws.
    return ToastContext(
      (message, [type = ToastType.info]) =>
          _showViaMessenger(context, message, type),
    );
  }

  static void _showViaMessenger(BuildContext context, String message, ToastType type) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      debugPrint('toast: $message');
      return;
    }
    final background = switch (type) {
      ToastType.success => AppColors.success,
      ToastType.error => AppColors.error,
      ToastType.info => AppColors.brandDark,
    };
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2500),
      ),
    );
  }
}

typedef ToastShowCallback = void Function(String message, [ToastType type]);

class ToastContext {
  final ToastShowCallback show;
  ToastContext(this.show);
}

class _InheritedToast extends InheritedWidget {
  final ToastContext toastContext;

  const _InheritedToast({
    required this.toastContext,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant _InheritedToast oldWidget) => false;
}

class _ToastProviderState extends State<ToastProvider> with SingleTickerProviderStateMixin {
  ToastMessage? _toast;
  late AnimationController _animController;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _opacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void show(String message, [ToastType type = ToastType.info]) {
    setState(() {
      _toast = ToastMessage(message: message, type: type, id: DateTime.now().millisecondsSinceEpoch);
    });
    _animController.forward();
    Future.delayed(const Duration(milliseconds: 2500), () {
      _animController.reverse().then((_) {
        if (mounted) setState(() => _toast = null);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedToast(
      toastContext: ToastContext(show),
      child: Stack(
        children: [
          widget.child,
          if (_toast != null)
            Positioned(
              top: 64,
              left: 16,
              right: 16,
              child: FadeTransition(
                opacity: _opacityAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: _buildToast(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToast() {
    final bgColor = switch (_toast!.type) {
      ToastType.success => AppColors.success,
      ToastType.error => AppColors.error,
      ToastType.info => AppColors.brandDark,
    };
    final icon = switch (_toast!.type) {
      ToastType.success => Icons.check_circle,
      ToastType.error => Icons.error,
      ToastType.info => Icons.info,
    };

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _toast!.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
