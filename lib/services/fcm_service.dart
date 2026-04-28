import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ets/services/notification_service.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  
  factory FCMService() {
    return _instance;
  }
  
  FCMService._internal();
  
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  Future<void> initFCM() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('🔔 FCM Permission: ${settings.authorizationStatus}');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Foreground message received!');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      
      _handleNotification(message);
    });

    // Handle background messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📭 Message opened from background!');
      _handleNotification(message);
    });

    // Handle message that opened app from terminated state
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('📨 App opened from terminated by notification');
      _handleNotification(initialMessage);
    }

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    print('🔑 FCM Token: $token');
  }

  void _handleNotification(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      NotificationService().addNotificationRecord(
        title: notification.title ?? 'Notifikasi Baru',
        body: notification.body ?? '-',
        type: 'push',
      );

      _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'default_notification_channel',
            'Default Notifications',
            channelDescription: 'Notifikasi dari Firebase',
            icon: android?.smallIcon,
          ),
        ),
      );
    }
  }
}
