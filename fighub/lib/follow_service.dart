import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';

class FollowService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final NotificationService _notificationService =
      NotificationService();

  CollectionReference<Map<String, dynamic>>
      get _followingCollection {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User must be signed in.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('following');
  }

  CollectionReference<Map<String, dynamic>>
      _followersCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('followers');
  }

  Future<bool> isFollowing(String targetUserId) async {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    if (targetUserId.isEmpty ||
        targetUserId == user.uid) {
      return false;
    }

    final document =
        await _followingCollection
            .doc(targetUserId)
            .get();

    return document.exists;
  }

  Stream<bool> watchIsFollowing(
    String targetUserId,
  ) {
    final user = _auth.currentUser;

    if (user == null ||
        targetUserId.isEmpty ||
        targetUserId == user.uid) {
      return Stream<bool>.value(false);
    }

    return _followingCollection
        .doc(targetUserId)
        .snapshots()
        .map((document) => document.exists);
  }

  Future<void> followUser(
    String targetUserId,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User must be signed in.');
    }

    if (targetUserId.isEmpty) {
      throw ArgumentError(
        'Target user ID is required.',
      );
    }

    if (targetUserId == user.uid) {
      throw StateError(
        'You cannot follow yourself.',
      );
    }

    final followingReference =
        _followingCollection.doc(targetUserId);

    final followerReference =
        _followersCollection(targetUserId)
            .doc(user.uid);

    final alreadyFollowing =
        await followingReference.get();

    if (alreadyFollowing.exists) {
      return;
    }

    final batch = _firestore.batch();

    batch.set(
      followingReference,
      {
        'userId': targetUserId,
        'createdAt':
            FieldValue.serverTimestamp(),
      },
    );

    batch.set(
      followerReference,
      {
        'userId': user.uid,
        'createdAt':
            FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();

    final followerName =
        user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : 'Someone';

    await _notificationService.addNotification(
      userId: targetUserId,
      title: 'New follower',
      message: '$followerName started following you.',
    );
  }

  Future<void> unfollowUser(
    String targetUserId,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User must be signed in.');
    }

    if (targetUserId.isEmpty) {
      throw ArgumentError(
        'Target user ID is required.',
      );
    }

    if (targetUserId == user.uid) {
      throw StateError(
        'You cannot unfollow yourself.',
      );
    }

    final followingReference =
        _followingCollection.doc(targetUserId);

    final followerReference =
        _followersCollection(targetUserId)
            .doc(user.uid);

    final batch = _firestore.batch();

    batch.delete(followingReference);
    batch.delete(followerReference);

    await batch.commit();
  }

  Stream<List<String>> watchFollowerIds(
    String userId,
  ) {
    if (userId.isEmpty) {
      return Stream<List<String>>.value(const []);
    }

    return _followersCollection(userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((document) => document.id)
          .toList();
    });
  }

  Stream<List<String>> watchFollowingIds(
    String userId,
  ) {
    if (userId.isEmpty) {
      return Stream<List<String>>.value(const []);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((document) => document.id)
          .toList();
    });
  }

  Stream<int> watchFollowersCount(
    String userId,
  ) {
    if (userId.isEmpty) {
      return Stream<int>.value(0);
    }

    return _followersCollection(userId)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Stream<int> watchFollowingCount(
    String userId,
  ) {
    if (userId.isEmpty) {
      return Stream<int>.value(0);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }
}
