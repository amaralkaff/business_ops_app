import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { staff, supervisor, hrd, finance }

class UserRoleModel {
  final String userId;
  final UserRole role;
  final String email;
  final String? displayName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserRoleModel({
    required this.userId,
    required this.role,
    required this.email,
    this.displayName,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserRoleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserRoleModel(
      userId: doc.id,
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == data['role'],
        orElse: () => UserRole.staff,
      ),
      email: data['email'] ?? '',
      displayName: data['displayName'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'role': role.toString().split('.').last,
      'email': email,
      'displayName': displayName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String get roleDisplayName {
    switch (role) {
      case UserRole.staff:
        return 'Staff';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.hrd:
        return 'HR Department';
      case UserRole.finance:
        return 'Finance';
    }
  }

  bool get canApproveRequests {
    return role == UserRole.supervisor || role == UserRole.hrd || role == UserRole.finance;
  }

  bool get canManageUsers {
    return role == UserRole.hrd;
  }

  bool get canViewReports {
    return role == UserRole.supervisor || role == UserRole.hrd || role == UserRole.finance;
  }

  bool get isStaff {
    return role == UserRole.staff;
  }

  bool get isSupervisor {
    return role == UserRole.supervisor;
  }

  bool get isHRD {
    return role == UserRole.hrd;
  }

  bool get isFinance {
    return role == UserRole.finance;
  }
}