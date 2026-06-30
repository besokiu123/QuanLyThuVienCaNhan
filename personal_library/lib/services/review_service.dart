import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../models/review_model.dart';

class ReviewService {
  // ─── LẤY DANH SÁCH ĐÁNH GIÁ CỦA SÁCH ──────────
  Future<List<ReviewModel>> getReviewsByBook(String bookId) async {
    try {
      final response = await ApiClient.dio.get('/review/$bookId');
      final data = response.data as List? ?? [];
      return data.map((e) => ReviewModel.fromJson(e)).toList();
    } catch (e) {
      print('❌ getReviewsByBook error: $e');
      return [];
    }
  }

  // ─── LƯU ĐÁNH GIÁ ──────────────────────────────
  Future<ReviewModel> saveReview({
    required String bookId,
    required int soSao,
    required String nhanXet,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/review',
        data: {
          'bookId': bookId,
          'soSao': soSao,
          'nhanXet': nhanXet,
        },
      );
      return ReviewModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Không thể lưu đánh giá: $e');
    }
  }

  // ─── XÓA ĐÁNH GIÁ ──────────────────────────────
  Future<void> deleteReview(String reviewId) async {
    try {
      await ApiClient.dio.delete('/review/$reviewId');
    } catch (e) {
      throw Exception('Không thể xóa đánh giá: $e');
    }
  }

  // ─── LẤY ĐÁNH GIÁ CỦA USER HIỆN TẠI ────────────
  Future<ReviewModel?> getMyReview(String bookId) async {
    try {
      final reviews = await getReviewsByBook(bookId);
      // Lấy review của user hiện tại (sẽ được xử lý backend)
      // Tạm thời lấy review đầu tiên nếu có
      return reviews.isNotEmpty ? reviews.first : null;
    } catch (e) {
      return null;
    }
  }
}