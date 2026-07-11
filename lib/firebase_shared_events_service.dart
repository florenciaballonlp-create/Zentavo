import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

const bool kUseFirebaseSharedEvents = bool.fromEnvironment(
  'USE_FIREBASE_SHARED_EVENTS',
  defaultValue: false,
);

class FirebaseSharedEventsService {
  static const String _collection = 'shared_events';

  Future<void> publishEvent({
    required String code,
    required Map<String, dynamic> eventData,
  }) async {
    if (!kUseFirebaseSharedEvents) return;
    if (Firebase.apps.isEmpty) return;

    await FirebaseFirestore.instance.collection(_collection).doc(code).set({
      'code': code,
      'event': eventData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> fetchEventByCode(String code) async {
    if (!kUseFirebaseSharedEvents) return null;
    if (Firebase.apps.isEmpty) return null;

    final doc =
        await FirebaseFirestore.instance.collection(_collection).doc(code).get();
    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null) return null;

    final event = data['event'];
    if (event is Map<String, dynamic>) {
      return event;
    }

    return null;
  }

  Future<void> deleteEventByCode(String code) async {
    if (!kUseFirebaseSharedEvents) return;
    if (Firebase.apps.isEmpty) return;

    await FirebaseFirestore.instance.collection(_collection).doc(code).delete();
  }
}
