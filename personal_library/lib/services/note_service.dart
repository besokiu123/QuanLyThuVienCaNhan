import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../models/note_model.dart';

class NoteService {
  // ─── LẤY DANH SÁCH GHI CHÚ CỦA SÁCH ──────────────
  Future<List<NoteModel>> getNotesByBook(String bookId) async {
    try {
      final response = await ApiClient.dio.get('/note/$bookId');
      final data = response.data as List? ?? [];
      return data.map((e) => NoteModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Không thể lấy danh sách ghi chú: $e');
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