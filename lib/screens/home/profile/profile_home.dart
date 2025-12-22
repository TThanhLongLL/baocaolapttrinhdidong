import 'package:flutter/material.dart';
import 'profile_theme.dart';

// ============================================================================
// 3. PROFILE SCREEN (Màn hình chính)
// ============================================================================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {

  // Quản lý Animation
  late AnimationController animationController;

  // List các Widget con (Header, Class, Calendar...)
  List<Widget> listViews = <Widget>[];

  // Quản lý thanh cuộn và hiệu ứng mờ AppBar
  final ScrollController scrollController = ScrollController();
  double topBarOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);

    addAllListData();

    // Logic làm mờ AppBar khi cuộn
    scrollController.addListener(() {
      if (scrollController.offset >= 24) {
        if (topBarOpacity != 1.0) {
          setState(() {
            topBarOpacity = 1.0;
          });
        }
      } else if (scrollController.offset <= 24 &&
          scrollController.offset >= 0) {
        if (topBarOpacity != scrollController.offset / 24) {
          setState(() {
            topBarOpacity = scrollController.offset / 24;
          });
        }
      } else if (scrollController.offset <= 0) {
        if (topBarOpacity != 0.0) {
          setState(() {
            topBarOpacity = 0.0;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    animationController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void addAllListData() {
    const int count = 5;

    // --- 1. Header Profile ---
    listViews.add(
      ProfileHeaderView(
        animation: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
            parent: animationController,
            curve: const Interval((1 / count) * 0, 1.0, curve: Curves.fastOutSlowIn))),
        animationController: animationController,
        onEditProfile: () {
          _showEditOptions(context);
        },
      ),
    );

    // --- 2. Lớp Học ---
    listViews.add(
      ClassSubjectView(
        animation: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
            parent: animationController,
            curve: const Interval((1 / count) * 2, 1.0, curve: Curves.fastOutSlowIn))),
        animationController: animationController,
        className: "Lớp: Kỹ Thuật Phần Mềm K18",
      ),
    );

    // --- 3. Tiêu đề Lịch ---
    listViews.add(
      Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 8),
        child: Text(
          'Lịch Học & Deadline',
          textAlign: TextAlign.left,
          style: AppTheme.headline.copyWith(fontSize: 18),
        ),
      ),
    );

    // --- 4. Lịch ---
    listViews.add(
      ScheduleCalendarView(
        animation: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
            parent: animationController,
            curve: const Interval((1 / count) * 3, 1.0, curve: Curves.fastOutSlowIn))),
        animationController: animationController,
      ),
    );
  }
