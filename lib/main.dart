import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:baocaocuoiky/screens/onboding/onboding_screen.dart';
import 'package:baocaocuoiky/screens/chat/chat_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dùng try-catch để bao bọc việc khởi tạo Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Khởi tạo Firebase thành công!");
  } catch (e) {
    // Nếu có lỗi (ví dụ: đã khởi tạo rồi), chỉ in ra và BỎ QUA để app chạy tiếp
    print("Lỗi khởi tạo Firebase (có thể bỏ qua): $e");
  }

  // Quan trọng nhất: Dòng này PHẢI được chạy thì mới hết màn hình trắng
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
