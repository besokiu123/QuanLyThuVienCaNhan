import 'package:flutter/material.dart';

import '../../models/category_model.dart';
import '../../services/category_service.dart';

class EditCategoryScreen extends StatefulWidget {
  final CategoryModel category;

  const EditCategoryScreen({super.key, required this.category});

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  late final TextEditingController tenController;
  late final TextEditingController moTaController;

  final CategoryService service = CategoryService();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    tenController = TextEditingController(text: widget.category.tenTheLoai);
    moTaController = TextEditingController(text: widget.category.moTa ?? '');
  }

  @override
  void dispose() {
    tenController.dispose();
    moTaController.dispose();
    super.dispose();
  }

  Future<void> updateCategory() async {
    if (tenController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tên thể loại không được để trống")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await service.updateCategory(
        widget.category.id,
        tenController.text.trim(),
        moTaController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật thể loại thành công")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sửa thể loại')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: tenController,
              decoration: const InputDecoration(labelText: 'Tên thể loại'),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: moTaController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Mô tả'),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : updateCategory,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Cập nhật'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
