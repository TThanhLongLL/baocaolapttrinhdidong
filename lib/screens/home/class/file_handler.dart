import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

// --- SERVICE UPLOAD FILE ---
class CloudinaryService {
  static const String cloudName = "dujejrg5i"; // Giữ nguyên của bạn
  static const String uploadPreset = "bacao1"; // Giữ nguyên của bạn

  static Future<String?> uploadFile(PlatformFile file) async {
    try {
      var uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/auto/upload");
      var request = http.MultipartRequest("POST", uri);

      request.fields['upload_preset'] = uploadPreset;
      request.fields['resource_type'] = 'auto'; // Tự động nhận diện (ảnh/video/pdf)

      // Xử lý bytes (quan trọng cho Web & Mobile)
      if (file.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ));
      } else if (file.path != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path!,
        ));
      }

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);
        var jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url']; // Trả về link file
      } else {
        print("Upload lỗi: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Lỗi upload: $e");
      return null;
    }
  }

  // Hàm mở link để tải xuống
  static Future<void> downloadFile(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Không thể mở link $url');
    }
  }
}

// --- MÀN HÌNH NỘP BÀI (CHO HỌC SINH) ---
class SubmissionScreen extends StatefulWidget {
  final String classId;
  final String postId;
  final String? accountId;
  final String? userName;

  const SubmissionScreen({
    Key? key,
    required this.classId,
    required this.postId,
    this.accountId,
    this.userName,
  }) : super(key: key);

  @override
  State<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends State<SubmissionScreen> {
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  bool _loadingState = true;
  bool _submitted = false;
  String? _submittedFileName;
  String? _submittedFileUrl;
  DateTime? _deadline;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn file!")));
      return;
    }

    setState(() => _isUploading = true);

    String? fileUrl = await CloudinaryService.uploadFile(_selectedFile!);

    if (fileUrl == null) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi upload file, thử lại sau!")));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final String submissionId = widget.accountId ?? user!.uid;

    await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('posts')
        .doc(widget.postId)
        .collection('submissions')
        .doc(submissionId)
        .set({
      'studentId': widget.accountId ?? user!.uid,
      'studentName': widget.userName ?? user!.displayName,
      'submittedAt': FieldValue.serverTimestamp(),
      'fileUrl': fileUrl,
      'fileName': _selectedFile!.name,
      'status': 'submitted',
    });

    setState(() {
      _isUploading = false;
      _submitted = true;
      _submittedFileName = _selectedFile!.name;
      _submittedFileUrl = fileUrl;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nộp bài thành công!"), backgroundColor: Colors.green));
    }
  }

  Future<void> _cancelSubmission() async {
    final user = FirebaseAuth.instance.currentUser;
    final String submissionId = widget.accountId ?? user!.uid;

    await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('posts')
        .doc(widget.postId)
        .collection('submissions')
        .doc(submissionId)
        .delete();

    setState(() {
      _submitted = false;
      _submittedFileName = null;
      _selectedFile = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã hủy nộp. Bạn có thể nộp lại.")));
    }
  }

  Future<void> _loadState() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final postSnap = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('posts')
        .doc(widget.postId)
        .get();
    if (postSnap.exists) {
      final data = postSnap.data() as Map<String, dynamic>;
      final deadlineTs = data['deadline'];
      if (deadlineTs is Timestamp) {
        _deadline = deadlineTs.toDate();
      }
    }

    final submissionSnap = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('posts')
        .doc(widget.postId)
        .collection('submissions')
        .doc(widget.accountId ?? user.uid)
        .get();

    if (submissionSnap.exists) {
      final data = submissionSnap.data() as Map<String, dynamic>;
      _submitted = true;
      _submittedFileName = data['fileName'] as String?;
      _submittedFileUrl = data['fileUrl'] as String?;
    }

    setState(() => _loadingState = false);
  }

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  bool _isDeadlinePassed() {
    if (_deadline == null) return false;
    return _deadline!.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final bool disableSubmit = _isUploading || _isDeadlinePassed();

    return Scaffold(
      appBar: AppBar(title: const Text("Nộp bài tập")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _loadingState
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_upload_outlined, size: 50, color: Colors.blue.shade300),
                        const SizedBox(height: 10),
                        const Text("Chọn tài liệu từ thiết bị", style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: (_isUploading || _isDeadlinePassed()) ? null : _pickFile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B8DEF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          child: const Text("Chọn File"),
                        ),
                        if (_deadline != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              "Hạn nộp: ${_deadline!.day}/${_deadline!.month}/${_deadline!.year}",
                              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_selectedFile != null)
                    ListTile(
                      leading: const Icon(Icons.attach_file, color: Colors.blue),
                      title: Text(_selectedFile!.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text("${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB"),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => setState(() => _selectedFile = null),
                      ),
                    ),
                  if (_submitted && _selectedFile == null)
                    ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: Text(_submittedFileName ?? "Đã nộp"),
                      subtitle: const Text("Trạng thái: Đã nộp"),
                      trailing: _submittedFileUrl != null && _submittedFileUrl!.isNotEmpty
                          ? IconButton(
                              tooltip: "Tải file đã nộp",
                              onPressed: () => CloudinaryService.downloadFile(_submittedFileUrl!),
                              icon: const Icon(Icons.cloud_download, color: Colors.blue),
                            )
                          : null,
                    ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: disableSubmit ? null : (_selectedFile == null ? null : _submit),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B8DEF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isDeadlinePassed()
                                  ? "Đã hết hạn"
                                  : _submitted
                                      ? "Nộp lại"
                                      : "NỘP BÀI",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  if (_isDeadlinePassed())
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Đã qua hạn nộp, bạn chỉ có thể tải file đã nộp.",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  if (_submitted && !_isDeadlinePassed())
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextButton.icon(
                        onPressed: _isUploading ? null : _cancelSubmission,
                        icon: const Icon(Icons.undo, color: Colors.redAccent),
                        label: const Text("Hủy nộp để nộp file khác", style: TextStyle(color: Colors.redAccent)),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
