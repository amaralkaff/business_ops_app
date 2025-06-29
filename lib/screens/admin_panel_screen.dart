import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/analytics_service.dart';
import '../services/export_service.dart';
import '../services/insights_service.dart';
import '../models/user_role_model.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/role_guard.dart';
import 'user_management_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final ExportService _exportService = ExportService();
  final InsightsService _insightsService = InsightsService();
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoadingRecommendations = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoadingRecommendations = true;
    });

    try {
      final recommendations = await _insightsService.getOperationalRecommendations();
      setState(() {
        _recommendations = recommendations;
        _isLoadingRecommendations = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRecommendations = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading recommendations: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showExportOptions(String reportType, String format) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Export ${reportType.toUpperCase()} Report',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 20),
            _buildExportOption(
              icon: Icons.share,
              title: 'Share Report',
              subtitle: 'Share report content via apps',
              onTap: () {
                Navigator.pop(context);
                _downloadAndShareReport(reportType, format);
              },
            ),
            const SizedBox(height: 12),
            _buildExportOption(
              icon: Icons.content_copy,
              title: 'Copy to Clipboard',
              subtitle: 'Copy report content for pasting',
              onTap: () {
                Navigator.pop(context);
                _copyToClipboard(reportType, format);
              },
            ),
            const SizedBox(height: 12),
            _buildExportOption(
              icon: Icons.download,
              title: 'Save to Device',
              subtitle: 'Save file to app folder',
              onTap: () {
                Navigator.pop(context);
                _saveToDevice(reportType, format);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: AppTheme.primaryBlue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTheme.bodyTextSmall,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadAndShareReport(String reportType, String format) async {
    try {
      await _exportService.downloadAndShareReport(
        reportType: reportType,
        format: format,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${reportType.toUpperCase()} report shared successfully'),
            backgroundColor: const Color(0xFF27AE60),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyToClipboard(String reportType, String format) async {
    try {
      String content;
      
      switch (reportType) {
        case 'attendance':
          content = await _exportService.exportAttendanceReport(format: format);
          break;
        case 'requests':
          content = await _exportService.exportRequestReport(format: format);
          break;
        case 'combined':
          content = await _exportService.exportCombinedReport(format: format);
          break;
        default:
          throw Exception('Unknown report type: $reportType');
      }

      await _exportService.copyToClipboard(content);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${reportType.toUpperCase()} report copied to clipboard'),
            backgroundColor: const Color(0xFF27AE60),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copy failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveToDevice(String reportType, String format) async {
    try {
      final file = await _exportService.saveToAppDirectory(
        reportType: reportType,
        format: format,
      );
      
      if (mounted) {
        if (file != null) {
          final filename = file.path.split('/').last;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${reportType.toUpperCase()} report saved as $filename'),
              backgroundColor: const Color(0xFF27AE60),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Share',
                textColor: Colors.white,
                onPressed: () async {
                  await Share.shareXFiles([XFile(file.path)]);
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save file'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: [UserRole.hrd],
      child: Scaffold(
        backgroundColor: AppTheme.white,
        appBar: const CustomAppBar(
          title: 'System Administration',
          showBackButton: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Admin Actions
                _buildQuickActions(),
                const SizedBox(height: 32),
                
                // Export Tools
                _buildExportSection(),
                const SizedBox(height: 32),
                
                // System Recommendations
                _buildRecommendationsSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionListItem(
          icon: Icons.people_outline,
          title: 'User Management',
          subtitle: 'Manage user roles and permissions',
          color: AppTheme.primaryBlue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UserManagementScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionListItem(
          icon: Icons.insights_outlined,
          title: 'Generate Insights',
          subtitle: 'Refresh operational recommendations',
          color: const Color(0xFF9B59B6),
          onTap: _loadRecommendations,
        ),
        const SizedBox(height: 12),
        _buildActionListItem(
          icon: Icons.security_outlined,
          title: 'Security Review',
          subtitle: 'Review access logs and permissions',
          color: const Color(0xFFE74C3C),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Security review feature coming soon'),
                backgroundColor: AppTheme.primaryBlue,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildExportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data Export',
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
              const Text(
                'Export Reports',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryDark,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Generate and export system reports for analysis',
                style: AppTheme.bodyTextSmall,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildExportButton(
                      'Attendance',
                      'attendance',
                      Icons.access_time,
                      const Color(0xFF27AE60),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildExportButton(
                      'Requests',
                      'requests',
                      Icons.list_alt,
                      AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildExportButton(
                      'Combined',
                      'combined',
                      Icons.summarize,
                      const Color(0xFF9B59B6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExportButton(String label, String reportType, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildFormatButton('CSV', reportType, 'csv'),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildFormatButton('JSON', reportType, 'json'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormatButton(String format, String reportType, String formatType) {
    return GestureDetector(
      onTap: () => _showExportOptions(reportType, formatType),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.textSecondary.withValues(alpha: 0.3)),
        ),
        child: Text(
          format,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'System Recommendations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryDark,
              ),
            ),
            if (_isLoadingRecommendations)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_recommendations.isEmpty && !_isLoadingRecommendations)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: const Color(0xFF27AE60),
                ),
                const SizedBox(height: 12),
                const Text(
                  'All Systems Optimal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'No critical recommendations at this time',
                  style: AppTheme.bodyTextSmall,
                ),
              ],
            ),
          )
        else
          ...(_recommendations.map((recommendation) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRecommendationCard(recommendation),
          )).toList()),
      ],
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    Color priorityColor;
    IconData priorityIcon;
    
    switch (recommendation['priority']) {
      case 'high':
        priorityColor = const Color(0xFFE74C3C);
        priorityIcon = Icons.priority_high;
        break;
      case 'medium':
        priorityColor = const Color(0xFFE67E22);
        priorityIcon = Icons.warning_outlined;
        break;
      default:
        priorityColor = AppTheme.primaryBlue;
        priorityIcon = Icons.info_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(priorityIcon, size: 16, color: priorityColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recommendation['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  recommendation['priority']?.toUpperCase() ?? '',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: priorityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation['description'] ?? '',
            style: AppTheme.bodyTextSmall,
          ),
          if (recommendation['metric'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                recommendation['metric'],
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryDark,
                ),
              ),
            ),
          ],
        ],
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
                    color: color.withValues(alpha: 0.1),
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
}