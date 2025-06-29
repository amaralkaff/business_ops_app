import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';
import '../services/role_service.dart';
import '../models/attendance_model.dart';
import '../models/request_model.dart';
import '../models/user_role_model.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'request_screen.dart';
import 'requests_list_screen.dart';
import 'request_approval_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final AttendanceService attendanceService = AttendanceService();
    final RoleService roleService = RoleService();
    final User? user = authService.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: const CustomAppBar(
        title: 'Business Operations',
        showBackButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 24,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome Back!',
                              style: AppTheme.headingMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email?.split('@')[0] ?? 'User',
                              style: AppTheme.bodyText,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundGray,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              user?.email ?? 'No email',
                              style: AppTheme.bodyTextSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              StreamBuilder<AttendanceModel?>(
                stream: attendanceService.getTodayAttendanceStream(),
                builder: (context, snapshot) {
                  final attendance = snapshot.data;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundGray,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryDark.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.access_time,
                                size: 20,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Today\'s Attendance',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildAttendanceInfo(
                              'Check In',
                              attendance?.formattedCheckInTime ?? '--:--',
                              attendance?.isLate == true ? Colors.red : const Color(0xFF27AE60),
                              attendance?.isLate == true ? Icons.warning : Icons.check_circle,
                            ),
                            _buildAttendanceInfo(
                              'Check Out',
                              attendance?.formattedCheckOutTime ?? '--:--',
                              AppTheme.primaryBlue,
                              Icons.logout,
                            ),
                            _buildAttendanceInfo(
                              'Hours',
                              attendance?.formattedTotalHours ?? '0.0',
                              const Color(0xFF9B59B6),
                              Icons.schedule,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryDark,
                ),
              ),
              const SizedBox(height: 20),
              FutureBuilder<UserRoleModel?>(
                future: user != null ? roleService.getUserRole(user.uid) : null,
                builder: (context, roleSnapshot) {
                  final userRole = roleSnapshot.data;
                  final canApprove = userRole?.canApproveRequests ?? false;
                  final canViewReports = userRole?.canViewReports ?? false;
                  
                  return Column(
                    children: [
                      _buildActionListItem(
                        icon: Icons.shopping_cart_outlined,
                        title: 'Goods Request',
                        subtitle: 'Request equipment and supplies',
                        color: const Color(0xFF27AE60),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RequestScreen(
                                requestType: RequestType.goods,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildActionListItem(
                        icon: Icons.attach_money,
                        title: 'Cash Request',
                        subtitle: 'Request operational funds',
                        color: AppTheme.primaryBlue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RequestScreen(
                                requestType: RequestType.cash,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildActionListItem(
                        icon: Icons.time_to_leave_outlined,
                        title: 'Leave Request',
                        subtitle: 'Request time off and vacation',
                        color: const Color(0xFF9B59B6),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RequestScreen(
                                requestType: RequestType.leave,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildActionListItem(
                        icon: Icons.list_alt_outlined,
                        title: 'My Requests',
                        subtitle: 'View request history and status',
                        color: const Color(0xFFE67E22),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RequestsListScreen(),
                            ),
                          );
                        },
                      ),
                      if (canViewReports) ...[
                        const SizedBox(height: 12),
                        _buildActionListItem(
                          icon: Icons.analytics_outlined,
                          title: 'Analytics Dashboard',
                          subtitle: 'View reports and analytics',
                          color: const Color(0xFF9B59B6),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DashboardScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                      if (canApprove) ...[
                        const SizedBox(height: 12),
                        _buildActionListItem(
                          icon: Icons.approval_outlined,
                          title: 'Approve Requests',
                          subtitle: 'Review and approve pending requests',
                          color: const Color(0xFFE74C3C),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RequestApprovalScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionListItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTheme.bodyTextSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceInfo(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}