import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:baocaocuoiky/screens/onboding/onboding_screen.dart';
import 'package:baocaocuoiky/screens/chat/chat_screen.dart';
import 'firebase_options.dart';
import 'package:baocaocuoiky/services/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Khởi tạo Firebase thành công!");
  } catch (e) {
    print("Lỗi khởi tạo Firebase (có thể bỏ qua): $e");
  }

  // 2. [QUAN TRỌNG] Khởi tạo Local Notification
  // Dòng này giúp đăng ký kênh thông báo với hệ thống Android/iOS
  await LocalNotificationService().init();

  // 3. Chạy ứng dụng
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'The Flutter Way',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFEEF1F8),
        primarySwatch: Colors.blue,
        fontFamily: "Intel",
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          errorStyle: TextStyle(height: 0),
          border: defaultInputBorder,
          enabledBorder: defaultInputBorder,
          focusedBorder: defaultInputBorder,
          errorBorder: defaultInputBorder,
        ),
      ),
      routes: {
        '/chat': (context) => const ChatScreen(),
      },
      home: const OnbodingScreen(),
    );
  }
}

const defaultInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(16)),
  borderSide: BorderSide(
    color: Color(0xFFDEE3F2),
    width: 1,
  ),
);