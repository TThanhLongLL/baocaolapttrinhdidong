import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rive/rive.dart';
import 'package:baocaocuoiky/screens/entryPoint/entry_point.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  // ... (Giữ nguyên các controller và biến state của bạn) ...
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
  late SMITrigger error, success, reset, confetti;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ... (Giữ nguyên các hàm dispose, RiveInit, generateId của bạn) ...
  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  void _onCheckRiveInit(Artboard artboard) {
    StateMachineController? controller = StateMachineController.fromArtboard(artboard, 'State Machine 1');
    artboard.addController(controller!);
    error = controller.findInput<bool>('Error') as SMITrigger;
    success = controller.findInput<bool>('Check') as SMITrigger;
    reset = controller.findInput<bool>('Reset') as SMITrigger;
  }

  void _onConfettiRiveInit(Artboard artboard) {
    StateMachineController? controller = StateMachineController.fromArtboard(artboard, "State Machine 1");
    artboard.addController(controller!);
    confetti = controller.findInput<bool>("Trigger explosion") as SMITrigger;
  }

  String _generateId(String prefix) => '${prefix}_${DateTime.now().millisecondsSinceEpoch}';

  // ... (Giữ nguyên hàm _saveUserToFirestore) ...
  Future<void> _saveUserToFirestore(User user, String fullName, String role) async {
    final accountId = _generateId('ACC');
    String defaultAvatar = user.photoURL ?? "https://ui-avatars.com/api/?name=$fullName&background=random&size=128";

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fullName': fullName, 'email': user.email, 'accountId': accountId,
      'role': role, 'profileImage': defaultAvatar, 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (role == 'student') {
      final q = await FirebaseFirestore.instance.collection('students').where('accountId', isEqualTo: accountId).get();
      if(q.docs.isEmpty) {
        await FirebaseFirestore.instance.collection('students').add({
          'hocSinhId': _generateId('HS'), 'fullName': fullName, 'email': user.email,
          'maHocSinh': '', 'accountId': accountId, 'ngaySinh': null, 'gioiTinh': null,
          'className': null, 'lopId': null, 'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } else if (role == 'teacher') {
      final q = await FirebaseFirestore.instance.collection('teachers').where('accountId', isEqualTo: accountId).get();
      if(q.docs.isEmpty) {
        await FirebaseFirestore.instance.collection('teachers').add({
          'giaoVienId': _generateId('GV'), 'hoTen': fullName, 'email': user.email,
          'maGiaoVien': '', 'accountId': accountId, 'ngaySinh': null, 'gioiTinh': null,
          'boMonId': null, 'lopDangDay': [], 'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // ... (Giữ nguyên hàm _handleGoogleSignIn) ...
  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() { isShowLoading = true; isShowConfetti = true; });
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) { setState(() => isShowLoading = false); return; }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          success.fire();
          await Future.delayed(const Duration(seconds: 1));
          if (!mounted) return;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EntryPoint()));
        } else {
          setState(() => isShowLoading = false);
          if (!mounted) return;
          await _showGoogleAdditionalInfoDialog(user, googleUser.displayName ?? "");
        }
      }
    } catch (e) {
      error.fire();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Google Error: $e")));
      setState(() => isShowLoading = false);
    }
  }

  // ... (Giữ nguyên hàm _showGoogleAdditionalInfoDialog) ...
  Future<void> _showGoogleAdditionalInfoDialog(User user, String defaultName) async {
    final nameController = TextEditingController(text: defaultName);
    String tempRole = 'student';
    await showDialog(
      context: context, barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Hoàn tất đăng ký"),
            content: Column( mainAxisSize: MainAxisSize.min, children: [
              const Text("Vui lòng xác nhận tên và vai trò."), const SizedBox(height: 16),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Họ và tên", border: OutlineInputBorder())),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: tempRole,
                decoration: const InputDecoration(labelText: "Vai trò", border: OutlineInputBorder()),
                items: _roles.map((role) => DropdownMenuItem(value: role['value'], child: Text(role['label']!))).toList(),
                onChanged: (val) { setStateDialog(() => tempRole = val!); },
              ),
            ]),
            actions: [
              TextButton(onPressed: () async { await FirebaseAuth.instance.signOut(); await _googleSignIn.signOut(); Navigator.pop(context); }, child: const Text("Hủy")),
              ElevatedButton(onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(context); setState(() => isShowLoading = true);
                try {
                  await user.updateDisplayName(nameController.text.trim());
                  await _saveUserToFirestore(user, nameController.text.trim(), tempRole);
                  success.fire(); confetti.fire();
                  await Future.delayed(const Duration(seconds: 2));
                  if (!mounted) return;
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EntryPoint()));
                } catch (e) { error.fire(); setState(() => isShowLoading = false); }
              }, child: const Text("Hoàn tất")),
            ],
          );
        });
      },
    );
  }

  // ... (Giữ nguyên hàm _forgotPassword) ...
  Future<void> _forgotPassword() async {
    final TextEditingController emailController = TextEditingController(text: _emailCtrl.text.trim());
    await showDialog(
      context: context, builder: (context) => AlertDialog(
      title: const Text("Đặt lại mật khẩu"),
      content: TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email", hintText: "email@example.com")),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
        ElevatedButton(onPressed: () async {
          if (emailController.text.isNotEmpty) {
            try { await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text.trim());
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã gửi email!"))); } catch (e) {}
          }
          Navigator.pop(context);
        }, child: const Text("Gửi")),
      ],
    ),
    );
  }

  // ... (Giữ nguyên hàm submit) ...
  Future<void> submit(BuildContext context) async {
    setState(() { isShowConfetti = true; isShowLoading = true; });
    await Future.delayed(const Duration(seconds: 1));
    if (!_formKey.currentState!.validate()) {
      setState(() => isShowLoading = false); error.fire();
      Future.delayed(const Duration(seconds: 2), () => reset.fire()); return;
    }
    try {
      final email = _emailCtrl.text.trim(); final pass = _passCtrl.text.trim();
      if (_isSignUp) {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);
        final fullName = _nameCtrl.text.trim();
        await cred.user!.updateDisplayName(fullName);
        await _saveUserToFirestore(cred.user!, fullName, _selectedRole);
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pass);
      }
      success.fire(); await Future.delayed(const Duration(seconds: 1)); confetti.fire();
      await Future.delayed(const Duration(seconds: 1));
      if (!context.mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => const EntryPoint()));
    } catch (e) { error.fire(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"))); }
    finally { if (mounted) setState(() => isShowLoading = false); reset.fire(); }
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

              // --- 3 NÚT MẠNG XÃ HỘI ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(onPressed: () {}, icon: SvgPicture.asset("assets/icons/email_box.svg", height: 64, width: 64)),
                  IconButton(onPressed: () {}, icon: SvgPicture.asset("assets/icons/apple_box.svg", height: 64, width: 64)),
                  IconButton(onPressed: _handleGoogleSignIn, padding: EdgeInsets.zero, icon: SvgPicture.asset("assets/icons/google_box.svg", height: 64, width: 64)),
                ],
              ),

              const SizedBox(height: 16),

              // --- SỬA LỖI OVERFLOW (DÙNG FLEXIBLE/SPACER) ---
              Row(
                children: [
                  if (!_isSignUp)
                    InkWell(
                      onTap: _forgotPassword,
                      child: const Text("Quên mật khẩu?", style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500)),
                    ),

                  const Spacer(), // Đẩy nút kia sang phải

                  Flexible( // Cho phép co dãn để không bị tràn
                    child: InkWell(
                      onTap: () {
                        setState(() { _isSignUp = !_isSignUp; _confirmCtrl.clear(); _selectedRole = 'student'; });
                        widget.onModeChanged(_isSignUp);
                      },
                      child: Text(
                        _isSignUp ? "Đã có TK? Đăng nhập" : "Chưa có TK? Đăng ký",
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFF77D8E)),
                        overflow: TextOverflow.ellipsis, // Nếu dài quá thì hiện ...
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

// --- CLASS CustomPositioned ĐỂ Ở CUỐI FILE ---
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