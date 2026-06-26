import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/book_model.dart';

class ReadingService {
  // ─── GET PROGRESS ────────────────────────────────
  Future<Map<String, dynamic>> getProgress(String bookId) async {
    try {
      final res = await ApiClient.dio.get('/reading/progress/$bookId');
      final data = res.data as Map<String, dynamic>? ?? {};

      debugPrint('📥 getProgress: $data');

      return {
        'trang_hien_tai': (data['trang_hien_tai'] as int?) ?? 0,
        'epubCfi': data['epubCfi'] as String?,
      };
    } catch (e) {
      debugPrint('❌ getProgress error: $e');
      return {'trang_hien_tai': 0, 'epubCfi': null};
    }
  }

  // ─── SAVE PROGRESS ───────────────────────────────
  Future<void> saveProgress({
    required String bookId,
    required int trangHienTai,
    String? epubCfi,
  }) async {
    try {
      final body = <String, dynamic>{
        'bookId': bookId,
        'trangHienTai': trangHienTai,
        if (epubCfi != null && epubCfi.isNotEmpty) 'epubCfi': epubCfi,
      };

      debugPrint('📤 saveProgress: $body');

      await ApiClient.dio.post('/reading/progress', data: body);
      debugPrint('✅ saveProgress OK');
    } catch (e) {
      debugPrint('❌ saveProgress error: $e');
    }
  }

  // ─── SAVE SESSION ────────────────────────────────
  Future<void> saveSession({
    required String bookId,
    required int startPage,
    required int endPage,
    required int minutes,
  }) async {
    if (minutes < 1 || endPage <= startPage) return;

    try {
      // 🔥 SỬA: dùng 'trangBatDau' thay vì 'trangHienTai'
      final body = {
        'bookId': bookId,
        'trangBatDau': startPage, // ✅ ĐÚNG
        'trangKetThuc': endPage,
        'phut': minutes,
      };
      debugPrint('📤 saveSession: $body');
      await ApiClient.dio.post('/session', data: body);
      debugPrint('✅ saveSession OK');
    } catch (e) {
      debugPrint('❌ saveSession error: $e');
    }
  }

  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await ApiClient.dio.get('/stats');
      final data = response.data as Map<String, dynamic>? ?? {};

      debugPrint('📥 getUserStats: $data');

      return {
        'totalReading': data['totalReading'] ?? 0,
        'totalCompleted': data['totalCompleted'] ?? 0,
        'totalMinutes': data['totalMinutes'] ?? 0,
        'totalPages': data['totalPages'] ?? 0,
        'readingHistory': data['readingHistory'] ?? [],
        'genreStats': data['genreStats'] ?? {},
      };
    } catch (e) {
      debugPrint('❌ getUserStats error: $e');
      return {
        'totalReading': 0,
        'totalCompleted': 0,
        'totalMinutes': 0,
        'totalPages': 0,
        'readingHistory': [],
        'genreStats': {},
      };
    }
  }
  // services/reading_service.dart

  // 🔥 Lấy sách đang đọc
  Future<List<BookModel>> getReadingBooks() async {
    try {
      // Gọi API lấy danh sách sách đang đọc
      final response = await ApiClient.dio.get('/books/reading');
      final data = response.data['data'] as List? ?? [];
      return data.map((e) => BookModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('❌ getReadingBooks error: $e');
      return [];
    }
  }

  // 🔥 Lấy sách đã đọc
  Future<List<BookModel>> getCompletedBooks() async {
    try {
      final response = await ApiClient.dio.get('/books/completed');
      final data = response.data['data'] as List? ?? [];
      return data.map((e) => BookModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('❌ getCompletedBooks error: $e');
      return [];
    }
  }
}
