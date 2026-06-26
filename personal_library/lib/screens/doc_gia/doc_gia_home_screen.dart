import 'package:flutter/material.dart';
import '../../services/book_service.dart';
import '../../services/reading_service.dart';
import '../../services/goal.service.dart';
import '../../services/admin_service.dart';
import '../../services/category_service.dart';
import '../../core/storage/auth_storage.dart';
import '../../models/book_model.dart';
import '../../models/category_model.dart';
import '../book/book_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../goal/goal_screen.dart';
import '../statistics/statistics_screen.dart';
import '../bookmark/bookmark_list_screen.dart';
import '../../widgets/book_card_widget.dart';

class DocGiaHomeScreen extends StatefulWidget {
  const DocGiaHomeScreen({super.key});

  @override
  State<DocGiaHomeScreen> createState() => _DocGiaHomeScreenState();
}

class _DocGiaHomeScreenState extends State<DocGiaHomeScreen> {
  final BookService _bookService = BookService();
  final ReadingService _readingService = ReadingService();
  final GoalService _goalService = GoalService();
  final AdminService _adminService = AdminService();
  final CategoryService _categoryService = CategoryService();

  List<BookModel> _allBooks = [];
  List<BookModel> _filteredBooks = [];
  List<BookModel> _readingBooks = [];
  List<BookModel> _completedBooks = [];
  List<BookModel> _unreadBooks = [];
  List<CategoryModel> _categories = [];

  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'Tất cả';
  String _selectedStatus =
      'Tất cả'; // 🔥 Thêm: Tất cả, Đang đọc, Đã đọc, Chưa đọc
  int _selectedNavIndex = 0;
  int _totalReading = 0;
  int _totalCompleted = 0;
  int _totalMinutes = 0;
  int _goalProgress = 0;
  int _goalTarget = 0;

