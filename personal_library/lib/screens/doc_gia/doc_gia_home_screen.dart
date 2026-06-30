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
  String _selectedStatus = 'Tất cả';
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

  String _tempCategory = 'Tất cả';
  String _tempStatus = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ===== LOAD DATA =====
Future<void> _loadData() async {
  setState(() => _isLoading = true);

  try {
    final books = await _bookService.getAllBooks();
    final categories = await _categoryService.getAllCategory();
    final stats = await _readingService.getUserStats();  // 🔥 LẤY STATS
    final currentYear = DateTime.now().year;
    final goalData = await _goalService.getMyProgress(currentYear);
    final readingBooks = await _readingService.getReadingBooks();
    final completedBooks = await _readingService.getCompletedBooks();

    // 🔥 LOG ĐỂ KIỂM TRA
    print('📊 Stats from service:');
    print('  - totalReading: ${stats['totalReading']}');
    print('  - totalCompleted: ${stats['totalCompleted']}');
    print('  - totalMinutes: ${stats['totalMinutes']}');  // 🔥 KIỂM TRA DÒNG NÀY
    print('  - totalPages: ${stats['totalPages']}');

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
      _totalMinutes = stats['totalMinutes'] ?? 0;  // 🔥 CẬP NHẬT PHÚT ĐỌC
      _goalProgress = goalData['phanTram'] ?? 0;
      _goalTarget = goalData['mucTieu'] ?? 0;
      _isLoading = false;
    });
  } catch (e) {
    debugPrint('❌ Load data error: $e');
    setState(() => _isLoading = false);
  }
}

