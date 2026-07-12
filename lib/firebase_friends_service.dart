import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

const bool kUseFirebaseFriendsSync = bool.fromEnvironment(
  'USE_FIREBASE_FRIENDS_SYNC',
  defaultValue: true,
);

class FirebaseFriendsService {
  static const String _friendshipsCollection = 'friendships';
  static const String _usersCollection = 'users';

  bool get _enabled => kUseFirebaseFriendsSync && Firebase.apps.isNotEmpty;

  bool get isEnabled => _enabled;

  String _friendshipDocId(String userA, String userB) {
    final ordered = [userA, userB]..sort();
    return '${ordered[0]}__${ordered[1]}';
  }

  Future<bool> upsertUserProfile({
    required String userId,
    required String displayName,
  }) async {
    if (!_enabled) return false;

    await FirebaseFirestore.instance.collection(_usersCollection).doc(userId).set({
      'displayName': displayName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return true;
  }

  Future<bool> createMutualFriendship({
    required String userAId,
    required String userAName,
    required String userBId,
    required String userBName,
  }) async {
    if (!_enabled) return false;

    final String docId = _friendshipDocId(userAId, userBId);

    await FirebaseFirestore.instance
        .collection(_friendshipsCollection)
        .doc(docId)
        .set({
      'users': [userAId, userBId],
      'names': {
        userAId: userAName,
        userBId: userBName,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return true;
  }

  Future<List<Map<String, dynamic>>> fetchFriendsForUser(String userId) async {
    if (!_enabled) return <Map<String, dynamic>>[];

    final snapshot = await FirebaseFirestore.instance
        .collection(_friendshipsCollection)
        .where('users', arrayContains: userId)
        .get();

    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          final users = List<String>.from(data['users'] ?? const <String>[]);
          final namesMap = Map<String, dynamic>.from(data['names'] ?? const {});

          final otherUserId = users.firstWhere(
            (id) => id != userId,
            orElse: () => '',
          );

          if (otherUserId.isEmpty) return null;

          final connectedAt = data['updatedAt'];
          final isoDate = connectedAt is Timestamp
              ? connectedAt.toDate().toIso8601String()
              : DateTime.now().toIso8601String();

          return {
            'userId': otherUserId,
            'nombre': (namesMap[otherUserId] ?? '').toString(),
            'fechaAgregado': isoDate,
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }
}
