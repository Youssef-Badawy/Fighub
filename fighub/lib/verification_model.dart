import 'package:cloud_firestore/cloud_firestore.dart';

class VerificationPlan {
  final String id;
  final String name;
  final int price;
  final int durationMonths;

  const VerificationPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.durationMonths,
  });

  static const VerificationPlan monthly =
      VerificationPlan(
    id: 'monthly',
    name: 'Monthly',
    price: 100,
    durationMonths: 1,
  );

  static const VerificationPlan threeMonths =
      VerificationPlan(
    id: 'three_months',
    name: '3 Months',
    price: 200,
    durationMonths: 3,
  );

  static const List<VerificationPlan> all = [
    monthly,
    threeMonths,
  ];
}

class VerificationRequest {
  final String? id;
  final String userId;
  final String planId;
  final int amount;
  final int durationMonths;
  final String status;
  final String paymentProofUrl;
  final String rejectionReason;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final DateTime? startsAt;
  final DateTime? expiresAt;

  const VerificationRequest({
    this.id,
    required this.userId,
    required this.planId,
    required this.amount,
    required this.durationMonths,
    required this.status,
    required this.paymentProofUrl,
    required this.rejectionReason,
    this.createdAt,
    this.reviewedAt,
    this.startsAt,
    this.expiresAt,
  });

  bool get isPending => status == 'Pending';

  bool get isApproved => status == 'Approved';

  bool get isRejected => status == 'Rejected';

  bool get isExpired {
    if (status != 'Approved' || expiresAt == null) {
      return false;
    }

    return expiresAt!.isBefore(DateTime.now());
  }

  bool get isCurrentlyVerified {
    if (!isApproved || expiresAt == null) {
      return false;
    }

    final now = DateTime.now();

    return startsAt != null &&
        !now.isBefore(startsAt!) &&
        now.isBefore(expiresAt!);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'planId': planId,
      'amount': amount,
      'durationMonths': durationMonths,
      'status': status,
      'paymentProofUrl': paymentProofUrl,
      'rejectionReason': rejectionReason,
      'createdAt': FieldValue.serverTimestamp(),
      'reviewedAt': reviewedAt != null
          ? Timestamp.fromDate(reviewedAt!)
          : null,
      'startsAt': startsAt != null
          ? Timestamp.fromDate(startsAt!)
          : null,
      'expiresAt': expiresAt != null
          ? Timestamp.fromDate(expiresAt!)
          : null,
    };
  }

  factory VerificationRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }

      return null;
    }

    return VerificationRequest(
      id: document.id,
      userId: data['userId'] as String? ?? '',
      planId: data['planId'] as String? ?? '',
      amount: data['amount'] as int? ?? 0,
      durationMonths:
          data['durationMonths'] as int? ?? 0,
      status: data['status'] as String? ?? 'Pending',
      paymentProofUrl:
          data['paymentProofUrl'] as String? ?? '',
      rejectionReason:
          data['rejectionReason'] as String? ?? '',
      createdAt: parseDate(data['createdAt']),
      reviewedAt: parseDate(data['reviewedAt']),
      startsAt: parseDate(data['startsAt']),
      expiresAt: parseDate(data['expiresAt']),
    );
  }
}
