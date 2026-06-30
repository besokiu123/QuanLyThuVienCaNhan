import 'package:flutter/material.dart';
import 'package:personal_library/models/book_model.dart';
import 'package:personal_library/services/book_service.dart';
import 'add_book_screen.dart';
import 'edit_book_screen.dart';
import 'book_detail_screen.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final service = BookService();
  List<BookModel> books = [];
  List<BookModel> filteredBooks = [];
  bool isLoading = true;
  String _searchQuery = '';
  String _filterType = 'Tất cả';

  final List<String> _filterOptions = ['Tất cả', 'PDF', 'EPUB'];

  @override
  void initState() {
    super.initState();
    loadBooks();
  }

  Future<void> loadBooks() async {
    try {
      books = await service.getAllBooks();
      _applyFilters();
    } catch (e) {
      print(e);
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  void _applyFilters() {
    setState(() {
      filteredBooks = books.where((book) {
        final query = _searchQuery.toLowerCase();
        final titleMatch = book.tieuDe.toLowerCase().contains(query);
        final authorMatch = book.tacGia.toLowerCase().contains(query);
        final searchMatch = query.isEmpty || titleMatch || authorMatch;

        final typeMatch = _filterType == 'Tất cả' || 
            (book.loaiFile?.toUpperCase() ?? '') == _filterType.toUpperCase();

        return searchMatch && typeMatch;
      }).toList();
    });
  }

  Future<void> deleteBook(String id) async {
    try {
      await service.deleteBook(id);
      await loadBooks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Xóa sách thành công"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // 🔥 Nội dung chính
          isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFF4A5D4E),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Đang tải sách...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildSearchBar(),
                    _buildFilterChips(),
                    Expanded(
                      child: filteredBooks.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: filteredBooks.length,
                              itemBuilder: (context, index) {
                                final book = filteredBooks[index];
                                return _buildBookCard(book);
                              },
                            ),
                    ),
                  ],
                ),
          
          // 🔥 NÚT THÊM SÁCH - Đặt ở góc dưới cùng
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                print('🔵 FAB PRESSED!');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddBookScreen()),
                ).then((result) {
                  print('📤 Result: $result');
                  if (result == true) loadBooks();
                });
              },
              backgroundColor: const Color.fromARGB(255, 215, 77, 79),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ================= SEARCH BAR =================
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Tìm kiếm sách...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          border: InputBorder.none,
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[400]),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _applyFilters();
                    });
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _applyFilters();
          });
        },
      ),
    );
  }

  // ================= FILTER CHIPS =================
  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Text(
            'Loại:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          ..._filterOptions.map((filter) {
            final isSelected = _filterType == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _filterType = filter;
                    _applyFilters();
                  });
                },
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFF4A5D4E),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? Colors.transparent : Colors.grey[300]!,
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          Text(
            '${filteredBooks.length} sách',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ================= BOOK CARD =================
  Widget _buildBookCard(BookModel book) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookDetailScreen(book: book),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 65,
                  height: 85,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[100],
                    image: book.anhBia != null
                        ? DecorationImage(
                            image: NetworkImage(book.anhBia!),
                            fit: BoxFit.cover,
                            onError: (_, __) {},
                          )
                        : null,
                  ),
                  child: book.anhBia == null
                      ? Center(
                          child: Icon(
                            Icons.book,
                            size: 32,
                            color: Colors.grey[400],
                          ),
                        )
                      : null,
                ),
                
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.tieuDe,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF222222),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              book.tacGia,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (book.loaiFile?.toUpperCase() ?? 'PDF') == 'EPUB'
                                  ? Colors.purple.withOpacity(0.1)
                                  : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              book.loaiFile?.toUpperCase() ?? 'PDF',
                              style: TextStyle(
                                color: (book.loaiFile?.toUpperCase() ?? 'PDF') == 'EPUB'
                                    ? Colors.purple[700]
                                    : Colors.blue[700],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${book.tongSoTrang} trang',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        color: Colors.blue[700],
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditBookScreen(book: book),
                            ),
                          );
                          if (result == true) loadBooks();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: Colors.red[400],
                        onPressed: () {
                          _showDeleteDialog(book.id);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= EMPTY STATE =================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'Không tìm thấy sách' : 'Chưa có sách nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Thử tìm kiếm với từ khóa khác'
                : 'Nhấn nút + để thêm sách mới',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ================= DELETE DIALOG =================
  void _showDeleteDialog(String bookId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Xác nhận xóa',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bạn có chắc muốn xóa sách này?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              deleteBook(bookId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  // ================= FILTER DIALOG =================
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lọc sách',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Loại file',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _filterOptions.map((filter) {
                  final isSelected = _filterType == filter;
                  return FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _filterType = filter;
                        _applyFilters();
                      });
                      Navigator.pop(context);
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF4A5D4E).withOpacity(0.1),
                    checkmarkColor: const Color(0xFF4A5D4E),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF4A5D4E) : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}