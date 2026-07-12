import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

const bool kUseFirebaseDirectChats = bool.fromEnvironment(
  'USE_FIREBASE_DIRECT_CHATS',
  defaultValue: true,
);

class DirectChatService {
  static const String _collection = 'direct_chats';

  bool get _enabled => kUseFirebaseDirectChats && Firebase.apps.isNotEmpty;

  String buildChatId(String userA, String userB) {
    final ordered = [userA, userB]..sort();
    return '${ordered[0]}__${ordered[1]}';
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamChatsForUser(String userId) {
    if (!_enabled) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection(_collection)
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMessages(String chatId) {
    if (!_enabled) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection(_collection)
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  Future<String?> getOrCreateChat({
    required String currentUserId,
    required String currentUserName,
    required String otherUserId,
    required String otherUserName,
  }) async {
    if (!_enabled) return null;

    final chatId = buildChatId(currentUserId, otherUserId);
    final ref = FirebaseFirestore.instance.collection(_collection).doc(chatId);

    await ref.set({
      'participants': [currentUserId, otherUserId],
      'participantNames': {
        currentUserId: currentUserName,
        otherUserId: otherUserName,
      },
      'lastReadAt': {
        currentUserId: FieldValue.serverTimestamp(),
      },
      'unreadCountByUser': {
        currentUserId: 0,
        otherUserId: 0,
      },
      'lastMessageText': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageSenderId': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return chatId;
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    if (!_enabled) return;

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final chatRef = FirebaseFirestore.instance.collection(_collection).doc(chatId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final chatSnapshot = await tx.get(chatRef);
      final data = chatSnapshot.data() ?? <String, dynamic>{};
      final participants = List<String>.from(data['participants'] ?? const <String>[]);
      final unread = Map<String, dynamic>.from(data['unreadCountByUser'] ?? const {});

      for (final participant in participants) {
        final current = (unread[participant] ?? 0) as num;
        if (participant == senderId) {
          unread[participant] = 0;
        } else {
          unread[participant] = current.toInt() + 1;
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

  Future<void> markChatAsRead({
    required String chatId,
    required String userId,
  }) async {
    if (!_enabled) return;

    await FirebaseFirestore.instance.collection(_collection).doc(chatId).set({
      'lastReadAt': {
        userId: FieldValue.serverTimestamp(),
      },
      'unreadCountByUser': {
        userId: 0,
      },
    }, SetOptions(merge: true));
  }
}
