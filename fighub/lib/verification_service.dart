import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'verification_model.dart';

class VerificationService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>
      get _verificationCollection {
    return _firestore.collection('verification_requests');
  }

  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User must be signed in.');
    }

    return user.uid;
  }

  VerificationPlan getPlan(String planId) {
    for (final plan in VerificationPlan.all) {
      if (plan.id == planId) {
        return plan;
      }
    }

    throw ArgumentError(
      'Unknown verification plan.',
    );
  }

  Future<String> createRequest({
    required String planId,
    required String paymentProofUrl,
  }) async {
    final uid = _uid;

    if (paymentProofUrl.trim().isEmpty) {
      throw ArgumentError(
        'Payment proof is required.',
      );
    }

    final plan = getPlan(planId);

    final existing = await _verificationCollection
        .where(
          'userId',
          isEqualTo: uid,
        )
        .where(
          'status',
          isEqualTo: 'Pending',
        )
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw StateError(
        'You already have a pending verification request.',
      );
    }

    final reference =
        await _verificationCollection.add({
      'userId': uid,
      'planId': plan.id,
      'amount': plan.price,
      'durationMonths': plan.durationMonths,
      'status': 'Pending',
      'paymentProofUrl': paymentProofUrl.trim(),
      'rejectionReason': '',
      'createdAt': FieldValue.serverTimestamp(),
      'reviewedAt': null,
      'startsAt': null,
      'expiresAt': null,
    });

    return reference.id;
  }

  Future<VerificationRequest?>
      getMyLatestRequest() async {
    final uid = _uid;

    final snapshot = await _verificationCollection
        .where(
          'userId',
          isEqualTo: uid,
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return VerificationRequest.fromFirestore(
      snapshot.docs.first,
    );
  }

  Stream<VerificationRequest?>
      watchMyLatestRequest() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream<VerificationRequest?>.value(null);
    }

    return _verificationCollection
        .where(
          'userId',
          isEqualTo: user.uid,
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }

      return VerificationRequest.fromFirestore(
        snapshot.docs.first,
      );
    });
  }

  Stream<bool> watchMyVerificationStatus() {
    return watchMyLatestRequest().map((request) {
      return request?.isCurrentlyVerified ?? false;
    });
  }

  Future<void> approveRequest({
    required String requestId,
  }) async {
    if (requestId.isEmpty) {
      throw ArgumentError(
        'Verification request ID is required.',
      );
    }

    final reference =
        _verificationCollection.doc(requestId);

    final snapshot = await reference.get();

    if (!snapshot.exists) {
      throw StateError(
        'Verification request not found.',
      );
    }

    final request =
        VerificationRequest.fromFirestore(snapshot);

    final now = DateTime.now();

    final expiresAt = DateTime(
      now.year,
      now.month + request.durationMonths,
      now.day,
      now.hour,
      now.minute,
      now.second,
      now.millisecond,
      now.microsecond,
    );

    await reference.update({
      'status': 'Approved',
      'reviewedAt': FieldValue.serverTimestamp(),
      'startsAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'rejectionReason': '',
    });
  }

  Future<void> rejectRequest({
    required String requestId,
    String reason = '',
  }) async {
    if (requestId.isEmpty) {
      throw ArgumentError(
        'Verification request ID is required.',
      );
    }

    await _verificationCollection
        .doc(requestId)
        .update({
      'status': 'Rejected',
      'reviewedAt': FieldValue.serverTimestamp(),
      'rejectionReason': reason.trim(),
    });
  }

  Future<void> markExpired(
    String requestId,
  ) async {
    if (requestId.isEmpty) {
      return;
    }

    final reference =
        _verificationCollection.doc(requestId);

    final snapshot = await reference.get();

    if (!snapshot.exists) {
      return;
    }

    final request =
        VerificationRequest.fromFirestore(snapshot);

    if (!request.isApproved ||
        request.expiresAt == null ||
        !request.expiresAt!.isBefore(DateTime.now())) {
      return;
    }

    await reference.update({
      'status': 'Expired',
    });
  }
}
