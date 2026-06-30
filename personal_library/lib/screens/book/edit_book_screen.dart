import 'dart:io';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/book_model.dart';
import '../../models/category_model.dart';
import '../../services/book_service.dart';
import '../../services/category_service.dart';

class EditBookScreen extends StatefulWidget {
  final BookModel book;

  const EditBookScreen({
    super.key,
    required this.book,
  });

  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  final bookService = BookService();
  final categoryService = CategoryService();

  late TextEditingController titleController;
  late TextEditingController authorController;
  late TextEditingController yearController;
  late TextEditingController pageController;
  late TextEditingController descController;

  List<CategoryModel> categories = [];
  String? selectedCategoryId;

  File? coverImage;
  File? bookFile; // 🔥 Đổi sang File
  String? bookFileName;
  int? bookFileSize;
  bool _isLoading = false;
  int _totalPages = 0;
  bool _isAutoFilled = false;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.book.tieuDe);
    authorController = TextEditingController(text: widget.book.tacGia);
    yearController = TextEditingController(
      text: widget.book.namXuatBan?.toString() ?? "",
    );
    pageController = TextEditingController(
      text: widget.book.tongSoTrang?.toString() ?? "",
    );
    descController = TextEditingController(text: widget.book.moTa ?? "");
    _totalPages = widget.book.tongSoTrang ?? 0;

    selectedCategoryId = widget.book.categoryId;

    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      categories = await categoryService.getAllCategory();
      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (picked != null) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_cover.jpg';
        final newFile = File('${appDir.path}/$fileName');
        
        final sourceFile = File(picked.path);
        await sourceFile.copy(newFile.path);
        
        setState(() {
          coverImage = newFile;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 🔥 ĐẾM SỐ TRANG PDF
  Future<int> _countPdfPages(String path) async {
    try {
      final bytes = File(path).readAsBytesSync();
      final doc = PdfDocument(inputBytes: bytes);
      final pages = doc.pages.count;
      doc.dispose();
      return pages;
    } catch (e) {
      print("❌ Lỗi đếm trang PDF: $e");
      return 0;
    }
  }

  // 🔥 ĐẾM SỐ TRANG EPUB
  Future<int> _countEpubPages(String path) async {
    try {
      final bytes = File(path).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      int count = 0;
      for (final file in archive.files) {
        if (!file.isFile) continue;
        final name = file.name.toLowerCase();
        if (name.endsWith(".xhtml") ||
            name.endsWith(".html") ||
            name.endsWith(".htm")) {
          final html = utf8.decode(file.content);
          count += (html.length / 2500).ceil();
        }
      }
      return count;
    } catch (e) {
      print("❌ Lỗi đếm trang EPUB: $e");
      return 0;
    }
  }

  // 🔥 TỰ ĐỘNG ĐIỀN THÔNG TIN TỪ FILE
  Future<void> _autoFillFromFile(String filePath, String fileName, String ext) async {
    // Lấy tên sách từ tên file
    String name = fileName;
    if (name.contains('.')) {
      name = name.substring(0, name.lastIndexOf('.'));
    }
    
    if (titleController.text.isEmpty || titleController.text == widget.book.tieuDe) {
      titleController.text = name;
    }
  }

  Future<void> pickBook() async {
    final result = await FilePicker.platform.pickFiles();

    if (result == null) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${result.files.first.name}';
      final newFile = File('${appDir.path}/$fileName');
      
      final sourceFile = File(result.files.first.path!);
      await sourceFile.copy(newFile.path);
      
      final file = result.files.first;
      final ext = file.extension?.toLowerCase();

      setState(() {
        bookFile = newFile;
        bookFileName = file.name;
        bookFileSize = file.size;
        _isLoading = true;
      });

      // 🔥 TỰ ĐỘNG ĐIỀN TÊN SÁCH
      await _autoFillFromFile(newFile.path, file.name, ext ?? '');

      // Đếm số trang
      int pageCount = 0;
      if (ext == 'pdf') {
        pageCount = await _countPdfPages(newFile.path);
      } else if (ext == 'epub') {
        pageCount = await _countEpubPages(newFile.path);
      } else {
        pageCount = 0;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Định dạng file không hỗ trợ (chỉ PDF, EPUB)'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      setState(() {
        _totalPages = pageCount;
        pageController.text = pageCount.toString();
        _isLoading = false;
        _isAutoFilled = true;
      });

      if (pageCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã đếm được $pageCount trang và cập nhật số trang'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> updateBook() async {
    final title = titleController.text.trim();
    final author = authorController.text.trim();
    final year = yearController.text.trim();
    final pages = pageController.text.trim();
    final description = descController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề')),
      );
      return;
    }

    if (author.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tác giả')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await bookService.updateBook(
        id: widget.book.id,
        title: title,
        author: author,
        year: year,
        pages: pages,
        description: description,
        categoryId: selectedCategoryId,
        imagePath: coverImage?.path,
        bookPath: bookFile?.path,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Cập nhật thành công"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Lỗi: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Sửa sách",
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
                  Text('Đang xử lý...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ===== ẢNH BÌA =====
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
                            : widget.book.anhBia != null
                                ? DecorationImage(
                                    image: NetworkImage(widget.book.anhBia!),
                                    fit: BoxFit.cover,
                                    onError: (_, __) {},
                                  )
                                : null,
                      ),
                      child: coverImage == null && widget.book.anhBia == null
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
                                  'Chọn ảnh bìa mới',
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

                  // ===== HIỂN THỊ TRẠNG THÁI =====
                  if (_isAutoFilled) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '✅ Đã tự động cập nhật số trang từ file mới',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ===== FORM =====
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
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Tiêu đề *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.title, color: Color(0xFF4A5D4E)),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF4A5D4E)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: authorController,
                          decoration: const InputDecoration(
                            labelText: 'Tác giả *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person, color: Color(0xFF4A5D4E)),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF4A5D4E)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          value: selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Thể loại',
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

                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: yearController,
                                decoration: const InputDecoration(
                                  labelText: 'Năm XB',
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
                                  border: Border.all(color: _totalPages > 0 ? Colors.green : Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.pages,
                                      color: _totalPages > 0 ? Colors.green : const Color(0xFF4A5D4E),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _totalPages > 0 ? '$_totalPages trang' : '... trang',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _totalPages > 0 ? Colors.black : Colors.grey[400],
                                        fontWeight: _totalPages > 0 ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: descController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Mô tả',
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

                  // ===== CHỌN FILE SÁCH =====
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
                                  bookFile == null ? 'Đổi file sách' : 'File đã chọn',
                                  style: TextStyle(
                                    color: bookFile == null ? Colors.grey[600] : Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                if (bookFile != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    bookFileName ?? '...',
                                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${((bookFileSize ?? 0) / 1024 / 1024).toStringAsFixed(2)} MB',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                  ),
                                ] else if (widget.book.fileUrl != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'File hiện tại: ${widget.book.fileUrl!.split('/').last}',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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

                  // ===== NÚT CẬP NHẬT =====
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: updateBook,
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
                        'Cập nhật sách',
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