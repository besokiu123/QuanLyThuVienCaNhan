import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../models/category_model.dart';

class CategoryService {
  Future<List<CategoryModel>> getAllCategory() async {
    final response = await ApiClient.dio.get('/theLoai');

    final rawData = response.data;
    final list = rawData is Map<String, dynamic> ? rawData['data'] : rawData;

    return (list as List).map((e) => CategoryModel.fromJson(e)).toList();
  }

  Future<Response> addCategory(String tenTheLoai, String moTa) async {
    return await ApiClient.dio.post(
      '/theLoai',
      data: {"ten_the_loai": tenTheLoai, "mo_ta": moTa},
    );
  }

  Future<Response> deleteCategory(String id) async {
    return await ApiClient.dio.delete('/theLoai/$id');
  }

  Future<Response> updateCategory(
    String id,
    String tenTheLoai,
    String moTa,
  ) async {
    return await ApiClient.dio.put(
      '/theLoai/$id',
      data: {"ten_the_loai": tenTheLoai, "mo_ta": moTa},
    );
  }
}
