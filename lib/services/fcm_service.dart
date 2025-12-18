import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<String> _notificationStream =
      StreamController<String>.broadcast();
  Stream<String> get notificationStream => _notificationStream.stream;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings =
          InitializationSettings(android: androidSettings, iOS: iosSettings);

      await _localNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          if (response.payload != null) {
            _notificationStream.add(response.payload!);
          }
        },
      );

      
      await _createNotificationChannel();

      
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      
      await _configureFCM();

      _initialized = true;
      print('FCMService initialisé avec succès');
    } catch (e) {
      print(' Erreur lors de l\'initialisation: $e');
    }
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'meal_reminder_channel',
      'Rappels de repas',
      description: 'Notifications de rappel pour vos repas',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _configureFCM() async {
   
    _fcm.getToken().then((token) => print("📱 FCM Token: $token"));

   
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        _showLocalNotification(
          notification.title, 
          notification.body, 
          message.data['entryId']
        );
      }
    });
  }

  Future<void> scheduleLocalNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String entryId,
  }) async {
    try {
      print(' Planification de notification...');
      print('Heure: $scheduledDate');
      print('Maintenant: ${DateTime.now()}');
      
     
      if (scheduledDate.isBefore(DateTime.now())) {
        throw Exception('La date est dans le passé');
      }

   
      final location = tz.getLocation('Africa/Casablanca');
      final tz.TZDateTime scheduledTzDate = tz.TZDateTime.from(
        scheduledDate, 
        location
      );
       print('Date TZ Casablanca : $scheduledTzDate');
     
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'meal_reminder_channel',
        'Rappels de repas',
        channelDescription: 'Notifications de rappel de repas',
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

      final NotificationDetails details =
          NotificationDetails(android: androidDetails, iOS: iosDetails);

      
      final notificationId = entryId.hashCode & 0x7fffffff;


      await _localNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledTzDate,
        details,
        payload: entryId,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        androidAllowWhileIdle: true,
        matchDateTimeComponents: DateTimeComponents.time
      );

      print(' Notification planifiée avec succès!');
      print('ID: $notificationId');
      print('Pour: $scheduledDate');
      print('Mode: inexactAllowWhileIdle');
    } catch (e, stackTrace) {
      print(' ERREUR lors de la planification: $e');
      print('Stack: $stackTrace');
      rethrow;
    }
  }

  void _showLocalNotification(String? title, String? body, String? payload) {
    if (title == null || body == null) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'meal_reminder_channel',
      'Rappels de repas',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    _localNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

 
  Future<void> cancelScheduledNotification(int notificationId) async {
    try {
      await _localNotificationsPlugin.cancel(notificationId);
      print(' Notification annulée: $notificationId');
    } catch (e) {
      print(' Erreur lors de l\'annulation: $e');
    }
  }


  Future<void> cancelAllScheduledNotifications() async {
    try {
      await _localNotificationsPlugin.cancelAll();
      print(' Toutes les notifications annulées');
    } catch (e) {
      print(' Erreur lors de l\'annulation: $e');
    }
  }

  void dispose() {
    _notificationStream.close();
  }
}