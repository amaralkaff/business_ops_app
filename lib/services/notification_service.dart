import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // Create notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? actionData,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'isRead': false,
        'actionData': actionData,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
      });
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // Get user notifications stream
  Stream<List<Map<String, dynamic>>> getUserNotificationsStream() {
    if (currentUser == null) return const Stream.empty();

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser!.uid)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Sort by createdAt descending, unread first
      notifications.sort((a, b) {
        // Unread notifications first
        if (a['isRead'] != b['isRead']) {
          return a['isRead'] ? 1 : -1;
        }
        // Then by creation time (newest first)
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime != null && bTime != null) {
          return bTime.compareTo(aTime);
        }
        return 0;
      });
      
      return notifications;
    });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (currentUser == null) return;

    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser!.uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Get unread notification count
  Stream<int> getUnreadCountStream() {
    if (currentUser == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser!.uid)
        .where('isRead', isEqualTo: false)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Notification types for system events
  Future<void> notifyRequestSubmitted({
    required String requestId,
    required String requestTitle,
    required String requestType,
    required String submitterUserId,
    required List<String> approverUserIds,
  }) async {
    for (final approverId in approverUserIds) {
      await createNotification(
        userId: approverId,
        title: 'New Request Submitted',
        body: '$requestTitle requires your approval',
        type: 'request_approval',
        actionData: {
          'requestId': requestId,
          'requestType': requestType,
          'submitterId': submitterUserId,
        },
      );
    }
  }

  Future<void> notifyRequestStatusChanged({
    required String requestId,
    required String requestTitle,
    required String status,
    required String submitterUserId,
    String? approverNotes,
  }) async {
    final statusText = status == 'approved' ? 'approved' : 'rejected';
    final body = approverNotes?.isNotEmpty == true
        ? '$requestTitle has been $statusText. Notes: $approverNotes'
        : '$requestTitle has been $statusText';

    await createNotification(
      userId: submitterUserId,
      title: 'Request ${statusText.toUpperCase()}',
      body: body,
      type: 'request_status_update',
      actionData: {
        'requestId': requestId,
        'status': status,
      },
    );
  }

  Future<void> notifyAttendanceReminder({
    required String userId,
    required String message,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Attendance Reminder',
      body: message,
      type: 'attendance_reminder',
    );
  }

  Future<void> notifySystemAlert({
    required List<String> userIds,
    required String title,
    required String message,
    Map<String, dynamic>? actionData,
  }) async {
    for (final userId in userIds) {
      await createNotification(
        userId: userId,
        title: title,
        body: message,
        type: 'system_alert',
        actionData: actionData,
      );
    }
  }

  // Clean up expired notifications
  Future<void> cleanupExpiredNotifications() async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('expiresAt', isLessThan: Timestamp.now())
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to cleanup expired notifications: $e');
    }
  }

  // Get notification statistics
  Future<Map<String, dynamic>> getNotificationStats() async {
    if (currentUser == null) return {};

    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser!.uid)
          .get();

      final notifications = snapshot.docs;
      final unreadCount = notifications.where((doc) => 
          doc.data()['isRead'] == false).length;
      
      final typeBreakdown = <String, int>{};
      for (final doc in notifications) {
        final type = doc.data()['type'] as String;
        typeBreakdown[type] = (typeBreakdown[type] ?? 0) + 1;
      }

      return {
        'totalNotifications': notifications.length,
        'unreadCount': unreadCount,
        'readCount': notifications.length - unreadCount,
        'typeBreakdown': typeBreakdown,
      };
    } catch (e) {
      throw Exception('Failed to get notification statistics: $e');
    }
  }
}