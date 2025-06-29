import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String userId;
  final DateTime date;
  final String dateKey;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final double? totalHours;
  final bool isLate;
  final String status;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.date,
    String? dateKey,
    this.checkInTime,
    this.checkOutTime,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.totalHours,
    this.isLate = false,
    this.status = 'pending',
  }) : dateKey = dateKey ?? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      dateKey: data['dateKey'] ?? '',
      checkInTime: data['checkInTime'] != null
          ? (data['checkInTime'] as Timestamp).toDate()
          : null,
      checkOutTime: data['checkOutTime'] != null
          ? (data['checkOutTime'] as Timestamp).toDate()
          : null,
      checkInLatitude: data['checkInLatitude']?.toDouble(),
      checkInLongitude: data['checkInLongitude']?.toDouble(),
      checkOutLatitude: data['checkOutLatitude']?.toDouble(),
      checkOutLongitude: data['checkOutLongitude']?.toDouble(),
      totalHours: data['totalHours']?.toDouble(),
      isLate: data['isLate'] ?? false,
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'dateKey': dateKey,
      'checkInTime': checkInTime != null ? Timestamp.fromDate(checkInTime!) : null,
      'checkOutTime': checkOutTime != null ? Timestamp.fromDate(checkOutTime!) : null,
      'checkInLatitude': checkInLatitude,
      'checkInLongitude': checkInLongitude,
      'checkOutLatitude': checkOutLatitude,
      'checkOutLongitude': checkOutLongitude,
      'totalHours': totalHours,
      'isLate': isLate,
      'status': status,
    };
  }

  AttendanceModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? dateKey,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    double? checkInLatitude,
    double? checkInLongitude,
    double? checkOutLatitude,
    double? checkOutLongitude,
    double? totalHours,
    bool? isLate,
    String? status,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      dateKey: dateKey ?? this.dateKey,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInLatitude: checkInLatitude ?? this.checkInLatitude,
      checkInLongitude: checkInLongitude ?? this.checkInLongitude,
      checkOutLatitude: checkOutLatitude ?? this.checkOutLatitude,
      checkOutLongitude: checkOutLongitude ?? this.checkOutLongitude,
      totalHours: totalHours ?? this.totalHours,
      isLate: isLate ?? this.isLate,
      status: status ?? this.status,
    );
  }

  bool get isCheckedIn => checkInTime != null && checkOutTime == null;
  bool get isCheckedOut => checkInTime != null && checkOutTime != null;
  
  String get formattedCheckInTime {
    if (checkInTime == null) return '--:--';
    return '${checkInTime!.hour.toString().padLeft(2, '0')}:${checkInTime!.minute.toString().padLeft(2, '0')}';
  }

  String get formattedCheckOutTime {
    if (checkOutTime == null) return '--:--';
    return '${checkOutTime!.hour.toString().padLeft(2, '0')}:${checkOutTime!.minute.toString().padLeft(2, '0')}';
  }

  String get formattedTotalHours {
    if (totalHours == null) return '0.0';
    return totalHours!.toStringAsFixed(1);
  }
}