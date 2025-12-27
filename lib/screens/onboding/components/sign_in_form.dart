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
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isSignUp = false; // false: đăng nhập, true: đăng ký
  // Biến để lưu ảnh
  // --- THÊM: Biến quản lý vai trò ---
  String _selectedRole = 'student'; // Mặc định là học sinh
  final List<Map<String, String>> _roles = [
    {'value': 'student', 'label': 'Học sinh'},
    {'value': 'teacher', 'label': 'Giáo viên'},
    {'value': 'admin', 'label': 'Quản trị viên (Admin)'},
  ];
  // ---------------------------------

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

  // Hàm tạo accountId duy nhất
  String _generateId(String prefix) {
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}';
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
    final pass = _passCtrl.text.trim();

    if (_isSignUp) {
      // 1. Tạo tài khoản Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      final uid = cred.user!.uid;
      final fullName = _nameCtrl.text.trim();
      final accountId = _generateId('ACC');

      // Cập nhật tên hiển thị
      await cred.user!.updateDisplayName(fullName);


      String defaultAvatar = "https://ui-avatars.com/api/?name=$fullName&background=random&size=128";
      // 2. Lưu vào bảng 'users'
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fullName': fullName,
        'email': email,
        'accountId': accountId,
        'role': _selectedRole,
        'profileImage': defaultAvatar, 
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Tạo dữ liệu hồ sơ tương ứng
      if (_selectedRole == 'student') {
        // ✅ Tự động tạo hồ sơ học sinh
        await FirebaseFirestore.instance.collection('students').add({
          'hocSinhId': _generateId('HS'),
          'fullName': fullName,
          'email': email,
          'maHocSinh': '', // Admin sẽ cập nhật sau
          'accountId': accountId,
          'ngaySinh': null,
          'gioiTinh': null,
          'className': null,
          'lopId': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else if (_selectedRole == 'teacher') {
        // ✅ Tự động tạo hồ sơ giáo viên
        await FirebaseFirestore.instance.collection('teachers').add({
          'giaoVienId': _generateId('GV'),
          'hoTen': fullName,
          'email': email,
          'maGiaoVien': '', // Admin sẽ cập nhật sau
          'accountId': accountId,
          'ngaySinh': null,
          'gioiTinh': null,
          'boMonId': null,
          'lopDangDay': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      // Nếu là admin thì chỉ lưu trong users là đủ

    } else {
      // Đăng nhập
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
      _ => 'Lỗi: ${e.message}',
    };

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  } catch (e) {
    error.fire();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi hệ thống: $e")));
    }
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
                  "Full Name",
                  style: TextStyle(color: Colors.black54),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: TextFormField(
                    controller: _nameCtrl,
                    validator: (value) {
                      if (!_isSignUp) return null;
                      if (value == null || value.trim().isEmpty) return "Vui lòng nhập tên";
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: SvgPicture.asset("assets/icons/User_name.svg"),
                      ),
                    ),
                  ),
                ),

                // --- THÊM: Dropdown chọn vai trò ---
                const Text(
                  "Vai trò đăng ký",
                  style: TextStyle(color: Colors.black54),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.badge_outlined, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: _roles.map((role) {
                      return DropdownMenuItem(
                        value: role['value'],
                        child: Text(role['label']!),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedRole = val!;
                      });
                    },
                  ),
                ),
                // -----------------------------------
              ],
              const Text(
                "Email",
                style: TextStyle(color: Colors.black54),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: TextFormField(
                  controller: _emailCtrl,
                  validator: (value) {
                    if (value!.isEmpty) return "";
                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: SvgPicture.asset("assets/icons/email.svg"),
                    ),
                  ),
                ),
              ),
              const Text(
                "Password",
                style: TextStyle(color: Colors.black54),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: TextFormField(
                  controller: _passCtrl,
                  obscureText: true,
                  validator: (value) {
                    if (value!.isEmpty) return "";
                    return null;
                  },
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: SvgPicture.asset("assets/icons/password.svg"),
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
                        child: SvgPicture.asset("assets/icons/password.svg"),
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
                    // Reset role về student khi chuyển chế độ
                    _selectedRole = 'student';
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
            'assets/RiveAssets/check.riv',
            fit: BoxFit.cover,
            onInit: _onCheckRiveInit,
          ),
        )
            : const SizedBox(),
        isShowConfetti
            ? CustomPositioned(
          scale: 6,
          child: RiveAnimation.asset(
            "assets/RiveAssets/confetti.riv",
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
