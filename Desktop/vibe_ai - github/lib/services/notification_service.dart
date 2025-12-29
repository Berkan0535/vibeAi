// lib/services/notification_service.dart
// Bildirim yönetimi için servis sınıfı

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Bildirimleri başlat
  Future<void> initialize() async {
    // Web platformunda bildirimleri atla
    if (kIsWeb) {
      print('Bildirimler web platformunda desteklenmiyor');
      return;
    }

    try {
      // Timezone verilerini yükle
      tz.initializeTimeZones();

      // Android bildirim kanallarını oluştur
      const androidChannel = AndroidNotificationChannel(
        'task_notifications',
        'Görev Bildirimleri',
        description: 'Planlanan görevler için bildirimler',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      // Kanalı sisteme kaydet
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // Android ayarları
      const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');

      // iOS ayarları
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      print('Bildirimler başarıyla başlatıldı');
    } catch (e) {
      print('Bildirim başlatma hatası: $e');
    }
  }

  // Bildirim izni iste
  Future<bool> requestPermission() async {
    // Web platformunda izin isteme
    if (kIsWeb) {
      return false;
    }

    try {
      if (await Permission.notification.isGranted) {
        return true;
      }

      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      print('İzin isteme hatası: $e');
      return false;
    }
  }

  // Bildirime tıklandığında
  void _onNotificationTapped(NotificationResponse response) {
    // Buraya bildirime tıklandığında yapılacak işlemler eklenebilir
    print('Bildirime tıklandı: ${response.payload}');
  }

  // Anında bildirim gönder
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'task_notifications',
        'Görev Bildirimleri',
        channelDescription: 'Planlanan görevler için bildirimler',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        DateTime.now().millisecond,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      print('Bildirim gönderme hatası: $e');
    }
  }

  // Zamanlanmış bildirim ayarla
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'task_notifications',
        'Görev Bildirimleri',
        channelDescription: 'Planlanan görevler için bildirimler',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      print('Zamanlanmış bildirim hatası: $e');
    }
  }

  // Günlük tekrarlayan bildirim
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'task_notifications',
        'Görev Bildirimleri',
        channelDescription: 'Planlanan görevler için bildirimler',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfTime(hour, minute),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      print('Günlük bildirim hatası: $e');
    }
  }

  // Belirli bir saatin bir sonraki örneğini bul
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // Belirli bir bildirimi iptal et
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Tüm bildirimleri iptal et
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Bekleyen bildirimleri listele
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
