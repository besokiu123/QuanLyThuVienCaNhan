import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../models/note_model.dart';

class NoteService {
  // ─── LẤY DANH SÁCH GHI CHÚ CỦA SÁCH ──────────────
  Future<List<NoteModel>> getNotesByBook(String bookId) async {
    try {
      final response = await ApiClient.dio.get('/note/$bookId');
      print('📥 Notes response: ${response.statusCode}');
      
      if (response.data == null) {
        return [];
      }
      
      if (response.data is List) {
        return (response.data as List)
            .map((e) => NoteModel.fromJson(e))
            .toList();
      }
      
      return [];
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      if (e.response?.statusCode == 404 || e.response?.statusCode == 500) {
        return [];
      }
      throw Exception('Không thể lấy danh sách ghi chú: ${e.message}');
    } catch (e) {
      print('❌ getNotesByBook error: $e');
      return [];
    }
  }

  // ─── THÊM GHI CHÚ MỚI ──────────────────────────────
  Future<NoteModel> addNote({
    required String bookId,
    required int soTrang,
    required String noiDung,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/note',
        data: {
          'bookId': bookId,
          'soTrang': soTrang,
          'noiDung': noiDung,
        },
      );
      return NoteModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Không thể thêm ghi chú: $e');
    }
  }

  // ─── CẬP NHẬT GHI CHÚ ──────────────────────────────
  Future<NoteModel> updateNote({
    required String noteId,
    required String noiDung,
  }) async {
    try {
      final response = await ApiClient.dio.put(
        '/note/$noteId',
        data: {'noiDung': noiDung},
      );
      return NoteModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Không thể cập nhật ghi chú: $e');
    }
  }

  // ─── XÓA GHI CHÚ ────────────────────────────────────
  Future<void> deleteNote(String noteId) async {
    try {
      await ApiClient.dio.delete('/note/$noteId');
    } catch (e) {
      throw Exception('Không thể xóa ghi chú: $e');
    }
  }
}