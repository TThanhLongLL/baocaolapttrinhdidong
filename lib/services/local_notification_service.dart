import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // ID kênh thông báo
  static const String channelId = 'thong_bao_hoc_tap_v4'; // Đổi tên kênh để refresh
  static const String channelName = 'Thông Báo Học Tập';

  Future<void> init() async {
    // 1. Cấu hình Android (Dùng icon 'app_icon' trong thư mục drawable)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    // 2. Cấu hình iOS
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true);

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // 3. Khởi tạo plugin
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        print("🔔 Người dùng đã bấm vào thông báo: ${details.payload}");
      },
    );

    // 4. Tạo kênh thông báo (Quan trọng cho Android)
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: 'Kênh thông báo học tập',
        importance: Importance.max, // Mức cao nhất để hiện banner
        playSound: true,
      );
      await androidPlugin.createNotificationChannel(channel);
      
      // Xin quyền hiển thị thông báo
      await androidPlugin.requestNotificationsPermission();
    }
  }

  // --- HÀM QUAN TRỌNG NHẤT: HIỆN THÔNG BÁO NGAY LẬP TỨC ---
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            importance: Importance.max,
            priority: Priority.high,
            color: Color(0xFF2196F3),
            icon: 'app_icon', // Đảm bảo file này có trong drawable
            playSound: true,
            styleInformation: BigTextStyleInformation(''), // Để hiện text dài
          ),
        ),
      );
      print("📢 Đã bắn thông báo ID $id: $title");
    } catch (e) {
      print("❌ Lỗi bắn thông báo: $e");
    }
  }
}