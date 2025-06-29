import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_model.dart';
import '../models/request_model.dart';

class InsightsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate productivity insights
  Future<Map<String, dynamic>> getProductivityInsights({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final start = startDate ?? DateTime(now.year, now.month, 1);
      final end = endDate ?? DateTime(now.year, now.month + 1, 0);

      // Get attendance data
      final attendanceSnapshot = await _firestore
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final attendanceRecords = attendanceSnapshot.docs
          .map((doc) => AttendanceModel.fromFirestore(doc))
          .toList();

      // Calculate insights
      final insights = <String, dynamic>{};

      // Attendance patterns
      insights['attendancePatterns'] = _analyzeAttendancePatterns(attendanceRecords);
      
      // Late arrival trends
      insights['lateArrivalTrends'] = _analyzeLateArrivalTrends(attendanceRecords);
      
      // Working hours efficiency
      insights['workingHoursEfficiency'] = _analyzeWorkingHours(attendanceRecords);
      
      // Team performance indicators
      insights['teamPerformance'] = _analyzeTeamPerformance(attendanceRecords);

      return insights;
    } catch (e) {
      throw Exception('Failed to generate productivity insights: $e');
    }
  }

  // Generate request insights
  Future<Map<String, dynamic>> getRequestInsights({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final start = startDate ?? DateTime(now.year, now.month, 1);
      final end = endDate ?? DateTime(now.year, now.month + 1, 0);

      // Get request data
      final requestSnapshot = await _firestore
          .collection('requests')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final requests = requestSnapshot.docs
          .map((doc) => RequestModel.fromFirestore(doc))
          .toList();

      final insights = <String, dynamic>{};

      // Request patterns
      insights['requestPatterns'] = _analyzeRequestPatterns(requests);
      
      // Approval efficiency
      insights['approvalEfficiency'] = _analyzeApprovalEfficiency(requests);
      
      // Cost analysis
      insights['costAnalysis'] = _analyzeCostTrends(requests);
      
      // Request frequency insights
      insights['frequencyInsights'] = _analyzeRequestFrequency(requests);

      return insights;
    } catch (e) {
      throw Exception('Failed to generate request insights: $e');
    }
  }

  // Generate operational recommendations
  Future<List<Map<String, dynamic>>> getOperationalRecommendations() async {
    try {
      final recommendations = <Map<String, dynamic>>[];
      
      // Get recent data for analysis
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      
      final productivityInsights = await getProductivityInsights(
        startDate: lastMonth,
        endDate: now,
      );
      
      final requestInsights = await getRequestInsights(
        startDate: lastMonth,
        endDate: now,
      );

      // Generate recommendations based on insights
      recommendations.addAll(_generateAttendanceRecommendations(productivityInsights));
      recommendations.addAll(_generateRequestRecommendations(requestInsights));
      
      // Sort by priority
      recommendations.sort((a, b) => 
        (b['priority'] as String).compareTo(a['priority'] as String));

      return recommendations;
    } catch (e) {
      throw Exception('Failed to generate recommendations: $e');
    }
  }

  Map<String, dynamic> _analyzeAttendancePatterns(List<AttendanceModel> records) {
    final patterns = <String, dynamic>{};
    
    if (records.isEmpty) return patterns;

    // Daily check-in patterns
    final checkInHours = <int, int>{};
    for (final record in records) {
      if (record.checkInTime != null) {
        final hour = record.checkInTime!.hour;
        checkInHours[hour] = (checkInHours[hour] ?? 0) + 1;
      }
    }

    // Find peak check-in time
    if (checkInHours.isNotEmpty) {
      final peakHour = checkInHours.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      patterns['peakCheckInHour'] = peakHour.key;
      patterns['peakCheckInCount'] = peakHour.value;
    }

    // Consistency score (percentage of days with attendance)
    final totalWorkingDays = DateTime.now().difference(
      records.first.date).inDays + 1;
    patterns['consistencyScore'] = (records.length / totalWorkingDays * 100).round();

    return patterns;
  }

  Map<String, dynamic> _analyzeLateArrivalTrends(List<AttendanceModel> records) {
    final trends = <String, dynamic>{};
    
    final lateRecords = records.where((r) => r.isLate).toList();
    trends['totalLateArrivals'] = lateRecords.length;
    trends['lateArrivalRate'] = records.isNotEmpty 
        ? (lateRecords.length / records.length * 100).toStringAsFixed(1)
        : '0.0';

    // Day of week analysis
    final lateByDay = <int, int>{};
    for (final record in lateRecords) {
      final weekday = record.date.weekday;
      lateByDay[weekday] = (lateByDay[weekday] ?? 0) + 1;
    }

    if (lateByDay.isNotEmpty) {
      final worstDay = lateByDay.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      final dayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      trends['worstDay'] = dayNames[worstDay.key];
      trends['worstDayCount'] = worstDay.value;
    }

    return trends;
  }

  Map<String, dynamic> _analyzeWorkingHours(List<AttendanceModel> records) {
    final analysis = <String, dynamic>{};
    
    final completedRecords = records.where((r) => r.totalHours != null).toList();
    
    if (completedRecords.isNotEmpty) {
      final totalHours = completedRecords.fold<double>(
        0.0, (sum, record) => sum + (record.totalHours ?? 0.0));
      
      analysis['averageHours'] = (totalHours / completedRecords.length).toStringAsFixed(2);
      analysis['totalProductiveHours'] = totalHours.toStringAsFixed(2);
      
      // Efficiency score (based on 8-hour standard)
      final expectedHours = completedRecords.length * 8.0;
      analysis['efficiencyScore'] = ((totalHours / expectedHours) * 100).round();
    }

    return analysis;
  }

  Map<String, dynamic> _analyzeTeamPerformance(List<AttendanceModel> records) {
    final performance = <String, dynamic>{};
    
    // Group by user
    final userGroups = <String, List<AttendanceModel>>{};
    for (final record in records) {
      userGroups.putIfAbsent(record.userId, () => []).add(record);
    }

    // Calculate team metrics
    performance['totalUsers'] = userGroups.length;
    performance['activeUsers'] = userGroups.values
        .where((userRecords) => userRecords.isNotEmpty).length;

    // Find most consistent user
    if (userGroups.isNotEmpty) {
      final userConsistency = userGroups.map((userId, userRecords) {
        final completedDays = userRecords.where((r) => r.totalHours != null).length;
        return MapEntry(userId, completedDays);
      });
      
      if (userConsistency.isNotEmpty) {
        final topUser = userConsistency.entries
            .reduce((a, b) => a.value > b.value ? a : b);
        performance['topPerformerUserId'] = topUser.key;
        performance['topPerformerDays'] = topUser.value;
      }
    }

    return performance;
  }

  Map<String, dynamic> _analyzeRequestPatterns(List<RequestModel> requests) {
    final patterns = <String, dynamic>{};
    
    if (requests.isEmpty) return patterns;

    // Request frequency by type
    final typeFrequency = <RequestType, int>{};
    for (final request in requests) {
      typeFrequency[request.type] = (typeFrequency[request.type] ?? 0) + 1;
    }

    patterns['mostRequestedType'] = typeFrequency.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key.toString().split('.').last;

    // Monthly request trend
    final now = DateTime.now();
    final thisMonth = requests.where((r) => 
        r.createdAt.year == now.year && r.createdAt.month == now.month).length;
    final lastMonth = requests.where((r) => 
        r.createdAt.year == now.year && r.createdAt.month == now.month - 1).length;
    
    patterns['monthlyTrend'] = lastMonth > 0 
        ? ((thisMonth - lastMonth) / lastMonth * 100).toStringAsFixed(1)
        : '0.0';

    return patterns;
  }

  Map<String, dynamic> _analyzeApprovalEfficiency(List<RequestModel> requests) {
    final efficiency = <String, dynamic>{};
    
    final processedRequests = requests.where((r) => 
        r.status != RequestStatus.pending).toList();
    
    if (processedRequests.isNotEmpty) {
      final approved = processedRequests.where((r) => 
          r.status == RequestStatus.approved).length;
      
      efficiency['approvalRate'] = (approved / processedRequests.length * 100).toStringAsFixed(1);
      efficiency['totalProcessed'] = processedRequests.length;
      efficiency['averageProcessingTime'] = 'N/A'; // Would need approval timestamps
    }

    return efficiency;
  }

  Map<String, dynamic> _analyzeCostTrends(List<RequestModel> requests) {
    final costAnalysis = <String, dynamic>{};
    
    final cashRequests = requests.where((r) => 
        r.type == RequestType.cash && r.amount != null).toList();
    
    if (cashRequests.isNotEmpty) {
      final totalAmount = cashRequests.fold<double>(
          0.0, (sum, request) => sum + (request.amount ?? 0.0));
      
      costAnalysis['totalCashRequested'] = totalAmount.toStringAsFixed(2);
      costAnalysis['averageRequestAmount'] = (totalAmount / cashRequests.length).toStringAsFixed(2);
      
      // Largest request
      final largestRequest = cashRequests.reduce((a, b) => 
          (a.amount ?? 0.0) > (b.amount ?? 0.0) ? a : b);
      costAnalysis['largestRequestAmount'] = largestRequest.amount?.toStringAsFixed(2);
    }

    return costAnalysis;
  }

  Map<String, dynamic> _analyzeRequestFrequency(List<RequestModel> requests) {
    final frequency = <String, dynamic>{};
    
    // Group by user
    final userRequests = <String, int>{};
    for (final request in requests) {
      userRequests[request.userId] = (userRequests[request.userId] ?? 0) + 1;
    }

    if (userRequests.isNotEmpty) {
      final mostActiveUser = userRequests.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      
      frequency['mostActiveUserId'] = mostActiveUser.key;
      frequency['mostActiveUserRequests'] = mostActiveUser.value;
      frequency['averageRequestsPerUser'] = (requests.length / userRequests.length).toStringAsFixed(1);
    }

    return frequency;
  }

  List<Map<String, dynamic>> _generateAttendanceRecommendations(Map<String, dynamic> insights) {
    final recommendations = <Map<String, dynamic>>[];
    
    final patterns = insights['attendancePatterns'] as Map<String, dynamic>? ?? {};
    final trends = insights['lateArrivalTrends'] as Map<String, dynamic>? ?? {};
    final efficiency = insights['workingHoursEfficiency'] as Map<String, dynamic>? ?? {};

    // Late arrival recommendations
    final lateRate = double.tryParse(trends['lateArrivalRate'] ?? '0.0') ?? 0.0;
    if (lateRate > 20.0) {
      recommendations.add({
        'title': 'High Late Arrival Rate',
        'description': 'Consider implementing flexible work hours or investigating transportation issues.',
        'priority': 'high',
        'category': 'attendance',
        'metric': '${lateRate.toStringAsFixed(1)}% late arrivals',
      });
    }

    // Efficiency recommendations
    final efficiencyScore = efficiency['efficiencyScore'] as int? ?? 0;
    if (efficiencyScore < 80) {
      recommendations.add({
        'title': 'Low Work Hour Efficiency',
        'description': 'Review work processes and consider productivity training.',
        'priority': 'medium',
        'category': 'productivity',
        'metric': '$efficiencyScore% efficiency score',
      });
    }

    // Consistency recommendations
    final consistencyScore = patterns['consistencyScore'] as int? ?? 0;
    if (consistencyScore < 90) {
      recommendations.add({
        'title': 'Attendance Consistency Issues',
        'description': 'Implement attendance tracking improvements and employee engagement initiatives.',
        'priority': 'medium',
        'category': 'attendance',
        'metric': '$consistencyScore% consistency',
      });
    }

    return recommendations;
  }

  List<Map<String, dynamic>> _generateRequestRecommendations(Map<String, dynamic> insights) {
    final recommendations = <Map<String, dynamic>>[];
    
    final patterns = insights['requestPatterns'] as Map<String, dynamic>? ?? {};
    final efficiency = insights['approvalEfficiency'] as Map<String, dynamic>? ?? {};
    final costs = insights['costAnalysis'] as Map<String, dynamic>? ?? {};

    // Approval rate recommendations
    final approvalRate = double.tryParse(efficiency['approvalRate'] ?? '100.0') ?? 100.0;
    if (approvalRate < 70.0) {
      recommendations.add({
        'title': 'Low Approval Rate',
        'description': 'Review approval criteria and provide clearer request guidelines.',
        'priority': 'high',
        'category': 'requests',
        'metric': '${approvalRate.toStringAsFixed(1)}% approval rate',
      });
    }

    // Cost optimization recommendations
    final totalCash = double.tryParse(costs['totalCashRequested'] ?? '0.0') ?? 0.0;
    if (totalCash > 10000.0) {
      recommendations.add({
        'title': 'High Cash Request Volume',
        'description': 'Consider budget planning and bulk purchasing to reduce frequent cash requests.',
        'priority': 'medium',
        'category': 'finance',
        'metric': '\$${totalCash.toStringAsFixed(2)} requested',
      });
    }

    // Request frequency recommendations
    final monthlyTrend = double.tryParse(patterns['monthlyTrend'] ?? '0.0') ?? 0.0;
    if (monthlyTrend > 50.0) {
      recommendations.add({
        'title': 'Increasing Request Volume',
        'description': 'Monitor resource allocation and consider proactive inventory management.',
        'priority': 'medium',
        'category': 'planning',
        'metric': '+${monthlyTrend.toStringAsFixed(1)}% monthly increase',
      });
    }

    return recommendations;
  }
}