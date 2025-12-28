import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rive/rive.dart';
import 'package:baocaocuoiky/screens/entryPoint/entry_point.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:baocaocuoiky/services/auth_service.dart'; 

class SignInForm extends StatefulWidget {
  const SignInForm({super.key, required this.onModeChanged});
  final ValueChanged<bool> onModeChanged;

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isSignUp = false;
  String _selectedRole = 'student';

  final List<Map<String, String>> _roles = [
    {'value': 'student', 'label': 'Học sinh'},
    {'value': 'teacher', 'label': 'Giáo viên'},
    {'value': 'admin', 'label': 'Quản trị viên (Admin)'},
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isShowLoading = false;
  bool isShowConfetti = false;
  
  // Dùng Nullable (?) để tránh lỗi LateInitializationError
  SMITrigger? error, success, reset, confetti;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  void _onCheckRiveInit(Artboard artboard) {
    StateMachineController? controller = StateMachineController.fromArtboard(artboard, 'State Machine 1');
    artboard.addController(controller!);
    error = controller.findInput<bool>('Error') as SMITrigger?;
    success = controller.findInput<bool>('Check') as SMITrigger?;
    reset = controller.findInput<bool>('Reset') as SMITrigger?;
  }

  void _onConfettiRiveInit(Artboard artboard) {
    StateMachineController? controller = StateMachineController.fromArtboard(artboard, "State Machine 1");
    artboard.addController(controller!);
    confetti = controller.findInput<bool>("Trigger explosion") as SMITrigger?;
  }

  // --- LOGIC GỌI AUTH SERVICE (ĐÃ TÁCH) ---
  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() { isShowLoading = true; isShowConfetti = true; });
      
      // 1. Gọi Service để đăng nhập
      final User? user = await AuthService.signInWithGoogle();

