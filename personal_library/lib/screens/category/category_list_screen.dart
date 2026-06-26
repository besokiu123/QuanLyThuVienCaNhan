import 'package:flutter/material.dart';

import '../../models/category_model.dart';
import '../../services/category_service.dart';
import 'add_category_screen.dart';
import 'edit_category_screen.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final CategoryService service = CategoryService();

  List<CategoryModel> categories = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      categories = await service.getAllCategory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  Future<void> deleteCategory(String id) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await service.deleteCategory(id);

      if (!mounted) return;

      await loadData();

      messenger.showSnackBar(const SnackBar(content: Text('Xóa thành công')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Xóa thất bại: $e')));
    }
  }

  Future<void> openAddScreen() async {
    final shouldReload = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddCategoryScreen()),
    );

    if (shouldReload == true) {
      await loadData();
    }
  }

  Future<void> openEditScreen(CategoryModel item) async {
    final shouldReload = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditCategoryScreen(category: item)),
    );

    if (shouldReload == true) {
      await loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách thể loại')),

      floatingActionButton: FloatingActionButton(
        onPressed: openAddScreen,
        child: const Icon(Icons.add),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final item = categories[index];

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(item.tenTheLoai),
                    subtitle: Text(item.moTa ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            openEditScreen(item);
                          },
                        ),

                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            deleteCategory(item.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
