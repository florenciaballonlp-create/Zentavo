import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const bool kUseFirebasePushMessaging = bool.fromEnvironment(
  'USE_FIREBASE_PUSH_MESSAGING',
  defaultValue: true,
);

class PushMessagingService {
  static final PushMessagingService _instance = PushMessagingService._internal();
  factory PushMessagingService() => _instance;
  PushMessagingService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
    final StreamController<Map<String, dynamic>> _notificationTapController =
      StreamController<Map<String, dynamic>>.broadcast();

  bool _initialized = false;

  bool get _enabled => kUseFirebasePushMessaging && Firebase.apps.isNotEmpty;
    Stream<Map<String, dynamic>> get notificationTapStream =>
      _notificationTapController.stream;

  Future<void> initialize({
    required String userId,
    required String displayName,
  }) async {
    if (_initialized || !_enabled || userId.isEmpty) return;

    await _initializeLocalNotifications();

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await messaging.getToken();
    if (token != null) {
      await _storeToken(userId: userId, displayName: displayName, token: token);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _storeToken(userId: userId, displayName: displayName, token: newToken);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await _showForegroundNotification(message);
    });

    _initialized = true;
  }

  Future<void> _initializeLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.trim().isEmpty) return;
        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) {
            _notificationTapController.add(decoded);
          }
        } catch (_) {
          // Ignorar payload inválido.
        }
      },
    );

    const channel = AndroidNotificationChannel(
      'messages_channel',
      'Mensajes',
      description: 'Notificaciones de nuevos mensajes y actividad social',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _storeToken({
    required String userId,
    required String displayName,
    required String token,
  }) async {
    if (!_enabled) return;

    final platform = kIsWeb
        ? 'web'
        : Platform.isIOS
            ? 'ios'
            : Platform.isAndroid
                ? 'android'
                : 'other';

    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'displayName': displayName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('devices')
        .doc(token)
        .set({
      'token': token,
      'platform': platform,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? 'Nuevo mensaje';
    final body = message.notification?.body ?? 'Tienes actividad en Zentavo';

    const androidDetails = AndroidNotificationDetails(
      'messages_channel',
      'Mensajes',
      channelDescription: 'Notificaciones de nuevos mensajes y actividad social',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(message.data),
    );
  }
}
