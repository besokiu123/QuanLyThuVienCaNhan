import 'package:flutter/material.dart';

import '../../models/book_model.dart';
import '../../services/reading_service.dart';
import 'read_book_screen.dart';
import '../note/note_list_screen.dart';
class BookDetailScreen extends StatefulWidget {
  final BookModel book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final _readingService = ReadingService();
  String? _epubCfi;
  int _currentPage = 0;
  int _tongSoTrang = 0;
  bool _loadingProgress = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final data = await _readingService.getProgress(widget.book.id);
      if (mounted) {
        setState(() {
          _currentPage = data['trang_hien_tai'] as int;
          _epubCfi = data['epubCfi'] as String?;
          _tongSoTrang = widget.book.tongSoTrang!;
          _loadingProgress = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingProgress = false);
    }
  }

  bool get _isReadingInProgress {
    final isEpub = widget.book.loaiFile?.toUpperCase() == 'EPUB';
    if (isEpub) {
      return _epubCfi != null && _epubCfi!.isNotEmpty;
    }
    return _currentPage > 1;
  }

  double get _progressPercent {
    if (_tongSoTrang <= 0) return 0;
    return (_currentPage / _tongSoTrang).clamp(0.0, 1.0);
  }

  void _openReader() {
    if (widget.book.fileUrl == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadBookScreen(
          bookId: widget.book.id,
          fileUrl: widget.book.fileUrl!,
          loaiFile: widget.book.loaiFile ?? 'PDF',
        ),
      ),
    ).then((_) {
      _loadProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final isEpub = book.loaiFile?.toUpperCase() == 'EPUB';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          book.tieuDe,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
  // Nút ghi chú
  IconButton(
    icon: const Icon(Icons.note_outlined, color: Colors.black54),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NoteListScreen(book: book),
        ),
      );
    },
    tooltip: 'Ghi chú',
  ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== ẢNH BÌA =====
            if (book.anhBia != null)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    book.anhBia!,
                    height: 280,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 280,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Icon(Icons.book, size: 80, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // ===== THÔNG TIN SÁCH =====
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.tieuDe,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tác giả
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A5D4E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Color(0xFF4A5D4E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tác giả: ${book.tacGia}',
                          style: const TextStyle(
                            color: Color(0xFF444444),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Năm xuất bản
                  if (book.namXuatBan != null) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A5D4E).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Color(0xFF4A5D4E),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Năm XB: ${book.namXuatBan}',
                          style: const TextStyle(
                            color: Color(0xFF444444),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Số trang
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A5D4E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.pages,
                          size: 16,
                          color: Color(0xFF4A5D4E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Số trang: ${book.tongSoTrang}',
                        style: const TextStyle(
                          color: Color(0xFF444444),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Định dạng
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A5D4E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.description,
                          size: 16,
                          color: Color(0xFF4A5D4E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isEpub
                              ? Colors.purple.withOpacity(0.1)
                              : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isEpub ? 'EPUB' : 'PDF',
                          style: TextStyle(
                            color: isEpub ? Colors.purple[700] : Colors.blue[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ===== TIẾN ĐỘ ĐỌC =====
            if (!_loadingProgress && book.fileUrl != null) ...[
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tiến độ đọc',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Color(0xFF222222),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _isReadingInProgress
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isReadingInProgress
                                ? (isEpub
                                    ? '📖 Đang đọc'
                                    : 'Trang $_currentPage / $_tongSoTrang')
                                : 'Chưa đọc',
                            style: TextStyle(
                              color: _isReadingInProgress
                                  ? Colors.green[700]
                                  : Colors.grey[500],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: isEpub ? (_isReadingInProgress ? 0.5 : 0) : _progressPercent,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        color: const Color(0xFF4A5D4E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          isEpub
                              ? (_isReadingInProgress ? 'Đang đọc' : '0%')
                              : '${(_progressPercent * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ===== MÔ TẢ =====
            if (book.moTa != null && book.moTa!.isNotEmpty) ...[
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mô tả',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.moTa!,
                      style: TextStyle(
                        color: Colors.grey[700],
                        height: 1.6,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ===== NÚT ĐỌC SÁCH =====
            if (book.fileUrl != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(
                    _isReadingInProgress ? Icons.refresh : Icons.play_arrow,
                  ),
                  label: Text(
                    _isReadingInProgress
                        ? (isEpub
                            ? 'Đọc tiếp sách'
                            : 'Đọc tiếp từ trang $_currentPage')
                        : 'Bắt đầu đọc sách',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isReadingInProgress
                        ? Colors.green[700]
                        : const Color(0xFF4A5D4E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _openReader,
                ),
              ),

              if (_isReadingInProgress) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[700],
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isEpub
                              ? '📖 Bạn đang đọc dở cuốn sách này'
                              : '📖 Bạn đang đọc dở tại trang $_currentPage',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}