  final List<String> _statusOptions = [
    'Tất cả',
    'Đang đọc',
    'Đã đọc',
    'Chưa đọc',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final books = await _bookService.getAllBooks();
      final categories = await _categoryService.getAllCategory();
      final stats = await _readingService.getUserStats();
      final currentYear = DateTime.now().year;
      final goalData = await _goalService.getMyProgress(currentYear);
      final readingBooks = await _readingService.getReadingBooks();
      final completedBooks = await _readingService.getCompletedBooks();
      print('📚 Total books: ${books.length}');
      print('📚 Reading books: ${readingBooks.length}');
      print('📚 Completed books: ${completedBooks.length}');

      // 🔥 Lấy sách chưa đọc (không có trong readingBooks và completedBooks)
      final readingIds = readingBooks.map((b) => b.id).toList();
      final completedIds = completedBooks.map((b) => b.id).toList();
      final unreadBooks = books
          .where(
            (b) => !readingIds.contains(b.id) && !completedIds.contains(b.id),
          )
          .toList();

      setState(() {
        _allBooks = books;
        _filteredBooks = books;
        _readingBooks = readingBooks;
        _completedBooks = completedBooks;
        _unreadBooks = unreadBooks;
        _categories = categories;
        _totalReading = stats['totalReading'] ?? 0;
        _totalCompleted = stats['totalCompleted'] ?? 0;
        _totalMinutes = stats['totalMinutes'] ?? 0;
        _goalProgress = goalData['phanTram'] ?? 0;
        _goalTarget = goalData['mucTieu'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Load data error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterBooks(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _applyFilters();
    });
  }

  void _filterByStatus(String status) {
    setState(() {
      _selectedStatus = status;
      _applyFilters();
    });
  }

  void _applyFilters() {
    _filteredBooks = _allBooks.where((book) {
      // Tìm kiếm
      final titleMatch = book.tieuDe.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final authorMatch = book.tacGia.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final searchMatch = _searchQuery.isEmpty || titleMatch || authorMatch;

      // Lọc theo thể loại
      bool categoryMatch = _selectedCategory == 'Tất cả';
      if (!categoryMatch && book.categoryName != null) {
        categoryMatch = book.categoryName == _selectedCategory;
      }

      // 🔥 Lọc theo trạng thái đọc
      bool statusMatch = true;
      final isReading = _readingBooks.any((b) => b.id == book.id);
      final isCompleted = _completedBooks.any((b) => b.id == book.id);

      switch (_selectedStatus) {
        case 'Đang đọc':
          statusMatch = isReading;
          break;
        case 'Đã đọc':
          statusMatch = isCompleted;
          break;
        case 'Chưa đọc':
          statusMatch = !isReading && !isCompleted;
          break;
        default:
          statusMatch = true;
      }

      return searchMatch && categoryMatch && statusMatch;
    }).toList();
  }

  // Lấy sách theo trạng thái cho tab Sách
  List<BookModel> _getBooksByStatus(String status) {
    switch (status) {
      case 'Đang đọc':
        return _readingBooks;
      case 'Đã đọc':
        return _completedBooks;
      case 'Chưa đọc':
        return _unreadBooks;
      default:
        return _allBooks;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _selectedNavIndex == 0 ? 'Thư viện của tôi' : 'Tất cả sách',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black54),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            tooltip: 'Thông tin cá nhân',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Tìm sách...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 18,
                          color: Colors.grey,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  _filterBooks('');
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: _filterBooks,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
                  Text('Đang tải...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : _selectedNavIndex == 0
          ? _buildHomeView()
          : _selectedNavIndex == 1
          ? const StatisticsScreen()
          : _selectedNavIndex == 2
          ? _buildAllBooksView()
          : _selectedNavIndex == 3
          ? const BookmarkListScreen()
          : const ProfileScreen(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ================= HOME VIEW =================
  Widget _buildHomeView() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickStats(),
            _buildReadingGoal(),
            _buildCategoryFilter(),
            if (_readingBooks.isNotEmpty) ...[
              _buildSectionTitle('Đang đọc', Icons.play_circle_outline),
              _buildBookHorizontalList(_readingBooks),
            ],
            if (_completedBooks.isNotEmpty) ...[
              _buildSectionTitle('Đã đọc', Icons.check_circle_outline),
              _buildBookHorizontalList(_completedBooks),
            ],
            _buildSectionTitle('Tất cả sách', Icons.menu_book),
            _buildBookGrid(),
          ],
        ),
      ),
    );
  }

