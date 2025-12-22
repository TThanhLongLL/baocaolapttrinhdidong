import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rive/rive.dart';
import 'package:baocaocuoiky/screens/entryPoint/entry_point.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignInForm extends StatefulWidget {
  const SignInForm({
    super.key,
    required this.onModeChanged,
  });
  final ValueChanged<bool> onModeChanged;

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isSignUp = false; // false: đăng nhập, true: đăng ký

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isShowLoading = false;
  bool isShowConfetti = false;
  late SMITrigger error;
  late SMITrigger success;
  late SMITrigger reset;

  late SMITrigger confetti;
  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _onCheckRiveInit(Artboard artboard) {
    StateMachineController? controller =
        StateMachineController.fromArtboard(artboard, 'State Machine 1');

    artboard.addController(controller!);
    error = controller.findInput<bool>('Error') as SMITrigger;
    success = controller.findInput<bool>('Check') as SMITrigger;
    reset = controller.findInput<bool>('Reset') as SMITrigger;
  }

  void _onConfettiRiveInit(Artboard artboard) {
    StateMachineController? controller =
        StateMachineController.fromArtboard(artboard, "State Machine 1");
    artboard.addController(controller!);

    confetti = controller.findInput<bool>("Trigger explosion") as SMITrigger;
  }
  Future<void> submit(BuildContext context) async {
    setState(() {
      isShowConfetti = true;
      isShowLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!_formKey.currentState!.validate()) {
      setState(() {
        isShowLoading = false;
      });
      error.fire();
      Future.delayed(const Duration(seconds: 2), () => reset.fire());
      return;
    }

    try {
      final email = _emailCtrl.text.trim();
      final pass  = _passCtrl.text.trim();

      if (_isSignUp) {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: pass,
        );

        final uid = cred.user!.uid;
        final fullName = _nameCtrl.text.trim();

        // (Tuỳ chọn) lưu displayName trong Auth
        await cred.user!.updateDisplayName(fullName);

        // ✅ Lưu profile vào Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'fullName': fullName,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: pass,
        );
      }

      success.fire();
      await Future.delayed(const Duration(seconds: 1));
      confetti.fire();

      await Future.delayed(const Duration(seconds: 1));
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EntryPoint()),
      );
    } on FirebaseAuthException catch (e) {
      error.fire();
      if (!context.mounted) return;

      final msg = switch (e.code) {
        'email-already-in-use' => 'Email đã được dùng.',
        'weak-password' => 'Mật khẩu quá yếu (thử >= 6 ký tự).',
        'user-not-found' => 'Không tìm thấy tài khoản.',
        'wrong-password' => 'Sai mật khẩu.',
        'invalid-email' => 'Email không hợp lệ.',
        _ => 'Lỗi đăng nhập/đăng ký: ${e.code}',
      };

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) {
        setState(() => isShowLoading = false);
      }
      reset.fire();
    }
  }




  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isSignUp) ...[
                const Text(
                  "Full name",
                  style: TextStyle(color: Colors.black54),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: TextFormField(
                    controller: _nameCtrl,
                    validator: (value) {
                      if (!_isSignUp) return null;
                      if (value == null || value.trim().isEmpty) return "";
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: SvgPicture.asset("icons/User_name.svg"),                      ),
                    ),
                  ),
                ),
              ],
              const Text(
                "Email",
                style: TextStyle(
                  color: Colors.black54,
                ),

              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: TextFormField(
                  controller: _emailCtrl,  
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "";
                    }
                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: SvgPicture.asset("icons/email.svg"),
                    ),
                  ),
                ),
              ),
              const Text(
                "Password",
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: TextFormField(
                  controller: _passCtrl,
                  obscureText: true,
                  validator: (value) {            
                    if (value!.isEmpty) {
                      return "";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: SvgPicture.asset("icons/password.svg"),
                    ),
                  ),
                ),
              ),
              if (_isSignUp) ...[
                const Text(
                  "Confirm Password",
                  style: TextStyle(color: Colors.black54),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: TextFormField(
                    controller: _confirmCtrl,
                    obscureText: true,
                    validator: (value) {
                      if (!_isSignUp) return null;
                      if (value == null || value.isEmpty) return "";
                      if (value.trim() != _passCtrl.text.trim()) return "Mật khẩu không khớp";
                      return null;
                    },
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: SvgPicture.asset("icons/password.svg"),
                      ),
                    ),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_isSignUp && _passCtrl.text.trim() != _confirmCtrl.text.trim()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Mật khẩu không khớp")),
                      );
                      setState(() => isShowLoading = false);
                      error.fire();
                      return;
                    }

                    submit(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF77D8E),
                    minimumSize: const Size(double.infinity, 56),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                        bottomLeft: Radius.circular(25),
                      ),
                    ),
                  ),
                  icon: const Icon(
                    CupertinoIcons.arrow_right,
                    color: Color(0xFFFE0037),
                  ),
                  label: Text(_isSignUp ? "Sign Up" : "Sign In"),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSignUp = !_isSignUp;
                    _confirmCtrl.clear();
                  });
                  widget.onModeChanged(_isSignUp);
                },
              child: Text(
                      _isSignUp
                          ? "Đã có tài khoản? Đăng nhập"
                          : "Chưa có tài khoản? Đăng ký",
                    ),             
               ),
            ],
          ),
        ),
        isShowLoading
            ? CustomPositioned(
                child: RiveAnimation.asset(
                  'RiveAssets/check.riv',
                  fit: BoxFit.cover,
                  onInit: _onCheckRiveInit,
                ),
              )
            : const SizedBox(),
        isShowConfetti
            ? CustomPositioned(
                scale: 6,
                child: RiveAnimation.asset(
                  "RiveAssets/confetti.riv",
                  onInit: _onConfettiRiveInit,
                  fit: BoxFit.cover,
                ),
              )
            : const SizedBox(),
      ],
    );
  }
}

class CustomPositioned extends StatelessWidget {
  const CustomPositioned({super.key, this.scale = 1, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Column(
        children: [
          const Spacer(),
          SizedBox(
            height: 100,
            width: 100,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
