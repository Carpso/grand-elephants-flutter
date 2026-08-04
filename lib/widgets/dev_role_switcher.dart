import 'package:flutter/material.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/models/user.dart';

class DevRoleSwitcher extends StatefulWidget {
  final UserRole currentRole;
  final ValueChanged<UserRole>? onRoleChanged;

  const DevRoleSwitcher({
    super.key,
    required this.currentRole,
    this.onRoleChanged,
  });

  @override
  State<DevRoleSwitcher> createState() => _DevRoleSwitcherState();
}

class _DevRoleSwitcherState extends State<DevRoleSwitcher> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    if (widget.currentRole != UserRole.superadmin) return const SizedBox.shrink();

    final roles = UserRole.values;

    return Stack(
      children: [
        Positioned(
          bottom: 96,
          right: 24,
          child: GestureDetector(
            onTap: () => setState(() => _isOpen = !_isOpen),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brandDark.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.brandPrimary, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                size: 24,
                color: AppColors.warning,
              ),
            ),
          ),
        ),
        if (_isOpen)
          Positioned(
            bottom: 160,
            right: 24,
            child: Container(
              width: 128,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: roles.map((role) {
                  final isSelected = widget.currentRole == role;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: GestureDetector(
                      onTap: () {
                        widget.onRoleChanged?.call(role);
                        setState(() => _isOpen = false);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.brandPrimary : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            role.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isSelected ? Colors.white : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}
