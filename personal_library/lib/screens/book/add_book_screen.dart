import 'dart:io';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/book_service.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final yearController = TextEditingController();
  final descController = TextEditingController();

  int totalPages = 0;
  String? selectedCategoryId;
  List<CategoryModel> categories = [];
  File? coverImage;
  PlatformFile? bookFile;
  bool _isLoading = false;
  bool _isTitleDuplicate = false;

  final categoryService = CategoryService();
  final bookService = BookService();

  @override
  void initState() {
    super.initState();
    loadCategories();
    titleController.addListener(_checkTitleDuplicate);
  }

  @override
  void dispose() {
    titleController.dispose();
    authorController.dispose();
    yearController.dispose();
    descController.dispose();
    titleController.removeListener(_checkTitleDuplicate);
    super.dispose();
  }

  Future<void> loadCategories() async {
    try {
      categories = await categoryService.getAllCategory();
      setState(() {});
    } catch (e) {
      print('❌ Load categories error: $e');
    }
  }

  // 🔥 KIỂM TRA TRÙNG TÊN SÁCH
  void _checkTitleDuplicate() {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _isTitleDuplicate = false);
      return;
    }

    // Kiểm tra với danh sách sách hiện có (có thể gọi API)
    // Ở đây tôi giả sử có danh sách sách từ service
    _checkTitleExists(title);
  }

  Future<void> _checkTitleExists(String title) async {
    try {
      final books = await bookService.getAllBooks();
      final exists = books.any((book) => 
        book.tieuDe.toLowerCase() == title.toLowerCase()
      );
      if (mounted) {
        setState(() => _isTitleDuplicate = exists);
      }
    } catch (e) {
      print('❌ Check title error: $e');
    }
  }

  // 🔥 VALIDATE TẤT CẢ
  bool _validate() {
    // 1. Kiểm tra tiêu đề
    if (titleController.text.trim().isEmpty) {
      _showSnackbar('⚠️ Vui lòng nhập tiêu đề sách', Colors.orange);
      return false;
    }

    // 2. Kiểm tra trùng tên
    if (_isTitleDuplicate) {
      _showSnackbar('⚠️ Tiêu đề sách đã tồn tại!', Colors.orange);
      return false;
    }

    // 3. Kiểm tra tác giả
    if (authorController.text.trim().isEmpty) {
      _showSnackbar('⚠️ Vui lòng nhập tác giả', Colors.orange);
      return false;
    }

    // 4. Kiểm tra tác giả (không chứa số)
    final author = authorController.text.trim();
    if (RegExp(r'\d').hasMatch(author)) {
      _showSnackbar('⚠️ Tác giả không được chứa số', Colors.orange);
      return false;
    }

    // 5. Kiểm tra thể loại
    if (selectedCategoryId == null) {
      _showSnackbar('⚠️ Vui lòng chọn thể loại', Colors.orange);
      return false;
    }

    // 6. Kiểm tra năm xuất bản
    final year = yearController.text.trim();
    if (year.isNotEmpty) {
      final yearInt = int.tryParse(year);
      if (yearInt == null || yearInt < 1000 || yearInt > DateTime.now().year) {
        _showSnackbar('⚠️ Năm xuất bản không hợp lệ (1000-${DateTime.now().year})', Colors.orange);
        return false;
      }
    }

    // 7. Kiểm tra ảnh bìa
    if (coverImage == null) {
      _showSnackbar('⚠️ Vui lòng chọn ảnh bìa', Colors.orange);
      return false;
    }

    // 8. Kiểm tra file sách
    if (bookFile == null) {
      _showSnackbar('⚠️ Vui lòng chọn file sách', Colors.orange);
      return false;
    }

    // 9. Kiểm tra số trang
    if (totalPages <= 0) {
      _showSnackbar('⚠️ File sách không có trang hoặc bị lỗi', Colors.orange);
      return false;
    }

    return true;
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => coverImage = File(picked.path));
    }
  }

  Future<void> pickBook() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    bookFile = result.files.first;
    final ext = bookFile!.extension?.toLowerCase();

    try {
      if (ext == 'pdf') {
        totalPages = await _countPdfPages(bookFile!.path!);
      } else if (ext == 'epub') {
        totalPages = await _countEpubPages(bookFile!.path!);
      } else {
        totalPages = 0;
        _showSnackbar('⚠️ Định dạng file không hỗ trợ (chỉ PDF, EPUB)', Colors.orange);
      }
      setState(() {});
    } catch (e) {
      print("❌ Lỗi đếm trang: $e");
      totalPages = 0;
      _showSnackbar('❌ Lỗi đọc file: $e', Colors.red);
    }
  }

  Future<int> _countPdfPages(String path) async {
    try {
      final bytes = File(path).readAsBytesSync();
      final doc = PdfDocument(inputBytes: bytes);
      final pages = doc.pages.count;
      doc.dispose();
      return pages;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _countEpubPages(String path) async {
    try {
      final bytes = File(path).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      int count = 0;
      for (final file in archive.files) {
        if (!file.isFile) continue;
        final name = file.name.toLowerCase();
        if (name.endsWith(".xhtml") || name.endsWith(".html") || name.endsWith(".htm")) {
          final html = utf8.decode(file.content);
          count += (html.length / 2500).ceil();
        }
      }
      return count;
    } catch (e) {
      return 0;
    }
  }

  Future<void> saveBook() async {
    // 🔥 GỌI VALIDATE
    if (!_validate()) return;

    setState(() => _isLoading = true);

    try {
      await bookService.addBook(
        title: titleController.text.trim(),
        author: authorController.text.trim(),
        categoryId: selectedCategoryId!,
        year: yearController.text.trim().isEmpty ? '2024' : yearController.text.trim(),
        pages: totalPages.toString(),
        description: descController.text.trim(),
        imagePath: coverImage!.path,
        bookPath: bookFile!.path!,
      );

      _showSnackbar('✅ Thêm sách thành công!', Colors.green);
      Navigator.pop(context, true);
    } catch (e) {
      print('❌ Save error: $e');
      _showSnackbar('❌ Lỗi: $e', Colors.red);
      setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Thêm sách mới',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Color(0xFF4A5D4E),
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF4A5D4E)),
                  SizedBox(height: 16),
                  Text(
                    'Đang thêm sách...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ===== Ảnh bìa =====
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: coverImage == null ? Colors.grey[300]! : Colors.transparent,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        image: coverImage != null
                            ? DecorationImage(
                                image: FileImage(coverImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: coverImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Chọn ảnh bìa *',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ===== Form =====
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Tiêu đề
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: titleController,
                              decoration: InputDecoration(
                                labelText: 'Tiêu đề *',
                                labelStyle: TextStyle(
                                  color: _isTitleDuplicate ? Colors.red : Colors.grey,
                                ),
                                border: const OutlineInputBorder(),
                                prefixIcon: Icon(
                                  Icons.title,
                                  color: _isTitleDuplicate ? Colors.red : const Color(0xFF4A5D4E),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _isTitleDuplicate ? Colors.red : const Color(0xFF4A5D4E),
                                  ),
                                ),
                                errorText: _isTitleDuplicate ? 'Tiêu đề đã tồn tại' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Tác giả
                        TextField(
                          controller: authorController,
                          decoration: const InputDecoration(
                            labelText: 'Tác giả *',
                            labelStyle: TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person, color: Color(0xFF4A5D4E)),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF4A5D4E)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Thể loại
                        DropdownButtonFormField<String>(
                          value: selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Thể loại *',
                            labelStyle: TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category, color: Color(0xFF4A5D4E)),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF4A5D4E)),
                            ),
                          ),
                          items: categories.map((item) {
                            return DropdownMenuItem(
                              value: item.id,
                              child: Text(item.tenTheLoai),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => selectedCategoryId = value);
                          },
                          hint: const Text('Chọn thể loại'),
                          isExpanded: true,
                        ),
                        const SizedBox(height: 12),

                        // Năm xuất bản + Số trang
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: yearController,
                                decoration: const InputDecoration(
                                  labelText: 'Năm XB',
                                  labelStyle: TextStyle(color: Colors.grey),
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF4A5D4E), size: 20),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFF4A5D4E)),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: totalPages > 0 ? Colors.green : Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.pages,
                                      color: totalPages > 0 ? Colors.green : const Color(0xFF4A5D4E),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      totalPages > 0 ? '$totalPages trang' : '... trang',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: totalPages > 0 ? Colors.black : Colors.grey[400],
                                        fontWeight: totalPages > 0 ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Mô tả
                        TextField(
                          controller: descController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Mô tả',
                            labelStyle: TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description, color: Color(0xFF4A5D4E)),
                            alignLabelWithHint: true,
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF4A5D4E)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ===== Chọn file sách =====
                  InkWell(
                    onTap: pickBook,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A5D4E).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              bookFile == null ? Icons.upload_file : Icons.check_circle,
                              color: bookFile == null ? const Color(0xFF4A5D4E) : Colors.green,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bookFile == null ? 'Chọn file sách *' : 'File đã chọn',
                                  style: TextStyle(
                                    color: bookFile == null ? Colors.grey[600] : Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                if (bookFile != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    bookFile!.name,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${(bookFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey[400],
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ===== Nút lưu =====
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saveBook,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A5D4E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Lưu sách',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}