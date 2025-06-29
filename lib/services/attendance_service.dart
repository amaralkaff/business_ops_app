import 'package:location/location.dart';
import '../models/attendance_model.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/firestore_service.dart';

class AttendanceService {
  final AuthService _authService = AuthService();
  final LocationService _locationService = LocationService();

  static const double standardWorkHours = 8.0;
  static const int lateThresholdMinutes = 15; // 15 minutes late threshold

  Future<AttendanceModel?> checkIn() async {
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if already checked in today first
      final existingAttendance = await getTodayAttendance();
      if (existingAttendance != null) {
        if (existingAttendance.checkInTime != null) {
          throw Exception('Already checked in today at ${existingAttendance.formattedCheckInTime}');
        }
      }

      final LocationData location = await _locationService.getCurrentLocation() ?? 
          (throw Exception('Could not get location'));

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final checkInTime = DateTime.now();
      final isLate = _isLateCheckIn(checkInTime);

      final dateKey = '${todayStart.year}-${todayStart.month.toString().padLeft(2, '0')}-${todayStart.day.toString().padLeft(2, '0')}';
      
      final attendance = AttendanceModel(
        id: '',
        userId: user.uid,
        date: todayStart,
        dateKey: dateKey,
        checkInTime: checkInTime,
        checkInLatitude: location.latitude,
        checkInLongitude: location.longitude,
        isLate: isLate,
        status: 'checked_in',
      );

      // If attendance record exists but no check-in time, update it
      if (existingAttendance != null) {
        await FirestoreService.updateAttendance(
          existingAttendance.id, 
          attendance.toFirestore(),
        );
        return attendance.copyWith(id: existingAttendance.id);
      } else {
        // Create new attendance record
        final docId = await FirestoreService.createAttendance(attendance.toFirestore());
        return attendance.copyWith(id: docId);
      }
    } catch (e) {
      throw Exception('Failed to check in: $e');
    }
  }

  Future<AttendanceModel?> checkOut() async {
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final LocationData location = await _locationService.getCurrentLocation() ?? 
          (throw Exception('Could not get location'));

      final attendance = await getTodayAttendance();
      if (attendance == null || attendance.checkInTime == null) {
        throw Exception('Must check in first');
      }

      if (attendance.checkOutTime != null) {
        throw Exception('Already checked out today');
      }

      final checkOutTime = DateTime.now();
      final totalHours = _calculateWorkingHours(attendance.checkInTime!, checkOutTime);

      final updatedAttendance = attendance.copyWith(
        checkOutTime: checkOutTime,
        checkOutLatitude: location.latitude,
        checkOutLongitude: location.longitude,
        totalHours: totalHours,
        status: 'completed',
      );

      await FirestoreService.updateAttendance(
        attendance.id, 
        updatedAttendance.toFirestore(),
      );

      return updatedAttendance;
    } catch (e) {
      throw Exception('Failed to check out: $e');
    }
  }

  Future<AttendanceModel?> getTodayAttendance() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return null;

      final query = await FirestoreService.getTodayAttendance(user.uid);

      if (query.docs.isEmpty) return null;

      return AttendanceModel.fromFirestore(query.docs.first);
    } catch (e) {
      return null;
    }
  }

  Future<List<AttendanceModel>> getMonthlyAttendance(DateTime month) async {
    try {
      final user = _authService.currentUser;
      if (user == null) return [];

      final query = await FirestoreService.getMonthlyAttendance(user.uid, month);

      return query.docs
          .map((doc) => AttendanceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  double _calculateWorkingHours(DateTime checkIn, DateTime checkOut) {
    final duration = checkOut.difference(checkIn);
    return duration.inMinutes / 60.0;
  }

  bool _isLateCheckIn(DateTime checkInTime) {
    // Standard work time: 9:00 AM
    final standardStartTime = DateTime(
      checkInTime.year,
      checkInTime.month,
      checkInTime.day,
      9, // 9 AM
      0,
    );

    final lateThreshold = standardStartTime.add(
      Duration(minutes: lateThresholdMinutes),
    );

    return checkInTime.isAfter(lateThreshold);
  }

  Stream<AttendanceModel?> getTodayAttendanceStream() {
    final user = _authService.currentUser;
    if (user == null) return Stream.value(null);

    return FirestoreService.getTodayAttendanceStream(user.uid)
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return AttendanceModel.fromFirestore(snapshot.docs.first);
    });
  }
}