import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../models/highlight_model.dart';

class HighlightService {
  // ─── LẤY DANH SÁCH HIGHLIGHT ──────────────────────
  Future<List<HighlightModel>> getHighlightsByBook(String bookId) async {
    try {
      final response = await ApiClient.dio.get('/highlights/book/$bookId');
      print('📥 Highlights response: ${response.statusCode}');
      
      // Kiểm tra response có data không
      if (response.data == null) {
        return [];
      }
      
      // Nếu response là Map và có key 'data'
      if (response.data is Map) {
        final data = response.data['data'];
        if (data is List) {
          return data.map((e) => HighlightModel.fromJson(e)).toList();
        }
        return [];
      }
      
      // Nếu response là List trực tiếp
      if (response.data is List) {
        return (response.data as List)
            .map((e) => HighlightModel.fromJson(e))
            .toList();
      }
      
      return [];
    } on DioException catch (e) {
      // 🔥 XỬ LÝ LỖI API
      print('❌ DioException: ${e.message}');
      print('❌ Status code: ${e.response?.statusCode}');
      print('❌ Response data: ${e.response?.data}');
      
      // Nếu lỗi 404 hoặc 500, trả về danh sách rỗng
      if (e.response?.statusCode == 404 || e.response?.statusCode == 500) {
        return [];
      }
      
      // Ném lỗi để xử lý ở nơi gọi
      throw Exception('Không thể lấy danh sách highlight: ${e.message}');
    } catch (e) {
      print('❌ getHighlightsByBook error: $e');
      return []; // Trả về rỗng thay vì throw
    }
  }

  // ─── THÊM HIGHLIGHT MỚI ──────────────────────────
  Future<HighlightModel> addHighlight({
    required String bookId,
    required String cfi,
    required String text,
    required String color,
    String? note,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/highlights',
        data: {
          'bookId': bookId,
          'cfi': cfi,
          'text': text,
          'color': color,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      return HighlightModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Không thể thêm highlight: $e');
    }
  }

  // ─── XÓA HIGHLIGHT ────────────────────────────────
  Future<void> deleteHighlight(String highlightId) async {
    try {
      await ApiClient.dio.delete('/highlights/$highlightId');
    } catch (e) {
      throw Exception('Không thể xóa highlight: $e');
    }
  }
}