import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [],
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(settings: initializationSettings);
    await _notificationsPlugin.initialize(settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Ce se întâmplă când dai click pe notificare
      },
    );
  }

  Future<void> showInstantNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_channel_id',
      'Task Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails, // Trece detaliile aici
    );

    await _notificationsPlugin.show(id: 0, title: title, body: body, notificationDetails: platformDetails);
  }

  Future<void> scheduleNotification(int id, String title, String body, DateTime scheduledDate) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'deadline_channel',
          'Deadline Alerts',
          channelDescription: 'Notificări pentru termene limită',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      // Eliminăm uiLocalNotificationDateInterpretation deoarece nu mai există în v17+
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}