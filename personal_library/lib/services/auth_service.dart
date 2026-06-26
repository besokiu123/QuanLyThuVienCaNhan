import 'package:dio/dio.dart';
import '../core/network/api_client.dart';

class AuthService {
  // ─── LOGIN ─────────────────────────────────────────
  Future<Response> login(String email, String password) async {
    return await ApiClient.dio.post(
      "/auth/login",
      data: {"email": email, "password": password},
    );
  }

  // ─── REGISTER ──────────────────────────────────────
  Future<Response> register(String email, String password, String tenHienThi) async {
    return await ApiClient.dio.post(
      "/auth/register",
      data: {
        "email": email,
        "password": password,
        "ten_hien_thi": tenHienThi,
      },
    );
  }
}