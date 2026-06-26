import 'package:flutter/material.dart';
import '../../services/bookmark_service.dart';
import '../../services/book_service.dart';
import '../../models/bookmark_model.dart';
import '../../models/book_model.dart';
import '../book/book_detail_screen.dart';

class BookmarkListScreen extends StatefulWidget {
  const BookmarkListScreen({super.key});

  @override
  State<BookmarkListScreen> createState() => _BookmarkListScreenState();
}

class _BookmarkListScreenState extends State<BookmarkListScreen> {
  final BookmarkService _bookmarkService = BookmarkService();
  final BookService _bookService = BookService();

  List<BookmarkModel> _bookmarks = [];
  Map<String, BookModel> _bookCache = {};
  bool _isLoading = true;
  String? _errorMessage;
  String _filterBookId = '';

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Lấy danh sách sách của user
      final books = await _bookService.getAllBooks();
      
      // Lấy bookmark cho từng sách
      List<BookmarkModel> allBookmarks = [];
      for (final book in books) {
        final bookmarks = await _bookmarkService.getBookmarksByBook(book.id);
        if (bookmarks.isNotEmpty) {
          _bookCache[book.id] = book;
          allBookmarks.addAll(bookmarks);
        }
      }

      // Sắp xếp theo thời gian tạo mới nhất
      allBookmarks.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      setState(() {
        _bookmarks = allBookmarks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteBookmark(BookmarkModel bookmark) async {
    final confirm = await showDialog<bool>(
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
          'Bạn có chắc muốn xóa đánh dấu trang này?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _bookmarkService.deleteBookmark(bookmark.id);
        setState(() {
          _bookmarks.removeWhere((b) => b.id == bookmark.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã xóa đánh dấu trang'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _goToBookDetail(BookmarkModel bookmark) {
    final book = _bookCache[bookmark.sachId];
    if (book != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookDetailScreen(book: book),
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
          'Đánh dấu trang',
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _loadBookmarks,
          ),
        ],
      ),
      body: _isLoading
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
                    'Đang tải...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBookmarks,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A5D4E),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _bookmarks.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _bookmarks.length,
                      itemBuilder: (context, index) {
                        final bookmark = _bookmarks[index];
                        final book = _bookCache[bookmark.sachId];
                        return _buildBookmarkCard(bookmark, book);
                      },
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
            Icons.bookmark_border,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có đánh dấu trang nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đọc sách và đánh dấu những trang bạn yêu thích',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ================= BOOKMARK CARD =================
  Widget _buildBookmarkCard(BookmarkModel bookmark, BookModel? book) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        onTap: () => _goToBookDetail(bookmark),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // Book cover
            Container(
              width: 50,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
                image: book?.anhBia != null
                    ? DecorationImage(
                        image: NetworkImage(book!.anhBia!),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      )
                    : null,
              ),
              child: book?.anhBia == null
                  ? const Icon(Icons.book, size: 24, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book?.tieuDe ?? 'Sách không tìm thấy',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF222222),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.bookmark,
                        size: 16,
                        color: const Color(0xFF4A5D4E),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Trang ${bookmark.soTrang}',
                        style: TextStyle(
                          color: const Color(0xFF4A5D4E),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (bookmark.createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(bookmark.createdAt!),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Actions
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red[400],
                  onPressed: () => _deleteBookmark(bookmark),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  color: Colors.grey[400],
                  onPressed: () => _goToBookDetail(bookmark),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= FORMAT DATE =================
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return '${diff.inDays} ngày trước';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}