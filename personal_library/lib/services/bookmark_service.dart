import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../models/bookmark_model.dart';

class BookmarkService {
  // ─── LẤY DANH SÁCH BOOKMARK CỦA SÁCH ────────────
  Future<List<BookmarkModel>> getBookmarksByBook(String bookId) async {
    try {
      final response = await ApiClient.dio.get('/danhDauTrang/book/$bookId');
      final data = response.data as List? ?? [];
      return data.map((e) => BookmarkModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('❌ getBookmarksByBook error: $e');
      return [];
    }
  }

  // ─── THÊM BOOKMARK ─────────────────────────────────
  Future<BookmarkModel> addBookmark({
    required String bookId,
    required int soTrang,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/danhDauTrang/add',
        data: {
          'bookId': bookId,
          'soTrang': soTrang,
        },
      );
      return BookmarkModel.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ addBookmark error: $e');
      throw Exception('Không thể thêm đánh dấu trang: $e');
    }
  }

  // ─── XÓA BOOKMARK ──────────────────────────────────
  Future<void> deleteBookmark(String bookmarkId) async {
    try {
      await ApiClient.dio.delete('/danhDauTrang/delete/$bookmarkId');
      debugPrint('✅ deleteBookmark OK');
    } catch (e) {
      debugPrint('❌ deleteBookmark error: $e');
      throw Exception('Không thể xóa đánh dấu trang: $e');
    }
  }

  // ─── KIỂM TRA ĐÃ BOOKMARK CHƯA ────────────────────
  Future<bool> isBookmarked({
    required String bookId,
    required int soTrang,
  }) async {
    try {
      final bookmarks = await getBookmarksByBook(bookId);
      return bookmarks.any((b) => b.soTrang == soTrang);
    } catch (e) {
      debugPrint('❌ isBookmarked error: $e');
      return false;
    }
  }
}