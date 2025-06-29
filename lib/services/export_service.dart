import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'analytics_service.dart';

class ExportService {
  final AnalyticsService _analyticsService = AnalyticsService();

  // Export attendance data as CSV format
  Future<String> exportAttendanceReport({
    DateTime? startDate,
    DateTime? endDate,
    String format = 'csv',
  }) async {
    try {
      final data = await _analyticsService.getAttendanceAnalytics(
        startDate: startDate,
        endDate: endDate,
      );

      if (format.toLowerCase() == 'csv') {
        return _generateAttendanceCSV(data);
      } else if (format.toLowerCase() == 'json') {
        return _generateAttendanceJSON(data);
      } else {
        throw Exception('Unsupported export format: $format');
      }
    } catch (e) {
      throw Exception('Failed to export attendance report: $e');
    }
  }

  // Export request data as CSV format
  Future<String> exportRequestReport({
    DateTime? startDate,
    DateTime? endDate,
    String format = 'csv',
  }) async {
    try {
      final data = await _analyticsService.getRequestAnalytics(
        startDate: startDate,
        endDate: endDate,
      );

      if (format.toLowerCase() == 'csv') {
        return _generateRequestCSV(data);
      } else if (format.toLowerCase() == 'json') {
        return _generateRequestJSON(data);
      } else {
        throw Exception('Unsupported export format: $format');
      }
    } catch (e) {
      throw Exception('Failed to export request report: $e');
    }
  }

  // Export combined report
  Future<String> exportCombinedReport({
    DateTime? startDate,
    DateTime? endDate,
    String format = 'json',
  }) async {
    try {
      final data = await _analyticsService.generateReport(
        reportType: 'combined',
        startDate: startDate,
        endDate: endDate,
      );

      if (format.toLowerCase() == 'json') {
        return _generateCombinedJSON(data);
      } else {
        throw Exception('Combined reports only support JSON format');
      }
    } catch (e) {
      throw Exception('Failed to export combined report: $e');
    }
  }

  String _generateAttendanceCSV(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Attendance Report');
    buffer.writeln('Period: ${data['period']['start']} to ${data['period']['end']}');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');
    
    // Summary
    buffer.writeln('Summary');
    buffer.writeln('Total Records,${data['totalRecords']}');
    buffer.writeln('Checked In Today,${data['checkedInToday']}');
    buffer.writeln('Late Arrivals,${data['lateArrivals']}');
    buffer.writeln('Completed Days,${data['completedDays']}');
    buffer.writeln('Average Hours,${data['averageHours'].toStringAsFixed(2)}');
    buffer.writeln('');
    
    // User Statistics (if available)
    final userStats = data['userStats'] as Map<String, dynamic>?;
    if (userStats != null && userStats.isNotEmpty) {
      buffer.writeln('User Statistics');
      buffer.writeln('User ID,Total Days,Late Days,Total Hours,Completed Days');
      userStats.forEach((userId, stats) {
        buffer.writeln('$userId,${stats['totalDays']},${stats['lateDays']},${stats['totalHours'].toStringAsFixed(2)},${stats['completedDays']}');
      });
    }
    
    return buffer.toString();
  }

  String _generateRequestCSV(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Request Report');
    buffer.writeln('Period: ${data['period']['start']} to ${data['period']['end']}');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');
    
    // Summary
    buffer.writeln('Summary');
    buffer.writeln('Total Requests,${data['totalRequests']}');
    buffer.writeln('Pending Requests,${data['pendingRequests']}');
    buffer.writeln('Approved Requests,${data['approvedRequests']}');
    buffer.writeln('Rejected Requests,${data['rejectedRequests']}');
    buffer.writeln('Total Cash Requested,\$${data['totalCashRequested'].toStringAsFixed(2)}');
    buffer.writeln('Approval Rate,${data['approvalRate'].toStringAsFixed(1)}%');
    buffer.writeln('');
    
    // Type Breakdown
    final typeBreakdown = data['typeBreakdown'] as Map<String, dynamic>?;
    if (typeBreakdown != null && typeBreakdown.isNotEmpty) {
      buffer.writeln('Request Types');
      buffer.writeln('Type,Count');
      typeBreakdown.forEach((type, count) {
        buffer.writeln('${type.toUpperCase()},$count');
      });
    }
    
    return buffer.toString();
  }

