import 'package:flutter/material.dart';
import '../models/user_role_model.dart';
import '../services/role_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/role_guard.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final RoleService _roleService = RoleService();
  List<UserRoleModel> _users = [];
  List<UserRoleModel> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  UserRole? _filterRole;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _roleService.getAllUsers();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers = _users.where((user) {
        final matchesSearch = user.email
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()) ||
            (user.displayName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        
        final matchesRole = _filterRole == null || user.role == _filterRole;
        
        return matchesSearch && matchesRole;
      }).toList();
    });
  }

  Future<void> _updateUserRole(UserRoleModel user, UserRole newRole) async {
    try {
      await _roleService.updateUserRole(
        userId: user.userId,
        newRole: newRole,
      );

      setState(() {
        final index = _users.indexWhere((u) => u.userId == user.userId);
        if (index != -1) {
          _users[index] = UserRoleModel(
            userId: user.userId,
            role: newRole,
            email: user.email,
            displayName: user.displayName,
            createdAt: user.createdAt,
            updatedAt: DateTime.now(),
          );
        }
      });

      _filterUsers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role updated to ${newRole.toString().split('.').last}'),
            backgroundColor: const Color(0xFF27AE60),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      permission: 'manage_users',
      child: Scaffold(
        backgroundColor: AppTheme.white,
        appBar: const CustomAppBar(title: 'User Management'),
        body: SafeArea(
          child: Column(
            children: [
              // Search and Filter Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundGray,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search users...',
                          prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        onChanged: (value) {
                          _searchQuery = value;
                          _filterUsers();
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Role Filter
                    Row(
                      children: [
                        const Text(
                          'Filter by role:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<UserRole?>(
                              value: _filterRole,
                              isExpanded: true,
                              underline: const SizedBox(),
                              hint: const Text('All roles'),
                              items: [
                                const DropdownMenuItem<UserRole?>(
                                  value: null,
                                  child: Text('All roles'),
                                ),
                                ...UserRole.values.map((role) {
                                  return DropdownMenuItem<UserRole?>(
                                    value: role,
                                    child: Text(role.toString().split('.').last),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _filterRole = value;
                                });
                                _filterUsers();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Users List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                        ),
                      )
                    : _filteredUsers.isEmpty
                        ? Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              margin: const EdgeInsets.all(24),
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
                                      color: AppTheme.textSecondary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.people_outline,
                                      size: 48,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No users found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryDark,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Try adjusting your search or filter',
                                    style: AppTheme.bodyText,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadUsers,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(24),
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = _filteredUsers[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildUserCard(user),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(UserRoleModel user) {
    return Container(
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryDark,
                      AppTheme.primaryBlue,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    user.email.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? user.email.split('@')[0],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: AppTheme.bodyTextSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Role:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<UserRole>(
                    value: user.role,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: UserRole.values.map((role) {
                      return DropdownMenuItem<UserRole>(
                        value: role,
                        child: Text(role.toString().split('.').last),
                      );
                    }).toList(),
                    onChanged: (newRole) {
                      if (newRole != null && newRole != user.role) {
                        _showRoleChangeConfirmation(user, newRole);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRoleChangeConfirmation(UserRoleModel user, UserRole newRole) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Role Change'),
          content: Text(
            'Change ${user.displayName ?? user.email}\'s role from ${user.roleDisplayName} to ${newRole.toString().split('.').last}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateUserRole(user, newRole);
              },
              style: AppTheme.getPrimaryButtonStyle(),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}