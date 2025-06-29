import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestType { goods, cash, leave }
enum RequestStatus { pending, approved, rejected }

class RequestModel {
  final String id;
  final String userId;
  final RequestType type;
  final String title;
  final String description;
  final double? amount;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? approverNotes;

  RequestModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    this.amount,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.approverNotes,
  });

  factory RequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RequestModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: RequestType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => RequestType.goods,
      ),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      amount: data['amount']?.toDouble(),
      status: RequestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => RequestStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      approvedAt: data['approvedAt'] != null 
          ? (data['approvedAt'] as Timestamp).toDate() 
          : null,
      approverNotes: data['approverNotes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'amount': amount,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approverNotes': approverNotes,
    };
  }

  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String get statusText {
    switch (status) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.approved:
        return 'Approved';
      case RequestStatus.rejected:
        return 'Rejected';
    }
  }

  String get typeText {
    switch (type) {
      case RequestType.goods:
        return 'Goods Request';
      case RequestType.cash:
        return 'Cash Request';
      case RequestType.leave:
        return 'Leave Request';
    }
  }
}