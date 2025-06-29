import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/role_guard.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  Map<String, dynamic>? _attendanceData;
  Map<String, dynamic>? _requestData;
  bool _isLoading = true;
  String _selectedPeriod = 'thisMonth';

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate;

      switch (_selectedPeriod) {
        case 'thisWeek':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          endDate = now;
          break;
        case 'thisMonth':
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 0);
          break;
        case 'lastMonth':
          startDate = DateTime(now.year, now.month - 1, 1);
          endDate = DateTime(now.year, now.month, 0);
          break;
        default:
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 0);
      }

      final attendanceData = await _analyticsService.getAttendanceAnalytics(
        startDate: startDate,
        endDate: endDate,
      );
      final requestData = await _analyticsService.getRequestAnalytics(
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        _attendanceData = attendanceData;
        _requestData = requestData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      permission: 'view_reports',
      child: Scaffold(
        backgroundColor: AppTheme.white,
        appBar: const CustomAppBar(
          title: 'Analytics Dashboard',
          showBackButton: false,
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Period Selector
                        _buildPeriodSelector(),
                        const SizedBox(height: 24),
                        
                        // Quick Stats
                        _buildQuickStats(),
                        const SizedBox(height: 32),
                        
                        // Attendance Analytics
                        _buildAttendanceSection(),
                        const SizedBox(height: 32),
                        
                        // Request Analytics
                        _buildRequestSection(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analytics Period',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPeriodChip('This Week', 'thisWeek'),
              const SizedBox(width: 8),
              _buildPeriodChip('This Month', 'thisMonth'),
              const SizedBox(width: 8),
              _buildPeriodChip('Last Month', 'lastMonth'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = value;
        });
        _loadAnalytics();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppTheme.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final attendance = _attendanceData ?? {};
    final requests = _requestData ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Check-ins',
                value: '${attendance['checkedInToday'] ?? 0}',
                color: const Color(0xFF27AE60),
                icon: Icons.login,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Pending Requests',
                value: '${requests['pendingRequests'] ?? 0}',
                color: const Color(0xFFE67E22),
                icon: Icons.pending_actions,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Late Arrivals',
                value: '${attendance['lateArrivals'] ?? 0}',
                color: const Color(0xFFE74C3C),
                icon: Icons.schedule,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Approval Rate',
                value: '${(requests['approvalRate'] ?? 0.0).toStringAsFixed(1)}%',
                color: AppTheme.primaryBlue,
                icon: Icons.check_circle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
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
        ],
      ),
    );
  }

  Widget _buildAttendanceSection() {
    final data = _attendanceData ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attendance Analytics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 16),
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
              _buildAnalyticsRow(
                'Total Records',
                '${data['totalRecords'] ?? 0}',
                Icons.calendar_today,
                AppTheme.primaryDark,
              ),
              const SizedBox(height: 12),
              _buildAnalyticsRow(
                'Completed Days',
                '${data['completedDays'] ?? 0}',
                Icons.check_circle_outline,
                const Color(0xFF27AE60),
              ),
              const SizedBox(height: 12),
              _buildAnalyticsRow(
                'Average Hours',
                '${(data['averageHours'] ?? 0.0).toStringAsFixed(1)}h',
                Icons.access_time,
                AppTheme.primaryBlue,
              ),
              const SizedBox(height: 12),
              _buildAnalyticsRow(
                'Late Arrivals',
                '${data['lateArrivals'] ?? 0}',
                Icons.warning_outlined,
                const Color(0xFFE74C3C),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequestSection() {
    final data = _requestData ?? {};
    final typeBreakdown = data['typeBreakdown'] as Map<String, dynamic>? ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Request Analytics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 16),
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
              _buildAnalyticsRow(
                'Total Requests',
                '${data['totalRequests'] ?? 0}',
                Icons.list_alt,
                AppTheme.primaryDark,
              ),
              const SizedBox(height: 12),
              _buildAnalyticsRow(
                'Approved',
                '${data['approvedRequests'] ?? 0}',
                Icons.check_circle,
                const Color(0xFF27AE60),
              ),
              const SizedBox(height: 12),
              _buildAnalyticsRow(
                'Rejected',
                '${data['rejectedRequests'] ?? 0}',
                Icons.cancel,
                const Color(0xFFE74C3C),
              ),
              const SizedBox(height: 12),
              _buildAnalyticsRow(
                'Cash Requested',
                '\$${(data['totalCashRequested'] ?? 0.0).toStringAsFixed(2)}',
                Icons.attach_money,
                AppTheme.primaryBlue,
              ),
              if (typeBreakdown.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Request Types',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                ...typeBreakdown.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key.toUpperCase(),
                        style: AppTheme.bodyTextSmall,
                      ),
                      Text(
                        '${entry.value}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTheme.bodyText,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}