  String _generateAttendanceJSON(Map<String, dynamic> data) {
    final exportData = {
      'reportType': 'attendance',
      'generatedAt': DateTime.now().toIso8601String(),
      'data': data,
    };
    
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  String _generateRequestJSON(Map<String, dynamic> data) {
    final exportData = {
      'reportType': 'requests',
      'generatedAt': DateTime.now().toIso8601String(),
      'data': data,
    };
    
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  String _generateCombinedJSON(Map<String, dynamic> data) {
    final exportData = {
      'reportType': 'combined',
      'generatedAt': DateTime.now().toIso8601String(),
      'data': data,
    };
    
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  // Copy report to clipboard
  Future<void> copyToClipboard(String content) async {
    try {
      await Clipboard.setData(ClipboardData(text: content));
    } catch (e) {
      throw Exception('Failed to copy to clipboard: $e');
    }
  }

  // Share report content directly (without file creation)
  Future<void> downloadAndShareReport({
    required String reportType,
    required String format,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Generate report content
      String content;
      switch (reportType) {
        case 'attendance':
          content = await exportAttendanceReport(
            startDate: startDate,
            endDate: endDate,
            format: format,
          );
          break;
        case 'requests':
          content = await exportRequestReport(
            startDate: startDate,
            endDate: endDate,
            format: format,
          );
          break;
        case 'combined':
          content = await exportCombinedReport(
            startDate: startDate,
            endDate: endDate,
            format: format,
          );
          break;
        default:
          throw Exception('Unknown report type: $reportType');
      }

      // Get filename for subject
      final filename = generateFilename(reportType, format);
      
      // Share content directly as text
      await Share.share(
        content,
        subject: 'Business Operations Report: $filename',
      );
    } catch (e) {
      throw Exception('Failed to share report: $e');
    }
  }

  // Create file using app directory (more reliable)
  Future<File> _saveToAppFile(String content, String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(content);
      return file;
    } catch (e) {
      // Fallback to temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsString(content);
      return file;
    }
  }

  // Save report to app directory (more reliable than external storage)
  Future<File?> saveToAppDirectory({
    required String reportType,
    required String format,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Generate report content
      String content;
      switch (reportType) {
        case 'attendance':
          content = await exportAttendanceReport(
            startDate: startDate,
            endDate: endDate,
            format: format,
          );
          break;
        case 'requests':
          content = await exportRequestReport(
            startDate: startDate,
            endDate: endDate,
            format: format,
          );
          break;
        case 'combined':
          content = await exportCombinedReport(
            startDate: startDate,
            endDate: endDate,
            format: format,
          );
          break;
        default:
          throw Exception('Unknown report type: $reportType');
      }

      // Get filename
      final filename = generateFilename(reportType, format);
      
      try {
        // Try app documents directory first
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsString(content);
        return file;
      } catch (e) {
        // Fallback: use temporary directory if documents directory fails
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$filename');
        await file.writeAsString(content);
        return file;
      }
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }

  // Generate filename for export
  String generateFilename(String reportType, String format) {
    final timestamp = DateTime.now().toIso8601String().split('T')[0];
    return '${reportType}_report_$timestamp.$format';
  }

  // Get supported export formats
  List<String> getSupportedFormats() {
    return ['csv', 'json'];
  }

  // Validate export parameters
  bool validateExportRequest({
    required String reportType,
    required String format,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    // Check format
    if (!getSupportedFormats().contains(format.toLowerCase())) {
      return false;
    }

    // Check report type
    final validTypes = ['attendance', 'requests', 'combined'];
    if (!validTypes.contains(reportType.toLowerCase())) {
      return false;
    }

    // Check date range
    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      return false;
    }

    return true;
  }
}