// Hàm 1: Hiển thị lựa chọn (Menu)
  void _showEditOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: AppTheme.nearlyDarkBlue),
              title: const Text("Đổi tên hiển thị"),
              onTap: () {
                Navigator.pop(context); // Đóng menu lựa chọn
                _showChangeNameDialog(context); // Mở dialog đổi tên
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock, color: AppTheme.nearlyDarkBlue),
              title: const Text("Đổi mật khẩu"),
              onTap: () {
                Navigator.pop(context); // Đóng menu lựa chọn
                _showChangePasswordDialog(context); // Mở dialog đổi mật khẩu
              },
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  // Hàm chung để tạo style cho ô nhập liệu (giúp code gọn hơn)
  InputDecoration _buildInputDecoration(String label, IconData icon, {String? errorText}) {
    return InputDecoration(
      labelText: label,
      errorText: errorText,
      prefixIcon: Icon(icon, color: AppTheme.nearlyDarkBlue.withOpacity(0.7)),
      filled: true,
      fillColor: Colors.grey[100], // Màu nền xám nhạt sang trọng
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.nearlyDarkBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  // --- Hàm 2: Dialog Đổi tên (Giao diện mới) ---
  void _showChangeNameDialog(BuildContext context) {
    TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Bo góc dialog nhiều hơn
          title: Row(
            children: const [
              Icon(Icons.edit_note, color: AppTheme.nearlyDarkBlue, size: 28),
              SizedBox(width: 10),
              Text("Đổi tên hiển thị", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Hãy nhập tên mới mà bạn muốn hiển thị trên hồ sơ.",
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: _buildInputDecoration("Tên mới", Icons.person),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
              child: const Text("Hủy bỏ", style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Logic lưu tên Firebase
                print("Tên mới: ${nameController.text}");
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.nearlyDarkBlue,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: AppTheme.nearlyDarkBlue.withOpacity(0.5), // Đổ bóng màu xanh
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text("Cập nhật"),
            ),
          ],
        );
      },
    );
  }

  // --- Hàm 3: Dialog Đổi mật khẩu (Giao diện mới) ---
  void _showChangePasswordDialog(BuildContext context) {
    final TextEditingController passController = TextEditingController();
    final TextEditingController confirmPassController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: const [
                  Icon(Icons.lock_reset, color: AppTheme.nearlyDarkBlue, size: 28),
                  SizedBox(width: 10),
                  Text("Đổi mật khẩu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Nhập mật khẩu mới để bảo vệ tài khoản.",
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 20),
                  
                  // Ô nhập mật khẩu mới
                  TextField(
                    controller: passController,
                    decoration: _buildInputDecoration("Mật khẩu mới", Icons.vpn_key),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  
                  // Ô nhập lại mật khẩu
                  TextField(
                    controller: confirmPassController,
                    decoration: _buildInputDecoration(
                      "Xác nhận mật khẩu", 
                      Icons.check_circle_outline, 
                      errorText: errorText
                    ),
                    obscureText: true,
                    onChanged: (value) {
                      // Tự động xóa lỗi khi người dùng gõ lại
                      if (errorText != null) {
                        setStateDialog(() => errorText = null);
                      }
                    },
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  child: const Text("Hủy bỏ", style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (passController.text != confirmPassController.text) {
                      setStateDialog(() {
                        errorText = "Mật khẩu xác nhận không khớp!";
                      });
                    } else if (passController.text.isEmpty) {
                      setStateDialog(() {
                        errorText = "Vui lòng nhập mật khẩu!";
                      });
                    } else {
                      // TODO: Logic đổi mật khẩu Firebase
                      print("Pass mới: ${passController.text}");
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Đổi mật khẩu thành công!"),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating, // Thông báo nổi đẹp hơn
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.nearlyDarkBlue,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppTheme.nearlyDarkBlue.withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text("Lưu thay đổi"),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Future<bool> getData() async {
    await Future<dynamic>.delayed(const Duration(milliseconds: 50));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: <Widget>[
            getMainListViewUI(),
            getAppBarUI(),
            SizedBox(
              height: MediaQuery.of(context).padding.bottom,
            )
          ],
        ),
      ),
    );
  }

  Widget getMainListViewUI() {
    return FutureBuilder<bool>(
      future: getData(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        } else {
          return ListView.builder(
            controller: scrollController,
            padding: EdgeInsets.only(
              top: AppBar().preferredSize.height +
                  MediaQuery.of(context).padding.top +
                  24,
              bottom: 62 + MediaQuery.of(context).padding.bottom,
            ),
            itemCount: listViews.length,
            scrollDirection: Axis.vertical,
            itemBuilder: (BuildContext context, int index) {
              animationController.forward();
              return listViews[index];
            },
          );
        }
      },
    );
  }

  // Thanh App Bar (Top Bar)
  Widget getAppBarUI() {
    return Column(
      children: <Widget>[
        AnimatedBuilder(
          animation: animationController,
          builder: (BuildContext context, Widget? child) {
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.white.withOpacity(topBarOpacity),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32.0),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                      color: AppTheme.grey
                          .withOpacity(0.4 * topBarOpacity),
                      offset: const Offset(1.1, 1.1),
                      blurRadius: 10.0),
                ],
              ),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: MediaQuery.of(context).padding.top,
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 50 - 8.0 * topBarOpacity,
                        bottom: 12 - 8.0 * topBarOpacity),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Hồ Sơ Của Tôi',
                              textAlign: TextAlign.left,
                              style: AppTheme.headline.copyWith(
                                fontSize: 22 + 6 - 6 * topBarOpacity,
                              ),
                            ),
                          ),
                        ),
                        // Nút Back giả lập
                        SizedBox(
                          height: 38,
                          width: 38,
                          child: InkWell(
                            highlightColor: Colors.transparent,
                            borderRadius: const BorderRadius.all(
                                Radius.circular(32.0)),
                            onTap: () {},
                            child: const Center(
                              child: Icon(
                                Icons.settings,
                                color: AppTheme.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        )
      ],
    );
  }
}

