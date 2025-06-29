import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  static CollectionReference get users => _firestore.collection('users');
  static CollectionReference get attendance => _firestore.collection('attendance');
  static CollectionReference get requests => _firestore.collection('requests');
  static CollectionReference get companies => _firestore.collection('companies');
  static CollectionReference get reports => _firestore.collection('reports');
  static CollectionReference get notifications => _firestore.collection('notifications');

  // User operations
  static Future<void> createUser(String userId, Map<String, dynamic> userData) async {
    await users.doc(userId).set({
      ...userData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
  }

  static Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    await users.doc(userId).update({
      ...userData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<DocumentSnapshot?> getUser(String userId) async {
    try {
      return await users.doc(userId).get();
    } catch (e) {
      return null;
    }
  }

  static Stream<DocumentSnapshot> getUserStream(String userId) {
    return users.doc(userId).snapshots();
  }

  // Attendance operations
  static Future<String> createAttendance(Map<String, dynamic> attendanceData) async {
    final docRef = await attendance.add({
      ...attendanceData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  static Future<void> updateAttendance(String attendanceId, Map<String, dynamic> updates) async {
    await attendance.doc(attendanceId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<QuerySnapshot> getTodayAttendance(String userId) async {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return await attendance
        .where('userId', isEqualTo: userId)
        .where('dateKey', isEqualTo: dateKey)
        .limit(1)
        .get();
  }

  static Stream<QuerySnapshot> getTodayAttendanceStream(String userId) {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return attendance
        .where('userId', isEqualTo: userId)
        .where('dateKey', isEqualTo: dateKey)
        .limit(1)
        .snapshots();
  }

  static Future<QuerySnapshot> getMonthlyAttendance(String userId, DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 1);

    return await attendance
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
        .orderBy('date', descending: true)
        .get();
  }

  // Request operations
  static Future<String> createRequest(Map<String, dynamic> requestData) async {
    final docRef = await requests.add({
      ...requestData,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  static Future<void> updateRequestStatus(
    String requestId,
    String status, {
    String? approvedBy,
    String? rejectionReason,
  }) async {
    final updates = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (approvedBy != null) {
      updates['approvedBy'] = approvedBy;
      updates['approvedAt'] = FieldValue.serverTimestamp();
    }

    if (rejectionReason != null) {
      updates['rejectionReason'] = rejectionReason;
    }

    await requests.doc(requestId).update(updates);
  }

  static Future<QuerySnapshot> getUserRequests(String userId) async {
    return await requests
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
  }

  static Stream<QuerySnapshot> getUserRequestsStream(String userId) {
    return requests
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<QuerySnapshot> getPendingRequests() async {
    return await requests
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .get();
  }

  static Stream<QuerySnapshot> getPendingRequestsStream() {
    return requests
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Notification operations
  static Future<String> createNotification(Map<String, dynamic> notificationData) async {
    final docRef = await notifications.add({
      ...notificationData,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    await notifications.doc(notificationId).update({'isRead': true});
  }

  static Future<QuerySnapshot> getUserNotifications(String userId) async {
    return await notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();
  }

  static Stream<QuerySnapshot> getUserNotificationsStream(String userId) {
    return notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();
  }

  static Future<int> getUnreadNotificationCount(String userId) async {
    final query = await notifications
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .count()
        .get();
    return query.count ?? 0;
  }

  // Company operations
  static Future<DocumentSnapshot?> getCompany(String companyId) async {
    try {
      return await companies.doc(companyId).get();
    } catch (e) {
      return null;
    }
  }

  static Stream<DocumentSnapshot> getCompanyStream(String companyId) {
    return companies.doc(companyId).snapshots();
  }

  // Batch operations
  static WriteBatch batch() => _firestore.batch();

  static Future<void> runTransaction(
    TransactionHandler updateFunction,
  ) async {
    return await _firestore.runTransaction(updateFunction);
  }

  // Utility methods
  static Timestamp now() => Timestamp.now();
  
  static Timestamp fromDate(DateTime date) => Timestamp.fromDate(date);
  
  static DateTime toDate(Timestamp timestamp) => timestamp.toDate();

  // Query helpers
  static Query whereArrayContains(CollectionReference collection, String field, dynamic value) {
    return collection.where(field, arrayContains: value);
  }

  static Query whereIn(CollectionReference collection, String field, List<dynamic> values) {
    return collection.where(field, whereIn: values);
  }

  static Query orderByDescending(Query query, String field) {
    return query.orderBy(field, descending: true);
  }

  static Query limitResults(Query query, int limit) {
    return query.limit(limit);
  }
}