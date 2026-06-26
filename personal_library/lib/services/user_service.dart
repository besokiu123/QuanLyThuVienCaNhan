import 'dart:io';
import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../models/user_model.dart';

class UserService {
  // ─── LẤY THÔNG TIN CÁ NHÂN ──────────────────────
  Future<UserModel> getProfile() async {
    try {
      final response = await ApiClient.dio.get('/users/profile');
      return UserModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Không thể lấy thông tin: $e');
    }
  }

  // ─── CẬP NHẬT THÔNG TIN ─────────────────────────
  Future<UserModel> updateProfile({
    required String tenHienThi,
    String? anhDaiDien,
  }) async {
    try {
      final data = <String, dynamic>{
        'ten_hien_thi': tenHienThi,
      };
      if (anhDaiDien != null && anhDaiDien.isNotEmpty) {
        data['anh_dai_dien'] = anhDaiDien;
      }

      final response = await ApiClient.dio.put('/users/profile', data: data);
      return UserModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Không thể cập nhật: $e');
    }
  }

  // ─── ĐỔI MẬT KHẨU ─────────────────────────────────
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await ApiClient.dio.post('/users/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
    } catch (e) {
      throw Exception('Không thể đổi mật khẩu: $e');
    }
  }

  // ─── UPLOAD ẢNH ĐẠI DIỆN ─────────────────────────
  Future<String> uploadAvatar(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(imageFile.path),
      });
      final response = await ApiClient.dio.post(
        '/users/upload-avatar',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
      return response.data['data']['avatar_url'];
    } catch (e) {
      throw Exception('Không thể upload ảnh: $e');
    }
  }


Future<List<UserModel>> getAllUsers() async {
  try {
    print('📤 ===== UserService.getAllUsers =====');
    
    final response = await ApiClient.dio.get('/users');
    print('📥 Status: ${response.statusCode}');
    print('📥 Data: ${response.data}');
    
    final data = response.data['data'] as List? ?? [];
    print('📥 Data length: ${data.length}');
    
    final users = data.map((e) => UserModel.fromJson(e)).toList();
    print('📥 Users parsed: ${users.length}');
    print('📥 First user: ${users.isNotEmpty ? users[0].tenHienThi : 'empty'}');
    
    return users;
  } catch (e) {
    print('❌ getAllUsers error: $e');
    if (e is DioException) {
      print('❌ Response: ${e.response?.data}');
      print('❌ Status: ${e.response?.statusCode}');
    }
    throw Exception('Không thể lấy danh sách: $e');
  }
}

  // ─── CẬP NHẬT VAI TRÒ (CHỈ THU_THU) ──────────────
  Future<UserModel> updateUserRole({
    required String userId,
    required String vaiTro,
  }) async {
    try {
      final response = await ApiClient.dio.patch(
        '/users/$userId/role',
        data: {'vai_tro': vaiTro},
      );
      return UserModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Không thể cập nhật vai trò: $e');
    }
  }

  // ─── XÓA NGƯỜI DÙNG (CHỈ THU_THU) ────────────────
  Future<void> deleteUser(String userId) async {
    try {
      await ApiClient.dio.delete('/users/$userId');
    } catch (e) {
      throw Exception('Không thể xóa người dùng: $e');
    }
  }
}