  // ================= ALL BOOKS VIEW =================
  Widget _buildAllBooksView() {
    // Áp dụng bộ lọc trạng thái
    List<BookModel> booksToShow;
    switch (_selectedStatus) {
      case 'Đang đọc':
        booksToShow = _readingBooks;
        break;
      case 'Đã đọc':
        booksToShow = _completedBooks;
        break;
      case 'Chưa đọc':
        booksToShow = _unreadBooks;
        break;
      default:
        booksToShow = _filteredBooks;
    }

    // Sắp xếp mới nhất
    final sortedBooks = List<BookModel>.from(booksToShow);
    sortedBooks.sort((a, b) => b.id.compareTo(a.id));

    return Column(
      children: [
        // 🔥 Bộ lọc trạng thái
        Container(
          height: 40,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _statusOptions.length,
            itemBuilder: (context, index) {
              final status = _statusOptions[index];
              final isSelected = _selectedStatus == status;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    status,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => _filterByStatus(status),
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFF4A5D4E),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.grey[300]!,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: sortedBooks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'Không tìm thấy sách'
                            : 'Không có sách nào ở trạng thái này',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: sortedBooks.length,
                  itemBuilder: (context, index) {
                    final book = sortedBooks[index];
                    // 🔥 Hiển thị badge trạng thái
                    final isReading = _readingBooks.any((b) => b.id == book.id);
                    final isCompleted = _completedBooks.any(
                      (b) => b.id == book.id,
                    );
                    String statusBadge = '';
                    Color badgeColor = Colors.grey;
                    if (isCompleted) {
                      statusBadge = '✅ Đã đọc';
                      badgeColor = Colors.green;
                    } else if (isReading) {
                      statusBadge = '📖 Đang đọc';
                      badgeColor = Colors.blue;
                    } else {
                      statusBadge = '📗 Chưa đọc';
                      badgeColor = Colors.orange;
                    }

                    return Stack(
                      children: [
                        BookCardWidget(book: book, showProgress: false),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusBadge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ================= QUICK STATS =================
  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A5D4E), Color(0xFF6B8F7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A5D4E).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.play_circle_outline,
            value: '$_totalReading',
            label: 'Đang đọc',
            color: Colors.white,
          ),
          _buildStatItem(
            icon: Icons.check_circle_outline,
            value: '$_totalCompleted',
            label: 'Đã đọc',
            color: Colors.white,
          ),
          _buildStatItem(
            icon: Icons.timer,
            value: '${_totalMinutes ~/ 60}h${_totalMinutes % 60}m',
            label: 'Thời gian',
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color.withOpacity(0.8), size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
        ),
      ],
    );
  }

  // ================= READING GOAL =================
  Widget _buildReadingGoal() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4A5D4E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.flag, color: Color(0xFF4A5D4E), size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mục tiêu năm nay',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$_goalProgress%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF4A5D4E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _goalProgress / 100,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    color: const Color(0xFF4A5D4E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_totalCompleted / $_goalTarget cuốn sách',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            color: Colors.grey[400],
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GoalScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // ================= CATEGORY FILTER =================
  Widget _buildCategoryFilter() {
    final List<String> categoryNames = [
      'Tất cả',
      ..._categories.map((c) => c.tenTheLoai),
    ];

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categoryNames.length,
        itemBuilder: (context, index) {
          final category = categoryNames[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => _filterByCategory(category),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF4A5D4E),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.grey[300]!,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= SECTION TITLE =================
  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4A5D4E), size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedNavIndex = 2;
              });
            },
            child: const Text(
              'Xem tất cả',
              style: TextStyle(color: Color(0xFF4A5D4E), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ================= BOOK HORIZONTAL LIST =================
  Widget _buildBookHorizontalList(List<BookModel> books) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: books.length > 10 ? 10 : books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
              );
            },
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      book.anhBia ?? '',
                      height: 140,
                      width: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 140,
                        width: 120,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.book,
                          size: 30,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      book.tieuDe,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= BOOK GRID =================
  Widget _buildBookGrid() {
    if (_filteredBooks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.menu_book, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Không tìm thấy sách'
                    : 'Chưa có sách nào',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredBooks.length > 6 ? 6 : _filteredBooks.length,
      itemBuilder: (context, index) {
        final book = _filteredBooks[index];
        return BookCardWidget(book: book, showProgress: false);
      },
    );
  }

  // ================= BOTTOM NAV =================
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home,
                label: 'Trang chủ',
                isSelected: _selectedNavIndex == 0,
                onTap: () {
                  setState(() {
                    _selectedNavIndex = 0;
                    _searchQuery = '';
                    _selectedCategory = 'Tất cả';
                    _selectedStatus = 'Tất cả';
                    _applyFilters();
                  });
                },
              ),
              _buildNavItem(
                icon: Icons.bar_chart,
                label: 'Thống kê',
                isSelected: _selectedNavIndex == 1,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StatisticsScreen()),
                  );
                },
              ),
              _buildNavItem(
                icon: Icons.menu_book,
                label: 'Sách',
                isSelected: _selectedNavIndex == 2,
                onTap: () {
                  setState(() {
                    _selectedNavIndex = 2;
                  });
                },
              ),
              _buildNavItem(
                icon: Icons.bookmark_border,
                label: 'Đánh dấu',
                isSelected: _selectedNavIndex == 3,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BookmarkListScreen(),
                    ),
                  );
                },
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                label: 'Tôi',
                isSelected: _selectedNavIndex == 4,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF4A5D4E) : Colors.grey[400],
            size: 26,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF4A5D4E) : Colors.grey[400],
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
