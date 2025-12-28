import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Để kiểm tra Web/App
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // 1. Hàm Đăng nhập Google thông minh (Tự chỉnh theo nền tảng)
  static Future<User?> signInWithGoogle() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user;

    if (kIsWeb) {
      // --- DÀNH CHO WEB (Sửa lỗi popup_closed) ---
      GoogleAuthProvider authProvider = GoogleAuthProvider();
      try {
        final UserCredential userCredential = await auth.signInWithPopup(authProvider);
        user = userCredential.user;
      } catch (e) {
        rethrow; // Ném lỗi ra để UI xử lý
      }
    } else {
      // --- DÀNH CHO ANDROID / IOS ---
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Đăng xuất trước để cho phép chọn lại tài khoản (tuỳ chọn)
      // await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        try {
          final UserCredential userCredential = await auth.signInWithCredential(credential);
          user = userCredential.user;
        } catch (e) {
          rethrow;
        }
      }
    }
    return user;
  }

  // 2. Hàm Lưu User mới vào Firestore (Tách từ form cũ sang)
  static Future<void> saveNewUserToFirestore(User user, String fullName, String role) async {
    // Hàm sinh ID ngẫu nhiên
    String generateId(String prefix) => '${prefix}_${DateTime.now().millisecondsSinceEpoch}';
    final accountId = generateId('ACC');

    String defaultAvatar = user.photoURL ?? "https://ui-avatars.com/api/?name=$fullName&background=random&size=128";

    // Lưu vào bảng 'users'
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fullName': fullName,
      'email': user.email,
      'accountId': accountId,
      'role': role,
      'profileImage': defaultAvatar,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Lưu vào bảng chi tiết (students / teachers)
    if (role == 'student') {
      final q = await FirebaseFirestore.instance.collection('students').where('accountId', isEqualTo: accountId).get();
      if(q.docs.isEmpty) {
        await FirebaseFirestore.instance.collection('students').add({
          'hocSinhId': generateId('HS'), 'fullName': fullName, 'email': user.email,
          'maHocSinh': '', 'accountId': accountId, 'ngaySinh': null, 'gioiTinh': null,
          'className': null, 'lopId': null, 'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } else if (role == 'teacher') {
      final q = await FirebaseFirestore.instance.collection('teachers').where('accountId', isEqualTo: accountId).get();
      if(q.docs.isEmpty) {
        await FirebaseFirestore.instance.collection('teachers').add({
          'giaoVienId': generateId('GV'), 'hoTen': fullName, 'email': user.email,
          'maGiaoVien': '', 'accountId': accountId, 'ngaySinh': null, 'gioiTinh': null,
          'boMonId': null, 'lopDangDay': [], 'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }
}