// ===== HIỂN THỊ THỜI GIAN =====
String _formatTime(int minutes) {
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (hours > 0) {
    return '${hours}h${mins}m';
  }
  return '${mins}m';
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
      final titleMatch = book.tieuDe.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final authorMatch = book.tacGia.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final searchMatch = _searchQuery.isEmpty || titleMatch || authorMatch;

      bool categoryMatch = _selectedCategory == 'Tất cả';
      if (!categoryMatch && book.categoryName != null) {
        categoryMatch = book.categoryName == _selectedCategory;
      }

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

  void _openFilterBottomSheet() {
    _tempCategory = _selectedCategory;
    _tempStatus = _selectedStatus;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        builder: (_, controller) => _buildFilterSheet(controller),
      ),
    );
  }

  Widget _buildFilterSheet(ScrollController controller) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🔍 Lọc sách',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _tempCategory = 'Tất cả';
                          _tempStatus = 'Tất cả';
                        });
                      },
                      child: const Text(
                        'Đặt lại',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = _tempCategory;
                          _selectedStatus = _tempStatus;
                          _applyFilters();
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A5D4E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Áp dụng'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  '📌 Trạng thái đọc',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _statusOptions.map((status) {
                    final isSelected = _tempStatus == status;
                    return ChoiceChip(
                      label: Text(
                        status,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _tempStatus = status;
                        });
                      },
                      backgroundColor: Colors.grey[100],
                      selectedColor: const Color(0xFF4A5D4E),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? Colors.transparent : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Text(
                  '📂 Thể loại',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(
                        'Tất cả',
                        style: TextStyle(
                          color: _tempCategory == 'Tất cả' ? Colors.white : Colors.grey[700],
                          fontSize: 13,
                          fontWeight: _tempCategory == 'Tất cả' ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      selected: _tempCategory == 'Tất cả',
                      onSelected: (_) {
                        setState(() {
                          _tempCategory = 'Tất cả';
                        });
                      },
                      backgroundColor: Colors.grey[100],
                      selectedColor: const Color(0xFF4A5D4E),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: _tempCategory == 'Tất cả' ? Colors.transparent : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                    ),
                    ..._categories.map((category) {
                      final isSelected = _tempCategory == category.tenTheLoai;
                      return ChoiceChip(
                        label: Text(
                          category.tenTheLoai,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _tempCategory = category.tenTheLoai;
                          });
                        },
                        backgroundColor: Colors.grey[100],
                        selectedColor: const Color(0xFF4A5D4E),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? Colors.transparent : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Kết quả: ${_filteredBooks.length} sách',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        _selectedNavIndex == 0 ? '📚 Thư viện của tôi' : '📖 Tất cả sách',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontSize: 20,
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list, color: Colors.black54),
          onPressed: _openFilterBottomSheet,
          tooltip: 'Lọc sách',
        ),
        IconButton(
          icon: const Icon(Icons.person_outline, color: Colors.black54),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: '🔍 Tìm kiếm sách...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.grey),
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
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
    );
  }

  Widget _buildHomeView() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildQuickStats(),
              const SizedBox(height: 12),
              _buildReadingGoal(),
              const SizedBox(height: 8),
              _buildCategoryFilter(),
              const SizedBox(height: 8),
              if (_readingBooks.isNotEmpty) ...[
                _buildSectionTitle('📖 Đang đọc', Icons.play_circle_outline),
                _buildBookHorizontalList(_readingBooks),
                const SizedBox(height: 4),
              ],
              if (_completedBooks.isNotEmpty) ...[
                _buildSectionTitle('✅ Đã đọc', Icons.check_circle_outline),
                _buildBookHorizontalList(_completedBooks),
                const SizedBox(height: 4),
              ],
              _buildSectionTitle('📚 Tất cả sách', Icons.menu_book),
              _buildBookGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllBooksView() {
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

    if (_selectedCategory != 'Tất cả') {
      booksToShow = booksToShow.where((book) {
        return book.categoryName == _selectedCategory;
      }).toList();
    }

    final sortedBooks = List<BookModel>.from(booksToShow);
    sortedBooks.sort((a, b) => b.id.compareTo(a.id));

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list, size: 18, color: Color(0xFF4A5D4E)),
                    onPressed: _openFilterBottomSheet,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Bộ lọc: ${_selectedStatus}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (_selectedCategory != 'Tất cả') ...[
                    const Text(' | ', style: TextStyle(color: Colors.grey)),
                    Text(
                      _selectedCategory,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                '${sortedBooks.length} sách',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: sortedBooks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book, size: 56, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'Không tìm thấy sách'
                            : 'Không có sách nào',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.6,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: sortedBooks.length,
                  itemBuilder: (context, index) {
                    final book = sortedBooks[index];
                    final isReading = _readingBooks.any((b) => b.id == book.id);
                    final isCompleted = _completedBooks.any((b) => b.id == book.id);

                    String statusBadge = '';
                    Color badgeColor = Colors.grey;
                    if (isCompleted) {
                      statusBadge = 'Đã đọc';
                      badgeColor = Colors.green;
                    } else if (isReading) {
                      statusBadge = 'Đang đọc';
                      badgeColor = Colors.blue;
                    } else {
                      statusBadge = 'Chưa đọc';
                      badgeColor = Colors.orange;
                    }

                    return Stack(
                      children: [
                        BookCardWidget(book: book, showProgress: false),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusBadge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
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

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
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
          ),
          _buildStatItem(
            icon: Icons.check_circle_outline,
            value: '$_totalCompleted',
            label: 'Đã đọc',
          ),
          _buildStatItem(
            icon: Icons.timer,
            value: '${_totalMinutes ~/ 60}h${_totalMinutes % 60}m',
            label: 'Thời gian',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildReadingGoal() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
            child: const Icon(Icons.flag, color: Color(0xFF4A5D4E), size: 24),
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
                        fontSize: 13,
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
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 14),
            color: Colors.grey[400],
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4A5D4E), size: 18),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
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
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
            ),
            child: const Text(
              'Xem tất cả',
              style: TextStyle(
                color: Color(0xFF4A5D4E),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookHorizontalList(List<BookModel> books) {
    return SizedBox(
      height: 180,
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
              width: 110,
              margin: const EdgeInsets.only(right: 10),
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
                      height: 130,
                      width: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 130,
                        width: 110,
                        color: Colors.grey[200],
                        child: const Icon(Icons.book, size: 24, color: Colors.grey),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      book.tieuDe,
                      style: const TextStyle(
                        fontSize: 11,
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

  Widget _buildBookGrid() {
    if (_filteredBooks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.menu_book, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Không tìm thấy sách'
                    : 'Chưa có sách nào',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _filteredBooks.length > 4 ? 4 : _filteredBooks.length,
      itemBuilder: (context, index) {
        final book = _filteredBooks[index];
        return BookCardWidget(book: book, showProgress: false);
      },
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Trang chủ'},
      {'icon': Icons.bar_chart_outlined, 'activeIcon': Icons.bar_chart, 'label': 'Thống kê'},
      {'icon': Icons.menu_book_outlined, 'activeIcon': Icons.menu_book, 'label': 'Sách'},
      {'icon': Icons.bookmark_border, 'activeIcon': Icons.bookmark, 'label': 'Đánh dấu'},
      {'icon': Icons.person_outline, 'activeIcon': Icons.person, 'label': 'Tôi'},
    ];

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
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = _selectedNavIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedNavIndex = index;
                    if (index == 0) {
                      _searchQuery = '';
                      _selectedCategory = 'Tất cả';
                      _selectedStatus = 'Tất cả';
                      _applyFilters();
                    }
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? item['activeIcon'] as IconData : item['icon'] as IconData,
                      color: isSelected ? const Color(0xFF4A5D4E) : Colors.grey[400],
                      size: 24,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF4A5D4E) : Colors.grey[400],
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}