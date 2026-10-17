import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'interests.dart';
import 'offer_model.dart';
import 'chat_service.dart';

class OfferService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      throw StateError('You can only add items to your own offers.');
    }

    final itemReference = offerReference.collection('items').doc();

    await itemReference.set(item.toFirestore());

    return itemReference.id;
  }

  Future<void> deleteOffer(String offerId) async {
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
      throw StateError('You can only delete your own offers.');
    }

    final itemsSnapshot = await offerReference.collection('items').get();

    if (itemsSnapshot.docs.isEmpty) {
      throw StateError('Add at least one item before deleting the offer.');
    }

    for (final item in itemsSnapshot.docs) {
      final reservationsSnapshot = await item.reference
          .collection('reservations')
          .get();

      final hasActiveReservation = reservationsSnapshot.docs.any((reservation) {
        final data = reservation.data();
        return data['status'] == 'Active';
      });

      if (hasActiveReservation) {
        throw StateError(
          'This offer has an active reservation and cannot be deleted.',
        );
      }
    }

    final batch = _firestore.batch();

    for (final item in itemsSnapshot.docs) {
      final reservationsSnapshot = await item.reference
          .collection('reservations')
          .get();

      for (final reservation in reservationsSnapshot.docs) {
        batch.delete(reservation.reference);
      }

      batch.delete(item.reference);
    }

    batch.delete(offerReference);

    await batch.commit();
  }

  Stream<List<Offer>> watchOffers() {
    return _offers
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Offer.fromFirestore).toList());
  }

  Stream<List<Offer>> watchRecommendedOffers(List<String> interests) {
    final normalizedInterests = interests
        .map((interest) => interest.trim())
        .where((interest) => interest.isNotEmpty)
        .toList();

    if (normalizedInterests.isEmpty) {
      return Stream.value(const <Offer>[]);
    }

    return watchOffers().asyncMap((offers) async {
      final recommended = <Offer>[];

      for (final offer in offers) {
        if (offer.id == null || offer.id!.isEmpty) {
          continue;
        }

        final items = await watchOfferItems(offer.id!).first;

        final hasMatch = items.any((item) {
          return normalizedInterests.any((interest) {
            return FigHubInterests.matchesInterest(
              interest: interest,
              category: item.category,
            );
          });
        });

        if (hasMatch) {
          recommended.add(offer);
        }
      }

      return recommended;
    });
  }

  Stream<Offer?> watchOffer(String offerId) {
    if (offerId.isEmpty) {
      return Stream.value(null);
    }

    return _offers
        .doc(offerId)
        .snapshots()
        .map(
          (snapshot) => snapshot.exists ? Offer.fromFirestore(snapshot) : null,
        );
  }

  Stream<List<OfferItem>> watchOfferItems(String offerId) {
    if (offerId.isEmpty) {
      return Stream.value(const <OfferItem>[]);
    }

    return _offers
        .doc(offerId)
        .collection('items')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(OfferItem.fromFirestore).toList());
  }

  Future<void> _syncReservedOfferItem({
    required String offerId,
    required String itemId,
    required String buyerId,
  }) async {
    try {
      final offerSnapshot = await _offers.doc(offerId).get();
      final itemSnapshot = await _offers
          .doc(offerId)
          .collection('items')
          .doc(itemId)
          .get();

      if (!offerSnapshot.exists || !itemSnapshot.exists) return;

      final offerData = offerSnapshot.data() ?? {};
      final itemData = itemSnapshot.data() ?? {};
      final sellerId = offerData['sellerId'] as String? ?? '';
      if (sellerId.isEmpty || sellerId == buyerId) return;

      final imagesRaw = itemData['imagePaths'];
      final images = imagesRaw is List
          ? imagesRaw.whereType<String>().toList()
          : <String>[];

      await ChatService().addReservedOfferItemToChat(
        offerId: offerId,
        itemId: itemId,
        itemName: itemData['name'] as String? ?? 'قطعة من العرض',
        price: itemData['price']?.toString() ?? '0',
        imagePaths: images,
        sellerId: sellerId,
      );
    } catch (error, stackTrace) {
      debugPrint('FIGHUB OFFER CHAT SYNC ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> reserveItem({
    required String offerId,
    required String itemId,
  }) async {
    final uid = _uid;

    if (offerId.isEmpty || itemId.isEmpty) {
      throw ArgumentError('Offer ID and item ID are required.');
    }

    final itemReference = _offers.doc(offerId).collection('items').doc(itemId);

    final reservationReference = itemReference
        .collection('reservations')
        .doc(uid);

    await _firestore.runTransaction((transaction) async {
      final itemSnapshot = await transaction.get(itemReference);

      if (!itemSnapshot.exists) {
        throw StateError('Offer item not found.');
      }

      final itemData = itemSnapshot.data() ?? {};

      final currentStatus = itemData['status'] as String? ?? 'Available';

      final currentReservedBy = itemData['reservedBy'] as String?;

      final rawWaitingUsers = itemData['waitingUsers'];

      final waitingUsers = rawWaitingUsers is List
          ? rawWaitingUsers.whereType<String>().toList()
          : <String>[];

      if (currentStatus != 'Available' ||
          (currentReservedBy != null && currentReservedBy.isNotEmpty)) {
        if (waitingUsers.contains(uid)) {
          throw StateError('You are already in the waiting list.');
        }

        transaction.set(reservationReference, {
          'userId': uid,
          'offerId': offerId,
          'itemId': itemId,
          'status': 'Waiting',
          'createdAt': FieldValue.serverTimestamp(),
          'cancelledAt': null,
        });

        transaction.update(itemReference, {
          'waitingUsers': [...waitingUsers, uid],
        });

        return;
      }

      transaction.set(reservationReference, {
        'userId': uid,
        'offerId': offerId,
        'itemId': itemId,
        'status': 'Active',
        'createdAt': FieldValue.serverTimestamp(),
        'cancelledAt': null,
      });

      transaction.update(itemReference, {
        'status': 'Reserved',
        'reservedBy': uid,
        'reservedAt': FieldValue.serverTimestamp(),
        'waitingUsers': waitingUsers,
      });
    });

    final reservationSnapshot = await reservationReference.get();
    if (reservationSnapshot.data()?['status'] == 'Active') {
      await _syncReservedOfferItem(
        offerId: offerId,
        itemId: itemId,
        buyerId: uid,
      );
    }
  }

  Future<void> claimWaitingReservation({
    required String offerId,
    required String itemId,
  }) async {
    final uid = _uid;

    if (offerId.isEmpty || itemId.isEmpty) {
      throw ArgumentError('Offer ID and item ID are required.');
    }

    final itemReference = _offers.doc(offerId).collection('items').doc(itemId);

    final reservationReference = itemReference
        .collection('reservations')
        .doc(uid);

    await _firestore.runTransaction((transaction) async {
      final itemSnapshot = await transaction.get(itemReference);

      final reservationSnapshot = await transaction.get(reservationReference);

      if (!itemSnapshot.exists) {
        throw StateError('Offer item not found.');
      }

      if (!reservationSnapshot.exists) {
        throw StateError('Waiting reservation not found.');
      }

      final itemData = itemSnapshot.data() ?? {};

      final reservationData = reservationSnapshot.data() ?? {};

      final rawWaitingUsers = itemData['waitingUsers'];

      final waitingUsers = rawWaitingUsers is List
          ? rawWaitingUsers.whereType<String>().toList()
          : <String>[];

      final currentStatus = itemData['status'] as String? ?? 'Available';

      final currentReservedBy = itemData['reservedBy'] as String?;

      if (reservationData['status'] != 'Waiting') {
        throw StateError('Reservation is not waiting.');
      }

      if (currentStatus != 'Available' ||
          (currentReservedBy != null && currentReservedBy.isNotEmpty)) {
        throw StateError('This item is not available yet.');
      }

      if (waitingUsers.isEmpty || waitingUsers.first != uid) {
        throw StateError('You are not first in the waiting list.');
      }

      transaction.update(reservationReference, {
        'status': 'Active',
        'cancelledAt': null,
      });

      transaction.update(itemReference, {
        'status': 'Reserved',
        'reservedBy': uid,
        'reservedAt': FieldValue.serverTimestamp(),
        'waitingUsers': waitingUsers.sublist(1),
      });
    });

    await _syncReservedOfferItem(
      offerId: offerId,
      itemId: itemId,
      buyerId: uid,
    );
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
              .map((doc) => {'id': doc.id, ...doc.data()})
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

    final itemReference = _offers.doc(offerId).collection('items').doc(itemId);

    final reservationReference = itemReference
        .collection('reservations')
        .doc(uid);

    await _firestore.runTransaction((transaction) async {
      final itemSnapshot = await transaction.get(itemReference);

      final reservationSnapshot = await transaction.get(reservationReference);

      if (!itemSnapshot.exists) {
        throw StateError('Offer item not found.');
      }

      if (!reservationSnapshot.exists) {
        throw StateError('Reservation not found.');
      }

      final itemData = itemSnapshot.data() ?? {};

      final reservationData = reservationSnapshot.data() ?? {};

      if (itemData['reservedBy'] != uid) {
        throw StateError('You do not own the current reservation.');
      }

      if (reservationData['status'] != 'Active') {
        throw StateError('Reservation is no longer active.');
      }

      transaction.update(reservationReference, {
        'status': 'Cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      final rawWaitingUsers = itemData['waitingUsers'];

      final waitingUsers = rawWaitingUsers is List
          ? rawWaitingUsers.whereType<String>().toList()
          : <String>[];

      transaction.update(itemReference, {
        'status': 'Available',
        'reservedBy': null,
        'reservedAt': null,
        'waitingUsers': waitingUsers,
      });
    });

    try {
      final offerSnapshot = await _offers.doc(offerId).get();
      final sellerId = offerSnapshot.data()?['sellerId'] as String? ?? '';
      if (sellerId.isNotEmpty && sellerId != uid) {
        await ChatService().removeReservedOfferItemFromChat(
          offerId: offerId,
          itemId: itemId,
          sellerId: sellerId,
        );
      }
    } catch (error, stackTrace) {
      debugPrint('FIGHUB OFFER CHAT CANCEL SYNC ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  bool isOfferActive(Offer offer) {
    final scheduledAt = offer.scheduledAt;

    if (scheduledAt == null) {
      return true;
    }

    return !DateTime.now().isBefore(scheduledAt);
  }
}
