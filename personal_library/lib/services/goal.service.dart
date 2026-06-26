import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../core/network/api_client.dart';

class GoalService {
  // ─── ĐẶT MỤC TIÊU ──────────────────────────────────
  Future<void> setGoal({
    required int nam,
    required int soLuongSach,
  }) async {
    try {
      final body = {
        'nam': nam,
        'soLuongSach': soLuongSach,
      };
      
      debugPrint('📤 setGoal: $body');
      
      await ApiClient.dio.post('/goal', data: body);
      debugPrint('✅ setGoal OK');
    } catch (e) {
      debugPrint('❌ setGoal error: $e');
      throw Exception('Không thể đặt mục tiêu: $e');
    }
  }

  // ─── LẤY TIẾN ĐỘ MỤC TIÊU ──────────────────────────
  Future<Map<String, dynamic>> getMyProgress(int nam) async {
    try {
      final response = await ApiClient.dio.get('/goal/$nam');
      final data = response.data as Map<String, dynamic>? ?? {};
      
      debugPrint('📥 getMyProgress: $data');
      
      return {
        'nam': data['nam'] ?? nam,
        'mucTieu': data['mucTieu'] ?? 0,
        'daHoanThanh': data['daHoanThanh'] ?? 0,
        'phanTram': data['phanTram'] ?? 0,
        'conLai': data['conLai'] ?? 0,
        'ngayHoanThanh': data['ngay_hoan_thanh'],
      };
    } catch (e) {
      debugPrint('❌ getMyProgress error: $e');
      return {
        'nam': nam,
        'mucTieu': 0,
        'daHoanThanh': 0,
        'phanTram': 0,
        'conLai': 0,
        'ngayHoanThanh': null,
      };
    }
  }
}