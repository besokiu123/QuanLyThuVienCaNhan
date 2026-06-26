import 'package:dio/dio.dart';
import '../models/dashboard_stats.dart';
import '../core/network/api_client.dart';

class AdminService {
  Future<DashboardStats> getStats() async {
    // Đảm bảo URL route này đã được định nghĩa trong Router của Express
    final response = await ApiClient.dio.get('/stats/admin-dashboard');
    return DashboardStats.fromJson(response.data['data']);
  }
}
