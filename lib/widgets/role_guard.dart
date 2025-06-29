import 'package:flutter/material.dart';
import '../models/user_role_model.dart';
import '../services/auth_service.dart';
import '../widgets/app_theme.dart';

class RoleGuard extends StatelessWidget {
  final Widget child;
  final List<UserRole>? allowedRoles;
  final String? permission;
  final Widget? fallback;

  const RoleGuard({
    super.key,
    required this.child,
    this.allowedRoles,
    this.permission,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder<UserRoleModel?>(
      stream: authService.getCurrentUserRoleStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            ),
          );
        }

        final userRole = snapshot.data;
        bool hasAccess = false;

        if (userRole != null) {
          // Check by specific roles
          if (allowedRoles != null) {
            hasAccess = allowedRoles!.contains(userRole.role);
          }
          // Check by permission
          else if (permission != null) {
            switch (permission!) {
              case 'approve_requests':
                hasAccess = userRole.canApproveRequests;
                break;
              case 'manage_users':
                hasAccess = userRole.canManageUsers;
                break;
              case 'view_reports':
                hasAccess = userRole.canViewReports;
                break;
              case 'submit_requests':
                hasAccess = true; // All users can submit requests
                break;
              default:
                hasAccess = false;
            }
          }
        }

        if (hasAccess) {
          return child;
        }

        return fallback ?? _buildAccessDenied();
      },
    );
  }

  Widget _buildAccessDenied() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 48,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Access Denied',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You don\'t have permission to access this feature',
            style: AppTheme.bodyText,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}