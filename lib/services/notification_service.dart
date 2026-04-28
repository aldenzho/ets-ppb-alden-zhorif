import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';

class AppNotificationItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppNotificationItem.fromMap(Map<String, dynamic> map) {
    return AppNotificationItem(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      body: (map['body'] ?? '').toString(),
      type: (map['type'] ?? 'info').toString(),
      createdAt: DateTime.tryParse((map['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();
  
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final ValueNotifier<List<AppNotificationItem>> notificationsNotifier =
      ValueNotifier<List<AppNotificationItem>>(<AppNotificationItem>[]);

  Future<File> _historyFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/notifications_history.json');
  }

  Future<void> _loadHistory() async {
    try {
      final file = await _historyFile();
      if (!await file.exists()) {
        notificationsNotifier.value = <AppNotificationItem>[];
        return;
      }

      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        notificationsNotifier.value = <AppNotificationItem>[];
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        notificationsNotifier.value = <AppNotificationItem>[];
        return;
      }

      final items = decoded
          .whereType<Map>()
          .map((m) => AppNotificationItem.fromMap(Map<String, dynamic>.from(m)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      notificationsNotifier.value = items;
    } catch (_) {
      notificationsNotifier.value = <AppNotificationItem>[];
    }
  }

  Future<void> _saveHistory() async {
    try {
      final file = await _historyFile();
      final encoded = jsonEncode(
        notificationsNotifier.value.map((n) => n.toMap()).toList(),
      );
      await file.writeAsString(encoded, flush: true);
    } catch (_) {
      // Ignore persistence errors to avoid breaking notification flow.
    }
  }

  Future<void> addNotificationRecord({
    required String title,
    required String body,
    required String type,
  }) async {
    final current = List<AppNotificationItem>.from(notificationsNotifier.value);
    current.insert(
      0,
      AppNotificationItem(
        id: '${DateTime.now().microsecondsSinceEpoch}_${current.length}',
        title: title,
        body: body,
        type: type,
        createdAt: DateTime.now(),
      ),
    );

    notificationsNotifier.value = current;
    await _saveHistory();
  }

  Future<void> deleteNotification(String id) async {
    final current = List<AppNotificationItem>.from(notificationsNotifier.value)
      ..removeWhere((n) => n.id == id);
    notificationsNotifier.value = current;
    await _saveHistory();
  }

  Future<void> clearAllNotifications() async {
    notificationsNotifier.value = <AppNotificationItem>[];
    await _saveHistory();
  }
  
  Future<void> initNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notificationsPlugin.initialize(initSettings);
    await _loadHistory();
  }
  
  // Show upload progress notification
  Future<void> showUploadProgressNotification(int progress) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'upload_progress_channel',
      'Upload Progress',
      channelDescription: 'Notifikasi progress upload foto',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      enableVibration: false,
      playSound: false,
      indeterminate: false,
    );
    
    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );
    
    await _notificationsPlugin.show(
      1,
      'Mengupload Foto',
      'Progress: $progress%',
      details,
      payload: 'upload_progress',
    );
  }
  
  // Show upload success notification
  Future<void> showUploadSuccessNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'upload_complete_channel',
      'Upload Complete',
      channelDescription: 'Notifikasi selesai upload foto',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin.show(
      2,
      'Upload Berhasil!',
      'Foto telah berhasil diupload ke database',
      details,
      payload: 'upload_success',
    );

    await addNotificationRecord(
      title: 'Upload Berhasil!',
      body: 'Foto telah berhasil diupload ke database',
      type: 'success',
    );
  }
  
  // Show upload error notification
  Future<void> showUploadErrorNotification(String error) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'upload_error_channel',
      'Upload Error',
      channelDescription: 'Notifikasi error upload foto',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notificationsPlugin.show(
      3,
      'Upload Gagal',
      'Error: $error',
      details,
      payload: 'upload_error',
    );

    await addNotificationRecord(
      title: 'Upload Gagal',
      body: 'Error: $error',
      type: 'error',
    );
  }
  
  // Dismiss upload notification
  Future<void> dismissUploadNotification() async {
    await _notificationsPlugin.cancel(1);
  }
}
