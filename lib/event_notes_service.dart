import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

const bool kUseFirebaseEventNotes = bool.fromEnvironment(
  'USE_FIREBASE_EVENT_NOTES',
  defaultValue: true,
);

class EventNotesService {
  static const String _collection = 'event_notes';

  bool get _enabled => kUseFirebaseEventNotes && Firebase.apps.isNotEmpty;

  Stream<QuerySnapshot<Map<String, dynamic>>> streamThreadsForUser(String userId) {
    if (!_enabled) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection(_collection)
        .where('memberIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamPosts(String eventId) {
    if (!_enabled) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection(_collection)
        .doc(eventId)
        .collection('posts')
        .orderBy('pinned', descending: true)
        .orderBy('updatedAt', descending: true)
        .limit(100)
        .snapshots();
  }

  Future<void> ensureThread({
    required String eventId,
    required String eventName,
    required List<String> memberIds,
  }) async {
    if (!_enabled) return;

    await FirebaseFirestore.instance.collection(_collection).doc(eventId).set({
      'eventId': eventId,
      'eventName': eventName,
      'memberIds': memberIds,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addPost({
    required String eventId,
    required String authorId,
    required String title,
    required String body,
  }) async {
    if (!_enabled) return;

    final normalizedTitle = title.trim();
    final normalizedBody = body.trim();
    if (normalizedTitle.isEmpty || normalizedBody.isEmpty) return;

    final threadRef = FirebaseFirestore.instance.collection(_collection).doc(eventId);
    final postRef = threadRef.collection('posts').doc();

    final batch = FirebaseFirestore.instance.batch();

    batch.set(postRef, {
      'authorId': authorId,
      'title': normalizedTitle,
      'body': normalizedBody,
      'pinned': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(threadRef, {
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> updatePost({
    required String eventId,
    required String postId,
    required String title,
    required String body,
  }) async {
    if (!_enabled) return;

    final normalizedTitle = title.trim();
    final normalizedBody = body.trim();
    if (normalizedTitle.isEmpty || normalizedBody.isEmpty) return;

    await FirebaseFirestore.instance
        .collection(_collection)
        .doc(eventId)
        .collection('posts')
        .doc(postId)
        .set({
      'title': normalizedTitle,
      'body': normalizedBody,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> togglePinned({
    required String eventId,
    required String postId,
    required bool pinned,
  }) async {
    if (!_enabled) return;

    await FirebaseFirestore.instance
        .collection(_collection)
        .doc(eventId)
        .collection('posts')
        .doc(postId)
        .set({
      'pinned': pinned,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