      if (user != null) {
        // 2. Kiểm tra xem User đã có trong DB chưa
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        
        if (userDoc.exists) {
          // Case A: Đã có -> Vào App luôn
          success?.fire();
          await Future.delayed(const Duration(seconds: 1));
          if (!mounted) return;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EntryPoint()));
        } else {
          // Case B: Chưa có -> Hiện Dialog bổ sung thông tin
          setState(() => isShowLoading = false);
          if (!mounted) return;
          await _showGoogleAdditionalInfoDialog(user, user.displayName ?? "");
        }
      } else {
        // User hủy đăng nhập
        setState(() => isShowLoading = false);
      }
    } catch (e) {
      error?.fire();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi đăng nhập: $e")));
      setState(() => isShowLoading = false);
    }
  }

  Future<void> _showGoogleAdditionalInfoDialog(User user, String defaultName) async {
    final nameController = TextEditingController(text: defaultName);
    String tempRole = 'student';
    await showDialog(
      context: context, barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
            title: const Text("Hoàn tất đăng ký", style: TextStyle(fontWeight: FontWeight.w700)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Vui lòng xác nhận tên và vai trò.", style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Họ và tên",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: tempRole,
                  decoration: const InputDecoration(
                    labelText: "Vai trò",
                    border: OutlineInputBorder(),
                  ),
                  items: _roles
                      .map((role) => DropdownMenuItem(value: role['value'], child: Text(role['label']!)))
                      .toList(),
                  onChanged: (val) {
                    setStateDialog(() => tempRole = val!);
                  },
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            actions: [
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6A7280),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                child: const Text("Hủy"),
              ),
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    setState(() => isShowLoading = true);
                    try {
                      await user.updateDisplayName(nameController.text.trim());
                      await AuthService.saveNewUserToFirestore(user, nameController.text.trim(), tempRole);
                      success?.fire();
                      confetti?.fire();
                      await Future.delayed(const Duration(seconds: 2));
                      if (!mounted) return;
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EntryPoint()));
                    } catch (e) {
                      error?.fire();
                      setState(() => isShowLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B8DEF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    minimumSize: const Size(110, 42),
                  ),
                  child: const Text("Hoàn tất"),
                ),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> submit(BuildContext context) async {
    setState(() { isShowConfetti = true; isShowLoading = true; });
    await Future.delayed(const Duration(seconds: 1));
    if (!_formKey.currentState!.validate()) {
      setState(() => isShowLoading = false); error?.fire();
      Future.delayed(const Duration(seconds: 2), () => reset?.fire()); return;
    }
    try {
      final email = _emailCtrl.text.trim(); final pass = _passCtrl.text.trim();
      if (_isSignUp) {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);
        final fullName = _nameCtrl.text.trim();
        await cred.user!.updateDisplayName(fullName);
        
        // Gọi Service để lưu
        await AuthService.saveNewUserToFirestore(cred.user!, fullName, _selectedRole);
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pass);
      }
      success?.fire(); await Future.delayed(const Duration(seconds: 1)); confetti?.fire();
      await Future.delayed(const Duration(seconds: 1));
      if (!context.mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => const EntryPoint()));
    } catch (e) { error?.fire(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"))); }
    finally { if (mounted) setState(() => isShowLoading = false); reset?.fire(); }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nhập email trước khi đặt lại mật khẩu")),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã gửi email đặt lại mật khẩu. Kiểm tra hộp thư của bạn.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Không gửi được email đặt lại mật khẩu: $e")),
      );
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
                const Text("Họ và Tên", style: TextStyle(color: Colors.black54)),
                Padding(padding: const EdgeInsets.only(top: 8, bottom: 16), child: TextFormField(
                    controller: _nameCtrl, validator: (v) => _isSignUp && v!.isEmpty ? "Nhập tên" : null,
                    decoration: InputDecoration(prefixIcon: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: SvgPicture.asset("assets/icons/User_name.svg"))))),
                const Text("Vai trò", style: TextStyle(color: Colors.black54)),
                Padding(padding: const EdgeInsets.only(top: 8, bottom: 16), child: DropdownButtonFormField<String>(
                    value: _selectedRole, items: _roles.map((r) => DropdownMenuItem(value: r['value'], child: Text(r['label']!))).toList(),
                    onChanged: (v) => setState(() => _selectedRole = v!),
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.badge_outlined, color: Colors.grey), filled: true, fillColor: Colors.white))),
              ],

              const Text("Email", style: TextStyle(color: Colors.black54)),
              Padding(padding: const EdgeInsets.only(top: 8, bottom: 16), child: TextFormField(
                  controller: _emailCtrl, validator: (v) => v!.isEmpty ? "Nhập email" : null, keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(prefixIcon: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: SvgPicture.asset("assets/icons/email.svg"))))),

              const Text("Mật khẩu", style: TextStyle(color: Colors.black54)),
              Padding(padding: const EdgeInsets.only(top: 8, bottom: 16), child: TextFormField(
                  controller: _passCtrl, obscureText: true, validator: (v) => v!.isEmpty ? "Nhập mật khẩu" : null,
                  decoration: InputDecoration(prefixIcon: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: SvgPicture.asset("assets/icons/password.svg"))))),

              if (_isSignUp) ...[
                const Text("Nhập lại mật khẩu", style: TextStyle(color: Colors.black54)),
                Padding(padding: const EdgeInsets.only(top: 8, bottom: 16), child: TextFormField(
                    controller: _confirmCtrl, obscureText: true, validator: (v) => _isSignUp && v != _passCtrl.text ? "Không khớp" : null,
                    decoration: InputDecoration(prefixIcon: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: SvgPicture.asset("assets/icons/password.svg"))))),
              ],

              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                child: ElevatedButton.icon(
                  onPressed: () { if (_isSignUp && _passCtrl.text != _confirmCtrl.text) { return; } submit(context); },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF77D8E), minimumSize: const Size(double.infinity, 56), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(25), bottomRight: Radius.circular(25), bottomLeft: Radius.circular(25)))),
                  icon: const Icon(CupertinoIcons.arrow_right, color: Color(0xFFFE0037)),
                  label: Text(_isSignUp ? "Đăng Ký" : "Đăng Nhập"),
                ),
              ),

              // --- NÚT GOOGLE ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(onPressed: () {}, icon: SvgPicture.asset("assets/icons/email_box.svg", height: 64, width: 64)),
                  IconButton(onPressed: () {}, icon: SvgPicture.asset("assets/icons/apple_box.svg", height: 64, width: 64)),
                  // Gọi hàm mới đã sửa
                  IconButton(onPressed: _handleGoogleSignIn, padding: EdgeInsets.zero, icon: SvgPicture.asset("assets/icons/google_box.svg", height: 64, width: 64)),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  if (!_isSignUp)
                    InkWell(
                      onTap: _forgotPassword,
                      child: const Text(
                        "Quên mật khẩu?",
                        style: TextStyle(
                          color: Color(0xFF5B8DEF),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Flexible(
                    child: InkWell(
                      onTap: () {
                        setState(() { _isSignUp = !_isSignUp; _confirmCtrl.clear(); _selectedRole = 'student'; });
                        widget.onModeChanged(_isSignUp);
                      },
                      child: Text(
                        _isSignUp ? "Đã có TK? Đăng nhập" : "Chưa có TK? Đăng ký",
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFF77D8E)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (isShowLoading) CustomPositioned(child: RiveAnimation.asset('assets/RiveAssets/check.riv', fit: BoxFit.cover, onInit: _onCheckRiveInit)),
        if (isShowConfetti) CustomPositioned(scale: 6, child: RiveAnimation.asset("assets/RiveAssets/confetti.riv", onInit: _onConfettiRiveInit, fit: BoxFit.cover)),
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
          SizedBox(height: 100, width: 100, child: Transform.scale(scale: scale, child: child)),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
