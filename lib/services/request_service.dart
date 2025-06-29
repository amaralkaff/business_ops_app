import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/request_model.dart';

class RequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<RequestModel?> submitRequest({
    required RequestType type,
    required String title,
    required String description,
    double? amount,
  }) async {
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      final docRef = await _firestore.collection('requests').add({
        'userId': currentUser!.uid,
        'type': type.toString().split('.').last,
        'title': title,
        'description': description,
        'amount': amount,
        'status': RequestStatus.pending.toString().split('.').last,
        'createdAt': FieldValue.serverTimestamp(),
        'approvedAt': null,
        'approverNotes': null,
      });

      final doc = await docRef.get();
      return RequestModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to submit request: $e');
    }
  }

  Stream<List<RequestModel>> getUserRequestsStream() {
    if (currentUser == null) return const Stream.empty();

    return _firestore
        .collection('requests')
        .where('userId', isEqualTo: currentUser!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RequestModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<List<RequestModel>> getUserRequests() async {
    if (currentUser == null) return [];

    try {
      final snapshot = await _firestore
          .collection('requests')
          .where('userId', isEqualTo: currentUser!.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RequestModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch requests: $e');
    }
  }

  Future<void> updateRequestStatus({
    required String requestId,
    required RequestStatus status,
    String? approverNotes,
  }) async {
    try {
      await _firestore.collection('requests').doc(requestId).update({
        'status': status.toString().split('.').last,
        'approvedAt': status != RequestStatus.pending 
            ? FieldValue.serverTimestamp() 
            : null,
        'approverNotes': approverNotes,
      });
    } catch (e) {
      throw Exception('Failed to update request status: $e');
    }
  }
}