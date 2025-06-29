import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_role_model.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/role_guard.dart';
import 'home_screen.dart';
import 'attendance_screen.dart';
import 'dashboard_screen.dart';
import 'request_approval_screen.dart';
import 'admin_panel_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserRoleModel?>(
      stream: _authService.getCurrentUserRoleStream(),
      builder: (context, roleSnapshot) {
        final userRole = roleSnapshot.data;
        final canViewReports = userRole?.canViewReports ?? false;
        final canApproveRequests = userRole?.canApproveRequests ?? false;
        final isHRD = userRole?.canManageUsers ?? false;
        
        final List<Widget> screens = [
          const HomeScreen(),
          const AttendanceScreen(),
          if (canViewReports) const DashboardScreen(),
          if (canApproveRequests) const RequestApprovalScreen(),
          const ProfileScreen(),
          if (isHRD) const AdminPanelScreen(),
        ];

        // Ensure current index doesn't exceed available screens
        if (_currentIndex >= screens.length) {
          _currentIndex = 0;
        }
        
        return Scaffold(
          backgroundColor: AppTheme.white,
          body: screens[_currentIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppTheme.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: _buildDynamicNavigation(
                  canViewReports: canViewReports,
                  canApproveRequests: canApproveRequests,
                  isHRD: isHRD,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDynamicNavigation({
    required bool canViewReports,
    required bool canApproveRequests,
    required bool isHRD,
  }) {
    final List<Map<String, dynamic>> navItems = [
      {
        'icon': Icons.home_outlined,
        'activeIcon': Icons.home,
        'label': 'Home',
        'show': true,
      },
      {
        'icon': Icons.access_time_outlined,
        'activeIcon': Icons.access_time,
        'label': 'Attendance',
        'show': true,
      },
      {
        'icon': Icons.analytics_outlined,
        'activeIcon': Icons.analytics,
        'label': 'Analytics',
        'show': canViewReports,
      },
      {
        'icon': Icons.approval_outlined,
        'activeIcon': Icons.approval,
        'label': 'Approvals',
        'show': canApproveRequests,
      },
      {
        'icon': Icons.person_outline,
        'activeIcon': Icons.person,
        'label': 'Profile',
        'show': true,
      },
      {
        'icon': Icons.admin_panel_settings_outlined,
        'activeIcon': Icons.admin_panel_settings,
        'label': 'Admin',
        'show': isHRD,
      },
    ];

    final visibleItems = navItems.where((item) => item['show'] == true).toList();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: visibleItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        
        return Expanded(
          child: _buildNavItem(
            icon: item['icon'],
            activeIcon: item['activeIcon'],
            label: item['label'],
            index: index,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryDark.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppTheme.primaryDark : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppTheme.primaryDark : AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: const CustomAppBar(
        title: 'Profile',
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
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryDark,
                            AppTheme.primaryBlue,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? user?.email?.split('@')[0] ?? 'User',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'No email',
                            style: AppTheme.bodyText,
                          ),
                          const SizedBox(height: 8),
                          StreamBuilder<UserRoleModel?>(
                            stream: authService.getCurrentUserRoleStream(),
                            builder: (context, snapshot) {
                              final userRole = snapshot.data;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF27AE60).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  userRole?.roleDisplayName ?? 'Staff',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF27AE60),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Account Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryDark,
                ),
              ),
              const SizedBox(height: 20),
              _buildSettingTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Manage notification preferences',
                color: AppTheme.primaryBlue,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications feature coming soon!')),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildSettingTile(
                icon: Icons.security_outlined,
                title: 'Privacy & Security',
                subtitle: 'Manage your privacy settings',
                color: const Color(0xFF9B59B6),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privacy settings coming soon!')),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildSettingTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get help and contact support',
                color: const Color(0xFFE67E22),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help & Support coming soon!')),
                  );
                },
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 40),
              CustomButton(
                text: 'Sign Out',
                onPressed: () async {
                  await authService.signOut();
                },
                isPrimary: false,
                height: 56,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
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
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
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
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTheme.bodyTextSmall,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}