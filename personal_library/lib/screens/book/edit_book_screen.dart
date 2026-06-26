import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  State<EditBookScreen> createState() =>
      _EditBookScreenState();
}

class _EditBookScreenState
    extends State<EditBookScreen> {

  final bookService = BookService();
  final categoryService =
      CategoryService();

  late TextEditingController
      titleController;

  late TextEditingController
      authorController;

  late TextEditingController
      yearController;

  late TextEditingController
      pageController;

  late TextEditingController
      descController;

  List<CategoryModel> categories =
      [];

  String? selectedCategoryId;

  File? coverImage;

  PlatformFile? bookFile;

  @override
  void initState() {
    super.initState();

    titleController =
        TextEditingController(
      text: widget.book.tieuDe,
    );

    authorController =
        TextEditingController(
      text: widget.book.tacGia,
    );

    yearController =
        TextEditingController(
      text:
          widget.book.namXuatBan
              ?.toString() ??
          "",
    );

    pageController =
        TextEditingController(
      text:
          widget.book.tongSoTrang
              ?.toString() ??
          "",
    );

    descController =
        TextEditingController(
      text: widget.book.moTa ?? "",
    );

    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      categories =
          await categoryService
              .getAllCategory();

      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  Future<void> pickImage() async {
    final picked =
        await ImagePicker()
            .pickImage(
      source:
          ImageSource.gallery,
    );

    if (picked != null) {
      setState(() {
        coverImage =
            File(picked.path);
      });
    }
  }

  Future<void> pickBook() async {
    final result =
        await FilePicker
            .platform
            .pickFiles();

    if (result != null) {
      setState(() {
        bookFile =
            result.files.first;
      });
    }
  }

  Future<void> updateBook() async {
    try {
      await bookService.updateBook(
        id: widget.book.id,
        title:
            titleController.text,
        author:
            authorController.text,
        year:
            yearController.text,
        pages:
            pageController.text,
        description:
            descController.text,
        categoryId:
            selectedCategoryId,
        imagePath:
            coverImage?.path,
        bookPath:
            bookFile?.path,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            "Cập nhật thành công",
          ),
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
              Text("Lỗi: $e"),
        ),
      );
    }
  }

  @override
  Widget build(
      BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          "Sửa sách",
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(
          16,
        ),

        child: Column(
          children: [

            TextField(
              controller:
                  titleController,
              decoration:
                  const InputDecoration(
                labelText:
                    "Tiêu đề",
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            TextField(
              controller:
                  authorController,
              decoration:
                  const InputDecoration(
                labelText:
                    "Tác giả",
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            DropdownButtonFormField<
                String>(
              value:
                  selectedCategoryId,
              decoration:
                  const InputDecoration(
                labelText:
                    "Thể loại",
              ),
              items:
                  categories.map(
                (item) {
                  return DropdownMenuItem(
                    value: item.id,
                    child: Text(
                      item.tenTheLoai,
                    ),
                  );
                },
              ).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategoryId =
                      value;
                });
              },
            ),

            const SizedBox(
              height: 10,
            ),

            TextField(
              controller:
                  yearController,
              decoration:
                  const InputDecoration(
                labelText:
                    "Năm xuất bản",
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            TextField(
              controller:
                  pageController,
              decoration:
                  const InputDecoration(
                labelText:
                    "Số trang",
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            TextField(
              controller:
                  descController,
              maxLines: 4,
              decoration:
                  const InputDecoration(
                labelText:
                    "Mô tả",
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            ElevatedButton(
              onPressed:
                  pickImage,
              child: Text(
                coverImage ==
                        null
                    ? "Đổi ảnh bìa"
                    : "Đã chọn ảnh",
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            ElevatedButton(
              onPressed:
                  pickBook,
              child: Text(
                bookFile ==
                        null
                    ? "Đổi file sách"
                    : bookFile!.name,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            ElevatedButton(
              onPressed:
                  updateBook,
              child:
                  const Text(
                "Cập nhật",
              ),
            ),
          ],
        ),
      ),
    );
  }
}