// ============================================================================
// 4. CUSTOM WIDGETS
// ============================================================================

// --- WIDGET 1: PROFILE HEADER ---
class ProfileHeaderView extends StatelessWidget {
  final AnimationController animationController;
  final Animation<double> animation;
  final VoidCallback onEditProfile;

  const ProfileHeaderView(
      {Key? key,
        required this.animationController,
        required this.animation,
        required this.onEditProfile})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: animation,
          child: Transform(
            transform: Matrix4.translationValues(
                0.0, 30 * (1.0 - animation.value), 0.0),
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 24, right: 24, top: 16, bottom: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                        color: AppTheme.grey.withOpacity(0.2),
                        offset: const Offset(1.1, 1.1),
                        blurRadius: 10.0),
                  ],
                ),
                child: Column(
                  children: <Widget>[
                    // Avatar & Camera Icon
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: AppTheme.grey.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5))
                              ],
                              image: const DecorationImage(
                                image: NetworkImage("https://i.pravatar.cc/300"), // Ảnh mẫu
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              color: AppTheme.nearlyDarkBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Tran Thanh Long",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: AppTheme.darkerText),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "ttlonga03@gmai.com",
                      style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.grey),
                    ),
                    const SizedBox(height: 20),
                    // Button Chỉnh sửa
                    Padding(
                      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: OutlinedButton.icon(
                          onPressed: onEditProfile,
                          icon: const Icon(Icons.edit, size: 18, color: AppTheme.nearlyDarkBlue),
                          label: const Text("Chỉnh sửa thông tin cá nhân", 
                          style: TextStyle(color: AppTheme.nearlyDarkBlue, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.nearlyDarkBlue, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- WIDGET 2: CLASS SUBJECT ---
class ClassSubjectView extends StatefulWidget {
  final AnimationController animationController;
  final Animation<double> animation;
  final String className;

  const ClassSubjectView(
      {Key? key,
        required this.animationController,
        required this.animation,
        required this.className})
      : super(key: key);

  @override
  State<ClassSubjectView> createState() => _ClassSubjectViewState();
}

class _ClassSubjectViewState extends State<ClassSubjectView> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: widget.animation,
          child: Transform(
            transform: Matrix4.translationValues(
                0.0, 30 * (1.0 - widget.animation.value), 0.0),
            child: Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                        color: AppTheme.grey.withOpacity(0.2),
                        offset: const Offset(1.1, 1.1),
                        blurRadius: 10.0),
                  ],
                ),
                child: Column(
                  children: <Widget>[
                    InkWell(
                      onTap: () {
                        setState(() {
                          isExpanded = !isExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: <Widget>[
                            Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: AppTheme.nearlyDarkBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.class_, color: AppTheme.nearlyDarkBlue, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.className,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppTheme.darkerText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isExpanded ? "Nhấn để thu gọn" : "Nhấn để xem bài tập (3 mới)",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isExpanded ? AppTheme.nearlyBlue : AppTheme.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: AppTheme.grey),
                          ],
                        ),
                      ),
                    ),
                    // Danh sách bài tập
                    AnimatedCrossFade(
                      firstChild: Container(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
                        child: Column(
                          children: [
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            _buildExerciseItem("Bài tập 1: Thiết kế UI", "Đã nộp", Colors.green),
                            _buildExerciseItem("Bài tập 2: Animation Flutter", "Quá hạn", Colors.redAccent),
                            _buildExerciseItem("Bài tập 3: Tích hợp API", "Hạn: 25/5", Colors.orange),
                          ],
                        ),
                      ),
                      crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExerciseItem(String title, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_outlined, size: 20, color: AppTheme.grey),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(color: AppTheme.darkerText, fontWeight: FontWeight.w500)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}

// --- WIDGET 3: SCHEDULE CALENDAR ---
class ScheduleCalendarView extends StatelessWidget {
  final AnimationController animationController;
  final Animation<double> animation;

  const ScheduleCalendarView(
      {Key? key, required this.animationController, required this.animation})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: animation,
          child: Transform(
            transform: Matrix4.translationValues(
                0.0, 30 * (1.0 - animation.value), 0.0),
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 24, right: 24, top: 16, bottom: 32),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: const BorderRadius.all(Radius.circular(24.0)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                        color: AppTheme.grey.withOpacity(0.2),
                        offset: const Offset(1.1, 1.1),
                        blurRadius: 10.0),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.calendar_today, color: AppTheme.nearlyDarkBlue),
                              SizedBox(width: 8),
                              Text("Tháng 5, 2024",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.darkerText)),
                            ],
                          ),
                          Icon(Icons.more_horiz, color: AppTheme.grey.withOpacity(0.5))
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Thứ trong tuần
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: ["T2","T3","T4","T5","T6","T7","CN"].map((e) =>
                            Text(e, style: const TextStyle(color: AppTheme.grey, fontSize: 13, fontWeight: FontWeight.bold))
                        ).toList(),
                      ),
                      const SizedBox(height: 10),
                      // Grid lịch
                      GridView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 1,
                        ),
                        itemCount: 31, // Giả lập 31 ngày
                        itemBuilder: (context, index) {
                          int day = index + 1;
                          // Giả lập logic tô màu
                          bool isSchoolDay = (day == 15 || day == 20 || day == 22);
                          bool isDeadline = (day == 25 || day == 28);
                          bool isToday = (day == 18); // Giả sử hôm nay là 18

                          Color bgColor = Colors.transparent;
                          Color textColor = AppTheme.darkerText;
                          BoxBorder? border;

                          if (isSchoolDay) {
                            bgColor = AppTheme.nearlyDarkBlue;
                            textColor = Colors.white;
                          } else if (isDeadline) {
                            bgColor = Colors.redAccent;
                            textColor = Colors.white;
                          } else if (isToday) {
                            border = Border.all(color: AppTheme.nearlyBlue, width: 2);
                            textColor = AppTheme.nearlyBlue;
                          }

                          return Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: bgColor,
                              shape: BoxShape.circle,
                              border: border,
                            ),
                            child: Center(
                              child: Text(
                                "$day",
                                style: TextStyle(
                                    color: textColor,
                                    fontWeight: (isSchoolDay || isDeadline || isToday) ? FontWeight.bold : FontWeight.normal
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      // Chú thích
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(12)
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Row(children: const [
                              CircleAvatar(radius: 4, backgroundColor: AppTheme.nearlyDarkBlue),
                              SizedBox(width: 6),
                              Text("Đi học", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
                            ]),
                            Container(width: 1, height: 16, color: Colors.grey.withOpacity(0.4)),
                            Row(children: const [
                              CircleAvatar(radius: 4, backgroundColor: Colors.redAccent),
                              SizedBox(width: 6),
                              Text("Hạn nộp", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
                            ]),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}