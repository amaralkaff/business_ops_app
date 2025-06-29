import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/attendance_model.dart';
import '../models/request_model.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // Attendance Analytics
  Future<Map<String, dynamic>> getAttendanceAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final start = startDate ?? DateTime(now.year, now.month, 1);
      final end = endDate ?? DateTime(now.year, now.month + 1, 0);

      final snapshot = await _firestore
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final attendanceRecords = snapshot.docs
          .map((doc) => AttendanceModel.fromFirestore(doc))
          .toList();

      // Calculate metrics
      final totalRecords = attendanceRecords.length;
      final checkedInToday = attendanceRecords
          .where((record) => record.checkInTime != null)
          .length;
      final lateArrivals = attendanceRecords
          .where((record) => record.isLate)
          .length;
      final completedDays = attendanceRecords
          .where((record) => record.checkOutTime != null)
          .length;

      // Calculate average hours
      final totalHours = attendanceRecords
          .where((record) => record.totalHours != null)
          .fold<double>(0.0, (sum, record) => sum + (record.totalHours ?? 0.0));
      final averageHours = completedDays > 0 ? totalHours / completedDays : 0.0;

      // Group by users for team overview
      final userStats = <String, Map<String, dynamic>>{};
      for (final record in attendanceRecords) {
        if (!userStats.containsKey(record.userId)) {
          userStats[record.userId] = {
            'totalDays': 0,
            'lateDays': 0,
            'totalHours': 0.0,
            'completedDays': 0,
          };
        }
        userStats[record.userId]!['totalDays']++;
        if (record.isLate) userStats[record.userId]!['lateDays']++;
        if (record.totalHours != null) {
          userStats[record.userId]!['totalHours'] += record.totalHours!;
          userStats[record.userId]!['completedDays']++;
        }
      }

      return {
        'totalRecords': totalRecords,
        'checkedInToday': checkedInToday,
        'lateArrivals': lateArrivals,
        'completedDays': completedDays,
        'averageHours': averageHours,
        'userStats': userStats,
        'period': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      };
    } catch (e) {
      throw Exception('Failed to get attendance analytics: $e');
    }
  }

  // Request Analytics
  Future<Map<String, dynamic>> getRequestAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final start = startDate ?? DateTime(now.year, now.month, 1);
      final end = endDate ?? DateTime(now.year, now.month + 1, 0);

      final snapshot = await _firestore
          .collection('requests')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final requests = snapshot.docs
          .map((doc) => RequestModel.fromFirestore(doc))
          .toList();

      // Calculate metrics
      final totalRequests = requests.length;
      final pendingRequests = requests
          .where((request) => request.status == RequestStatus.pending)
          .length;
      final approvedRequests = requests
          .where((request) => request.status == RequestStatus.approved)
          .length;
      final rejectedRequests = requests
          .where((request) => request.status == RequestStatus.rejected)
          .length;

      // Group by type
      final typeBreakdown = <String, int>{};
      for (final request in requests) {
        final type = request.type.toString().split('.').last;
        typeBreakdown[type] = (typeBreakdown[type] ?? 0) + 1;
      }

      // Calculate total cash requested
      final totalCashRequested = requests
          .where((request) => request.type == RequestType.cash && request.amount != null)
          .fold<double>(0.0, (sum, request) => sum + (request.amount ?? 0.0));

      // Calculate approval rate
      final processedRequests = approvedRequests + rejectedRequests;
      final approvalRate = processedRequests > 0 
          ? (approvedRequests / processedRequests * 100) 
          : 0.0;

      return {
        'totalRequests': totalRequests,
        'pendingRequests': pendingRequests,
        'approvedRequests': approvedRequests,
        'rejectedRequests': rejectedRequests,
        'typeBreakdown': typeBreakdown,
        'totalCashRequested': totalCashRequested,
        'approvalRate': approvalRate,
        'period': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      };
    } catch (e) {
      throw Exception('Failed to get request analytics: $e');
    }
  }

  // Real-time dashboard metrics
  Stream<Map<String, dynamic>> getDashboardMetricsStream() {
    return Stream.periodic(const Duration(minutes: 5), (_) async {
      try {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final thisMonth = DateTime(now.year, now.month, 1);

        // Get today's attendance
        final todayAttendance = await _firestore
            .collection('attendance')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
            .where('date', isLessThan: Timestamp.fromDate(today.add(const Duration(days: 1))))
            .get();

        // Get pending requests
        final pendingRequests = await _firestore
            .collection('requests')
            .where('status', isEqualTo: 'pending')
            .get();

        // Get this month's requests
        final monthlyRequests = await _firestore
            .collection('requests')
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thisMonth))
            .get();

        return {
          'todayCheckIns': todayAttendance.docs.length,
          'pendingApprovals': pendingRequests.docs.length,
          'monthlyRequests': monthlyRequests.docs.length,
          'lastUpdated': DateTime.now().toIso8601String(),
        };
      } catch (e) {
        return {
          'error': 'Failed to load dashboard metrics: $e',
          'lastUpdated': DateTime.now().toIso8601String(),
        };
      }
    }).asyncMap((future) => future);
  }

  // Export data for reports
  Future<Map<String, dynamic>> generateReport({
    required String reportType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      switch (reportType) {
        case 'attendance':
          return await getAttendanceAnalytics(
            startDate: startDate,
            endDate: endDate,
          );
        case 'requests':
          return await getRequestAnalytics(
            startDate: startDate,
            endDate: endDate,
          );
        case 'combined':
          final attendance = await getAttendanceAnalytics(
            startDate: startDate,
            endDate: endDate,
          );
          final requests = await getRequestAnalytics(
            startDate: startDate,
            endDate: endDate,
          );
          return {
            'attendance': attendance,
            'requests': requests,
            'generatedAt': DateTime.now().toIso8601String(),
          };
        default:
          throw Exception('Unknown report type: $reportType');
      }
    } catch (e) {
      throw Exception('Failed to generate report: $e');
    }
  }
}