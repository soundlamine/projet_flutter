import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // ================= SINGLETON =================
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ================= INITIALISATION =================
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Android
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('📩 Notification cliquée: ${response.payload}');
        },
      );

      // Important pour zonedSchedule
      tz.initializeTimeZones();

      _initialized = true;
      debugPrint(' NotificationService initialisé');
    } catch (e) {
      debugPrint(' Erreur initialisation NotificationService: $e');
    }
  }

  // ================= PROGRAMMER NOTIFICATION =================
  Future<void> scheduleMealNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    required int id,
    String? payload,
  }) async {
    try {
      await initialize();

      if (scheduledDate.isBefore(DateTime.now())) {
        debugPrint(' Date passée, notification annulée');
        return;
      }

      // ANDROID
      final androidDetails = AndroidNotificationDetails(
        'meal_reminder_channel',
        'Rappels de repas',
        channelDescription: 'Notifications pour les rappels de repas',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        color: Colors.orange,
      );

      // IOS
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final tz.TZDateTime tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

      debugPrint(' Notification prévue pour $tzDateTime');

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
        payload: payload,
      );

      debugPrint(' Notification programmée');
    } catch (e) {
      debugPrint('Erreur programmation notification: $e');
    }
  }

  // ================= ANNULATION =================
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
    debugPrint(' Notification $id annulée');
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    debugPrint(' Toutes les notifications annulées');
  }

  // ================= UTILITAIRE =================
  int generateNotificationId(DateTime date, String foodName) {
    final unique = '${date.millisecondsSinceEpoch}_$foodName';
    return unique.hashCode.abs();
  }
}
