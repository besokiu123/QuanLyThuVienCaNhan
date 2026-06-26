import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/book_model.dart';

class BookService {
  Future<List<BookModel>> getAllBooks() async {
  try {
    final response = await ApiClient.dio.get('/books');
    final data = response.data;
    if (data == null) return [];
    
    // Lấy danh sách sách (có thể đã include the_loai)
    final list = data['data'] ?? data;
    if (list is! List) return [];
    
    return list.map((e) => BookModel.fromJson(e)).toList();
  } catch (e) {
    debugPrint('❌ getAllBooks error: $e');
    return [];
  }
}

  Future<Response> deleteBook(String id) async {
    return await ApiClient.dio.delete('/books/$id');
  }

  Future<Response> addBook({
    required String title,
    required String author,
    required String categoryId,
    required String year,
    required String pages,
    required String description,
    required String imagePath,
    required String bookPath,
  }) async {
    FormData formData = FormData.fromMap({
      "tieu_de": title,
      "tac_gia": author,
      "the_loai_id": categoryId,
      "nam_xuat_ban": year,
      "tong_so_trang": pages,
      "mo_ta": description,

      "anh_bia": await MultipartFile.fromFile(imagePath),

      "file_sach": await MultipartFile.fromFile(bookPath),
    });

    return await ApiClient.dio.post("/books/", data: formData);
  }

  Future<Response> updateBook({
    required String id,
    required String title,
    required String author,
    required String year,
    required String pages,
    required String description,
    String? categoryId,
    String? imagePath,
    String? bookPath,
  }) async {
    FormData formData = FormData.fromMap({
      "tieu_de": title,
      "tac_gia": author,
      "nam_xuat_ban": year,
      "tong_so_trang": pages,
      "mo_ta": description,
      "the_loai_id": categoryId,
    });

    if (imagePath != null) {
      formData.files.add(
        MapEntry("anh_bia", await MultipartFile.fromFile(imagePath)),
      );
    }

    if (bookPath != null) {
      formData.files.add(
        MapEntry("file_sach", await MultipartFile.fromFile(bookPath)),
      );
    }

    return await ApiClient.dio.patch("/books/$id", data: formData);
  }

  Future<BookModel> getBookDetail(String id) async {
    final response = await ApiClient.dio.get('/books/$id');

    return BookModel.fromJson(response.data);
  }
}
