import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'sign_in_form.dart';

void showCustomDialog(BuildContext context, {required ValueChanged onValue}) {
  showGeneralDialog(
    context: context,
    barrierLabel: "Barrier",
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, __, ___) {
      final ValueNotifier<bool> isSignUp = ValueNotifier(false);

      return Center(
        child: Container(
          height: 800,
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
            body: Stack(
              clipBehavior: Clip.none,
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
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
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: ValueListenableBuilder<bool>(
                          valueListenable: isSignUp,
                          builder: (context, v, _) {
                            return Text(
                              v ? "Tạo tài khoản mới" : "Vui lòng đăng nhập",
                              textAlign: TextAlign.center,
                            );
                          },
                        ),
                      ),
                      SignInForm(
                        onModeChanged: (v) => isSignUp.value = v,
                      ),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "OR",
                              style: TextStyle(
                                color: Colors.black26,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: ValueListenableBuilder<bool>(
                          valueListenable: isSignUp,
                          builder: (context, v, _) {
                            return Text(
                              v
                                  ? "Sign up with Email, Apple or Google"
                                  : "Continue with Email, Apple or Google",
                              style: const TextStyle(color: Colors.black54),
                            );
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: () {},
                            padding: EdgeInsets.zero,
                            icon: SvgPicture.asset(
                              "icons/email_box.svg",
                              height: 64,
                              width: 64,
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            padding: EdgeInsets.zero,
                            icon: SvgPicture.asset(
                              "icons/apple_box.svg",
                              height: 64,
                              width: 64,
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            padding: EdgeInsets.zero,
                            icon: SvgPicture.asset(
                              "icons/google_box.svg",
                              height: 64,
                              width: 64,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: -48,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.black,
                    ),
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
  ).then(onValue);
}
