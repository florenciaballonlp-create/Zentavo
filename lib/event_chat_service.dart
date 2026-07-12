import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

const bool kUseFirebaseEventChats = bool.fromEnvironment(
  'USE_FIREBASE_EVENT_CHATS',
  defaultValue: true,
);

class EventChatService {
  static const String _collection = 'event_chats';

  bool get _enabled => kUseFirebaseEventChats && Firebase.apps.isNotEmpty;

  Stream<QuerySnapshot<Map<String, dynamic>>> streamChatsForUser(String userId) {
    if (!_enabled) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection(_collection)
        .where('memberIds', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMessages(String eventId) {
    if (!_enabled) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection(_collection)
        .doc(eventId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  Future<void> ensureChat({
    required String eventId,
    required String eventName,
    required List<String> memberIds,
  }) async {
    if (!_enabled) return;

    await FirebaseFirestore.instance.collection(_collection).doc(eventId).set({
      'eventId': eventId,
      'eventName': eventName,
      'memberIds': memberIds,
      'lastReadAt': {},
      'unreadCountByUser': {
        for (final memberId in memberIds) memberId: 0,
      },
      'lastMessageText': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageSenderId': '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> sendMessage({
    required String eventId,
    required String senderId,
    required String text,
  }) async {
    if (!_enabled) return;

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final chatRef = FirebaseFirestore.instance.collection(_collection).doc(eventId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final chatSnapshot = await tx.get(chatRef);
      final data = chatSnapshot.data() ?? <String, dynamic>{};
      final members = List<String>.from(data['memberIds'] ?? const <String>[]);
      final unread = Map<String, dynamic>.from(data['unreadCountByUser'] ?? const {});

      for (final member in members) {
        final current = (unread[member] ?? 0) as num;
        if (member == senderId) {
          unread[member] = 0;
        } else {
          unread[member] = current.toInt() + 1;
        }
      }

      final messageRef = chatRef.collection('messages').doc();
      tx.set(messageRef, {
        'senderId': senderId,
        'text': trimmed,
        'type': 'text',
        'deletedForAll': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.set(chatRef, {
        'unreadCountByUser': unread,
        'lastMessageText': trimmed,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> markEventChatAsRead({
    required String eventId,
    required String userId,
  }) async {
    if (!_enabled) return;

    await FirebaseFirestore.instance.collection(_collection).doc(eventId).set({
      'lastReadAt': {
        userId: FieldValue.serverTimestamp(),
      },
      'unreadCountByUser': {
        userId: 0,
      },
    }, SetOptions(merge: true));
  }
}
