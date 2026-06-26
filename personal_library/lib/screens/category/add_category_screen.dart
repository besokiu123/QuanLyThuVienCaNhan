import 'package:flutter/material.dart';
import '../../services/category_service.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final tenController = TextEditingController();

  final moTaController = TextEditingController();

  final CategoryService service = CategoryService();

  bool isLoading = false;

  @override
  void dispose() {
    tenController.dispose();
    moTaController.dispose();
    super.dispose();
  }

  Future<void> saveCategory() async {
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
      await service.addCategory(
        tenController.text.trim(),
        moTaController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Thêm thể loại thành công")));

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
      appBar: AppBar(title: const Text("Thêm thể loại")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: tenController,
              decoration: const InputDecoration(labelText: "Tên thể loại"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: moTaController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Mô tả"),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveCategory,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Lưu"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
