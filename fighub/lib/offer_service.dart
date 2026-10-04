import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';
import 'offer_model.dart';

class OfferService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final NotificationService _notificationService =
      NotificationService();

  CollectionReference<Map<String, dynamic>> get _offers {
    return _firestore.collection('offers');
  }

  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User must be signed in.');
    }

    return user.uid;
  }

  Future<String> createOffer(Offer offer) async {
    final uid = _uid;

    final offerData = offer.toFirestore();
    offerData['sellerId'] = uid;

    final reference = await _offers.add(offerData);

    return reference.id;
  }

  Future<String> addOfferItem({
    required String offerId,
    required OfferItem item,
  }) async {
    final uid = _uid;

    if (offerId.isEmpty) {
      throw ArgumentError('Offer ID is required.');
    }

    final offerReference = _offers.doc(offerId);
    final offerSnapshot = await offerReference.get();

    if (!offerSnapshot.exists) {
      throw StateError('Offer not found.');
    }

    final offerData = offerSnapshot.data() ?? {};

    if (offerData['sellerId'] != uid) {
      throw StateError(
        'You can only add items to your own offers.',
      );
    }

    final itemReference =
        offerReference.collection('items').doc();

    await itemReference.set(item.toFirestore());

    return itemReference.id;
  }

  Stream<List<Offer>> watchOffers() {
    return _offers
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(Offer.fromFirestore)
              .toList(),
        );
  }

  Stream<List<OfferItem>> watchOfferItems(
    String offerId,
  ) {
    if (offerId.isEmpty) {
      return Stream.value(
        const <OfferItem>[],
      );
    }

    return _offers
        .doc(offerId)
        .collection('items')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(OfferItem.fromFirestore)
              .toList(),
        );
  }

  Future<void> reserveItem({
    required String offerId,
    required String itemId,
  }) async {
    final uid = _uid;

    if (offerId.isEmpty || itemId.isEmpty) {
      throw ArgumentError(
        'Offer ID and item ID are required.',
      );
    }

    final itemReference = _offers
        .doc(offerId)
        .collection('items')
        .doc(itemId);

    final reservationReference = itemReference
        .collection('reservations')
        .doc(uid);

    await _firestore.runTransaction(
      (transaction) async {
        final itemSnapshot =
            await transaction.get(itemReference);

        if (!itemSnapshot.exists) {
          throw StateError('Offer item not found.');
        }

        final itemData =
            itemSnapshot.data() ?? {};

        final currentStatus =
            itemData['status'] as String? ?? 'Available';

        final currentReservedBy =
            itemData['reservedBy'] as String?;

        if (currentStatus != 'Available' ||
            (currentReservedBy != null &&
                currentReservedBy.isNotEmpty)) {
          throw StateError(
            'This item has already been reserved.',
          );
        }

        transaction.set(
          reservationReference,
          {
            'userId': uid,
            'offerId': offerId,
            'itemId': itemId,
            'status': 'Active',
            'createdAt':
                FieldValue.serverTimestamp(),
            'cancelledAt': null,
          },
        );

        transaction.update(
          itemReference,
          {
            'status': 'Reserved',
            'reservedBy': uid,
            'reservedAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );

    final offerSnapshot =
        await _offers.doc(offerId).get();

    final sellerId =
        offerSnapshot.data()?['sellerId'] as String?;

    if (sellerId != null &&
        sellerId.isNotEmpty &&
        sellerId != uid) {
      await _notificationService.addNotification(
        userId: sellerId,
        title: 'حجز جديد',
        message: 'تم حجز قطعة من العرض الخاص بك.',
      );
    }
  }

  Stream<List<Map<String, dynamic>>> watchItemReservations({
    required String offerId,
    required String itemId,
  }) {
    return _offers
        .doc(offerId)
        .collection('items')
        .doc(itemId)
        .collection('reservations')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => {
                  'id': doc.id,
                  ...doc.data(),
                },
              )
              .toList(),
        );
  }

  Stream<Map<String, dynamic>?> watchReservation({
    required String offerId,
    required String itemId,
    required String userId,
  }) {
    return _offers
        .doc(offerId)
        .collection('items')
        .doc(itemId)
        .collection('reservations')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.exists ? snapshot.data() : null);
  }

  Future<void> cancelReservation({
    required String offerId,
    required String itemId,
  }) async {
    final uid = _uid;

    final itemReference = _offers
        .doc(offerId)
        .collection('items')
        .doc(itemId);

    final reservationReference =
        itemReference.collection('reservations').doc(uid);

    await _firestore.runTransaction(
      (transaction) async {
        final itemSnapshot =
            await transaction.get(itemReference);

        final reservationSnapshot =
            await transaction.get(reservationReference);

        if (!itemSnapshot.exists) {
          throw StateError('Offer item not found.');
        }

        if (!reservationSnapshot.exists) {
          throw StateError('Reservation not found.');
        }

        final itemData =
            itemSnapshot.data() ?? {};

        final reservationData =
            reservationSnapshot.data() ?? {};

        if (itemData['reservedBy'] != uid) {
          throw StateError(
            'You do not own the current reservation.',
          );
        }

        if (reservationData['status'] != 'Active') {
          throw StateError(
            'Reservation is no longer active.',
          );
        }

        transaction.update(
          reservationReference,
          {
            'status': 'Cancelled',
            'cancelledAt':
                FieldValue.serverTimestamp(),
          },
        );

        transaction.update(
          itemReference,
          {
            'status': 'Available',
            'reservedBy': null,
            'reservedAt': null,
          },
        );
      },
    );
  }
}
