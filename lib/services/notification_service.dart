import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _inited = false;

  /// 所有提醒固定在这个时间通知
  // static const int reminderHour = 9;
  // static const int reminderMinute = 0;

  // ⚠️ 测试用：当前时间 +2 分钟。测完改回 const int reminderHour = 9; reminderMinute = 0;
  static int get reminderHour =>
      DateTime.now().add(const Duration(minutes: 2)).hour;
  static int get reminderMinute =>
      DateTime.now().add(const Duration(minutes: 2)).minute;

  /// 初始化
  static Future<void> init() async {
    if (_inited) return;
    // ─── 1. 初始化时区 ───
    tz.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {}

    // ─── 2. 初始化通知插件 ───
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {},
    );

    // ─── 3. 请求权限 ───
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _inited = true;
  }

  /// 预约一条横幅通知
  static Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    int repeatDays = 0,
  }) async {
    if (repeatDays == 0 && when.isBefore(DateTime.now())) return;

    // 重复规则
    DateTimeComponents? match;
    if (repeatDays == 1) {
      match = DateTimeComponents.time;
    } else if (repeatDays == 7) {
      match = DateTimeComponents.dayOfWeekAndTime;
    } else if (repeatDays == 30 ||
        repeatDays == 90 ||
        repeatDays == 180 ||
        repeatDays == 365) {
      match = DateTimeComponents.dayOfMonthAndTime;
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'furkid_reminders',
          '宠物提醒',
          channelDescription: '驱虫、疫苗、称重等提醒',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: match,
    );
  }

  /// 取消一条通知
  static Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
  }

  /// 取消所有通知
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
