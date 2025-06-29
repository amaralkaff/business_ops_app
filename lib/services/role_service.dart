import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_role_model.dart';

class RoleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<UserRoleModel?> createUserRole({
    required String userId,
    required UserRole role,
    required String email,
    String? displayName,
  }) async {
    try {
      final userRoleData = UserRoleModel(
        userId: userId,
        role: role,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('user_roles')
          .doc(userId)
          .set(userRoleData.toFirestore());

      return userRoleData;
    } catch (e) {
      throw Exception('Failed to create user role: $e');
    }
  }

  Future<UserRoleModel?> getUserRole(String userId) async {
    try {
      final doc = await _firestore
          .collection('user_roles')
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserRoleModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user role: $e');
    }
  }

  Future<UserRoleModel?> getCurrentUserRole() async {
    if (currentUser == null) return null;
    return getUserRole(currentUser!.uid);
  }

  Stream<UserRoleModel?> getCurrentUserRoleStream() {
    if (currentUser == null) return const Stream.empty();

    return _firestore
        .collection('user_roles')
        .doc(currentUser!.uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserRoleModel.fromFirestore(doc);
      }
      return null;
    });
  }

  Future<void> updateUserRole({
    required String userId,
    required UserRole newRole,
  }) async {
    try {
      await _firestore
          .collection('user_roles')
          .doc(userId)
          .update({
        'role': newRole.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  Future<List<UserRoleModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore
          .collection('user_roles')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => UserRoleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }

  Future<List<UserRoleModel>> getUsersByRole(UserRole role) async {
    try {
      final snapshot = await _firestore
          .collection('user_roles')
          .where('role', isEqualTo: role.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => UserRoleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get users by role: $e');
    }
  }

  bool hasPermission(UserRoleModel? userRole, String permission) {
    if (userRole == null) return false;

    switch (permission) {
      case 'approve_requests':
        return userRole.canApproveRequests;
      case 'manage_users':
        return userRole.canManageUsers;
      case 'view_reports':
        return userRole.canViewReports;
      case 'submit_requests':
        return true; // All users can submit requests
      default:
        return false;
    }
  }
}