import 'package:flutter/material.dart';
import '../../models/book_model.dart';
import '../../services/reading_service.dart';
import '../../services/highlight_service.dart';
import '../../services/note_service.dart';
import '../../services/review_service.dart'; // 🔥 THÊM
import '../../models/highlight_model.dart';
import '../../models/note_model.dart';
import '../../models/review_model.dart'; // 🔥 THÊM
import 'read_book_screen.dart';
import '../highlight/highlight_list_screen.dart';
import '../note/note_list_screen.dart';
import '../highlight/add_highlight_screen.dart';
import '../note/add_note_screen.dart';
import '../review/review_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final BookModel book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen>
    with SingleTickerProviderStateMixin {
  final _readingService = ReadingService();
  final _highlightService = HighlightService();
  final _noteService = NoteService();
  final _reviewService = ReviewService(); // 🔥 THÊM

  String? _epubCfi;
  int _currentPage = 0;
  int _tongSoTrang = 0;
  bool _loadingProgress = true;
  bool _isExpanded = false;
  int _highlightCount = 0;
  int _noteCount = 0;
  
  // 🔥 THÊM BIẾN RATING
  double _averageRating = 0;
  int _totalReviews = 0;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ===== LOAD TẤT CẢ DỮ LIỆU =====
  Future<void> _loadAllData() async {
    print('🔄 ===== LOAD ALL DATA =====');
    await Future.wait([
      _loadProgress(),
      _loadHighlightsAndNotes(),
      _loadReviews(), // 🔥 THÊM
    ]);
    print('🔄 ===== LOAD ALL DATA DONE =====');
  }

  // ===== LOAD PROGRESS =====
  Future<void> _loadProgress() async {
    try {
      print('🔄 Loading progress for book: ${widget.book.id}');
      final data = await _readingService.getProgress(widget.book.id);
      print('📥 Progress data: $data');

      final page = data['trang_hien_tai'] as int? ?? 0;
      final cfi = data['epubCfi'] as String?;

      print('📊 Page: $page');

      if (mounted) {
        setState(() {
          _currentPage = page;
          _epubCfi = cfi;
          _tongSoTrang = widget.book.tongSoTrang!;
          _loadingProgress = false;
        });
        print('✅ UI Updated: page=$_currentPage');
      }
    } catch (e) {
      print('❌ Load progress error: $e');
      if (mounted) {
        setState(() {
          _currentPage = 0;
          _epubCfi = null;
          _loadingProgress = false;
        });
      }
    }
  }

  // ===== LOAD HIGHLIGHTS & NOTES =====
  Future<void> _loadHighlightsAndNotes() async {
    try {
      print('🔄 Loading highlights and notes...');
      final results = await Future.wait([
        _highlightService.getHighlightsByBook(widget.book.id),
        _noteService.getNotesByBook(widget.book.id),
      ]);

      final highlights = results[0];
      final notes = results[1];

      print('📊 Highlights: ${highlights.length}, Notes: ${notes.length}');

      if (mounted) {
        setState(() {
          _highlightCount = highlights.length;
          _noteCount = notes.length;
        });
      }
    } catch (e) {
      print('❌ Load highlights/notes error: $e');
      if (mounted) {
        setState(() {
          _highlightCount = 0;
          _noteCount = 0;
        });
      }
    }
  }

  // 🔥 THÊM LOAD REVIEWS
  Future<void> _loadReviews() async {
    try {
      print('🔄 Loading reviews...');
      final reviews = await _reviewService.getReviewsByBook(widget.book.id);
      
      if (reviews.isNotEmpty) {
        final total = reviews.fold(0, (sum, r) => sum + r.soSao);
        _averageRating = total / reviews.length;
        _totalReviews = reviews.length;
      } else {
        _averageRating = 0;
        _totalReviews = 0;
      }
      
      print('📊 Rating: $_averageRating ($_totalReviews reviews)');
    } catch (e) {
      print('❌ Load reviews error: $e');
      _averageRating = 0;
      _totalReviews = 0;
    }
  }

  // ===== REFRESH SAU KHI ĐÓNG READER =====
  Future<void> _refreshData() async {
    print('🔄 ===== REFRESH DATA AFTER READER =====');
    await _loadAllData();
    if (mounted) {
      setState(() {});
      print('✅ UI REFRESHED');
    }
  }

  bool get _isReadingInProgress {
    return _currentPage > 0;
  }

  double get _progressPercent {
    if (_tongSoTrang <= 0) return 0;
    final page = _currentPage > _tongSoTrang ? _tongSoTrang : _currentPage;
    return (page / _tongSoTrang).clamp(0.0, 1.0);
  }

  // ===== MỞ READER =====
  void _openReader({bool readFromBeginning = false}) {
    if (widget.book.fileUrl == null) return;

    print('📖 Opening reader for book: ${widget.book.tieuDe}');
    print('📄 Current page: $_currentPage');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadBookScreen(
          bookId: widget.book.id,
          fileUrl: widget.book.fileUrl!,
          loaiFile: widget.book.loaiFile ?? 'PDF',
          bookTitle: widget.book.tieuDe,
          readFromBeginning: readFromBeginning,
        ),
      ),
    ).then((_) {
      print('📖 Reader closed, refreshing data...');
      _refreshData();
    });
  }

  void _confirmReadFromBeginning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Đọc từ đầu?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          _isReadingInProgress
              ? 'Bạn đang đọc đến trang $_currentPage. Đọc từ đầu sẽ reset vị trí hiện tại. Tiếp tục?'
              : 'Bạn có chắc muốn đọc từ đầu?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openReader(readFromBeginning: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đọc từ đầu'),
          ),
        ],
      ),
    );
  }

  // 🔥 WIDGET HIỂN THỊ SAO
  Widget _buildRatingStars(double rating, int totalReviews) {
    return Row(
      children: [
        // Hiển thị sao
        ...List.generate(5, (index) {
          final starIndex = index + 1;
          final isFullStar = rating >= starIndex;
          final isHalfStar = rating > index && rating < starIndex;
          
          IconData icon;
          Color color;
          
          if (isFullStar) {
            icon = Icons.star;
            color = Colors.amber;
          } else if (isHalfStar) {
            icon = Icons.star_half;
            color = Colors.amber;
          } else {
            icon = Icons.star_border;
            color = Colors.grey[300]!;
          }
          
          return Icon(
            icon,
            color: color,
            size: 18,
          );
        }),
        const SizedBox(width: 8),
        if (rating > 0)
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
        Text(
          totalReviews > 0 ? ' ($totalReviews đánh giá)' : ' (Chưa có đánh giá)',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final isEpub = book.loaiFile?.toUpperCase() == 'EPUB';
    final description = book.moTa ?? '';
    final bool hasLongDescription = description.length > 200;

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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[100],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== ẢNH BÌA VỚI HIỆU ỨNG =====
            if (book.anhBia != null)
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
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
                        child: const Icon(
                          Icons.book,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
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
                  const SizedBox(height: 8),
                  
                  // 🔥 THÊM ĐÁNH GIÁ SAO
                  _buildRatingStars(_averageRating, _totalReviews),
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

                  // Thể loại
                  if (book.categoryName != null &&
                      book.categoryName!.isNotEmpty) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A5D4E).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.category,
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
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            book.categoryName!,
                            style: const TextStyle(
                              color: Color(0xFF444444),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

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
                            color: isEpub
                                ? Colors.purple[700]
                                : Colors.blue[700],
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
                                ? '📖 Đang đọc (Trang $_currentPage/$_tongSoTrang)'
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
                        value: _progressPercent,
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
                          _isReadingInProgress
                              ? '${(_progressPercent * 100).toStringAsFixed(1)}%'
                              : '0%',
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.grey[700],
                            height: 1.6,
                            fontSize: 15,
                          ),
                          maxLines: _isExpanded ? null : 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (hasLongDescription) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isExpanded = !_isExpanded;
                              });
                            },
                            child: Text(
                              _isExpanded ? 'Thu gọn' : 'Xem thêm',
                              style: TextStyle(
                                color: const Color(0xFF4A5D4E),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ===== NÚT ĐỌC SÁCH =====
            if (book.fileUrl != null) ...[
              if (!_isReadingInProgress) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow, size: 20),
                    label: const Text(
                      'Bắt đầu đọc sách',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A5D4E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => _openReader(readFromBeginning: false),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(
                          'Đọc tiếp (Trang $_currentPage)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _openReader(readFromBeginning: false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.restart_alt, size: 18),
                        label: const Text(
                          'Từ đầu',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red[700],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.red[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _confirmReadFromBeginning,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
            ],

            // ===== NÚT ĐÁNH GIÁ SÁCH =====
            Container(
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
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Đánh giá sách',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  _totalReviews > 0
                      ? '${_averageRating.toStringAsFixed(1)} sao - $_totalReviews đánh giá'
                      : 'Hãy là người đầu tiên đánh giá',
                  style: TextStyle(
                    color: _totalReviews > 0 ? Colors.amber[700] : Colors.grey[500],
                    fontSize: 13,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReviewScreen(
                        bookId: book.id,
                        bookTitle: book.tieuDe,
                      ),
                    ),
                  ).then((_) {
                    _loadReviews();
                    if (mounted) setState(() {});
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // ===== TABS: HIGHLIGHT & NOTE =====
            Container(
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
                  TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF4A5D4E),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFF4A5D4E),
                    tabs: [
                      Tab(text: '📝 Ghi chú ($_noteCount)'),
                      Tab(text: '🟡 Highlight ($_highlightCount)'),
                    ],
                  ),
                  SizedBox(
                    height: 200,
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildNoteTab(), _buildHighlightTab()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ===== NÚT THÊM NHANH =====
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.note_add),
                    label: const Text('Thêm ghi chú'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4A5D4E),
                      side: const BorderSide(color: Color(0xFF4A5D4E)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddNoteScreen(bookId: book.id),
                        ),
                      );
                      if (result == true) {
                        await _loadHighlightsAndNotes();
                        if (mounted) setState(() {});
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.highlight),
                    label: const Text('Thêm highlight'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4A5D4E),
                      side: const BorderSide(color: Color(0xFF4A5D4E)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (book.fileUrl == null) return;
                      _openReader(readFromBeginning: false);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ===== NOTE TAB =====
  Widget _buildNoteTab() {
    return FutureBuilder<List<NoteModel>>(
      future: _noteService.getNotesByBook(widget.book.id).catchError((e) {
        print('❌ Note tab error: $e');
        return <NoteModel>[];
      }),
      initialData: const <NoteModel>[],
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final notes = snapshot.data ?? [];
        if (notes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.note_outlined, size: 40, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'Chưa có ghi chú nào',
                  style: TextStyle(color: Colors.grey),
                ),
                Text(
                  'Nhấn "Thêm ghi chú" để tạo mới',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: notes.length > 3 ? 3 : notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A5D4E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Tr ${note.soTrang}',
                      style: TextStyle(
                        color: const Color(0xFF4A5D4E),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note.noiDung,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 14),
                    color: Colors.grey,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NoteListScreen(book: widget.book),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===== HIGHLIGHT TAB =====
  Widget _buildHighlightTab() {
    return FutureBuilder<List<HighlightModel>>(
      future: _highlightService.getHighlightsByBook(widget.book.id).catchError((
        e,
      ) {
        print('❌ Highlight tab error: $e');
        return <HighlightModel>[];
      }),
      initialData: const <HighlightModel>[],
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final highlights = snapshot.data ?? [];
        if (highlights.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.highlight_off, size: 40, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'Chưa có highlight nào',
                  style: TextStyle(color: Colors.grey),
                ),
                Text(
                  'Đọc sách và highlight đoạn văn hay',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: highlights.length > 3 ? 3 : highlights.length,
          itemBuilder: (context, index) {
            final highlight = highlights[index];
            final color = Color(
              int.parse(highlight.color.replaceFirst('#', '0xFF')),
            );
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      highlight.text,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 14),
                    color: Colors.grey,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              HighlightListScreen(bookId: widget.book.id),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}