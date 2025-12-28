import 'package:flutter/material.dart';
import 'sign_in_form.dart'; // Import file Form

void showCustomDialog(BuildContext context, {required ValueChanged<bool> onValue}) {
  showGeneralDialog(
    context: context,
    barrierLabel: "Barrier",
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, __, ___) {
      // Biến này chỉ để thay đổi Tiêu đề (Sign In / Sign Up)
      final ValueNotifier<bool> isSignUp = ValueNotifier(false);

      return Center(
        child: Container(
          height: 640, // Chiều cao cố định vừa vặn
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 30),
                blurRadius: 60,
              ),
              const BoxShadow(
                color: Colors.black45,
                offset: Offset(0, 30),
                blurRadius: 60,
              ),
            ],
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              clipBehavior: Clip.none,
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      // Tiêu đề thay đổi theo trạng thái
                      ValueListenableBuilder<bool>(
                        valueListenable: isSignUp,
                        builder: (context, v, _) {
                          return Text(
                            v ? "Sign up" : "Sign in",
                            style: const TextStyle(
                              fontSize: 34,
                              fontFamily: "Poppins",
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          "Vui lòng nhập thông tin để tiếp tục",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),

                      // --- GỌI FORM Ở ĐÂY (Toàn bộ logic nằm trong này) ---
                      SignInForm(
                        onModeChanged: (v) => isSignUp.value = v,
                      ),
                      // ----------------------------------------------------
                    ],
                  ),
                ),
                // Nút đóng (X)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: -48,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.close, size: 20, color: Colors.black),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (_, anim, __, child) {
      final tween = Tween(begin: const Offset(0, -1), end: Offset.zero);
      return SlideTransition(
        position: tween.animate(
          CurvedAnimation(parent: anim, curve: Curves.easeInOut),
        ),
        child: child,
      );
    },
  ).then((_) => onValue(true));
}