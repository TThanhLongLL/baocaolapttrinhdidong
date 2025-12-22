import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String apiKey = 'AIzaSyBPZHG7twcf7doPkcwOb6PF3zzocECJMEU';
  late final GenerativeModel _model;
  bool _isConnected = false;

  GeminiService() {
    _model = GenerativeModel(
      model: 'models/gemini-flash-latest',
      apiKey: apiKey,
    );
  }

  // Kiểm tra kết nối
  Future<bool> checkConnection() async {
    try {
      final content = [Content.text('Xin chào')];
      final response = await _model.generateContent(content);
      _isConnected = response.text != null;
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      print('Lỗi kết nối: $e');
      return false;
    }
  }

  // Lấy trạng thái kết nối
  bool get isConnected => _isConnected;

  Future<String> sendMessage(String message) async {
    try {
      final content = [Content.text(message)];
      final response = await _model.generateContent(content);
      return response.text ?? 'Không có phản hồi';
    } catch (e) {
      return 'Lỗi: ${e.toString()}';
    }
  }
}