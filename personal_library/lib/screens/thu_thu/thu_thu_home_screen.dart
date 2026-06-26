import 'package:flutter/material.dart';
import '../category/category_list_screen.dart';
import '../book/book_list_screen.dart';
import '../profile/profile_screen.dart';
import '../../core/network/api_client.dart';
import '../../models/book_model.dart';
import '../../services/book_service.dart';
import '../../services/admin_service.dart';
import '../../models/dashboard_stats.dart';
import '../profile/user_management_screen.dart';  

class ThuThuHomeScreen extends StatefulWidget {
  const ThuThuHomeScreen({super.key});

  @override
  State<ThuThuHomeScreen> createState() => _ThuThuHomeScreenState();
}

class _ThuThuHomeScreenState extends State<ThuThuHomeScreen> {
  int _selectedIndex = 0;

  // 🔥 SỬA: Xóa dòng thừa
  final List<Widget> _pages = [
    const DashboardView(),
    const BookListScreen(),
    const CategoryListScreen(),
    const UserManagementScreen(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Quản lý sách',
    'Thể loại',
    'Người dùng',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
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
          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              backgroundColor: Color(0xFF4A5D4E),
              radius: 18,
              child: Text(
                "TT",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF4A5D4E),
        unselectedItemColor: Colors.grey[600],
        currentIndex: _selectedIndex,
        onTap: (index) {
          print('🔵 ===== Tab clicked: $index =====');
          print('🔵 Tab name: ${_titles[index]}');
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: "Sách",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            activeIcon: Icon(Icons.category),
            label: "Thể loại",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: "Người dùng",
          ),
        ],
      ),
    );
  }
}

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final AdminService _adminService = AdminService();
  DashboardStats? _stats;
  List<BookModel> books = [];
  bool isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      isLoading = true;
      _errorMessage = null;
    });

    try {
      // 🔥 Dùng AdminService thay vì gọi trực tiếp
      final stats = await _adminService.getStats();
      final booksRes = await ApiClient.dio.get('/books');
      final booksData = booksRes.data['data'] ?? [];

      if (!mounted) return;

      setState(() {
        _stats = stats;
        books = List<BookModel>.from(
          booksData.map(
            (e) => BookModel.fromJson(Map<String, dynamic>.from(e)),
          ),
        );
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Lỗi tải dashboard: $e");
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteBook(String id) async {
    try {
      await BookService().deleteBook(id);
      await _fetchDashboardData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Xóa sách thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Lỗi xóa sách: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF4A5D4E), strokeWidth: 3),
            SizedBox(height: 16),
            Text('Đang tải dữ liệu...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'Lỗi: $_errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDashboardData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A5D4E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 Row các thẻ thống kê
          Row(
            children: [
              _buildStatCard(
                "Tổng sách",
                "${_stats?.totalBooks ?? 0}",
                Icons.menu_book,
                const Color(0xFF4A5D4E),
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                "Tổng người dùng",
                "${_stats?.totalUsers ?? 0}",
                Icons.people_outline,
                Colors.blueGrey,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                "Sách mới",
                "${_stats?.newArrivals ?? 0}",
                Icons.fiber_new,
                Colors.orange,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                "Đang đọc",
                "${_stats?.totalReading ?? 0}",
                Icons.play_circle_outline,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 🔥 Tiêu đề danh sách sách
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Sách gần đây",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222222),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Chuyển đến tab sách
                  // Có thể dùng GlobalKey hoặc callback
                },
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
                    color: Color(0xFF4A5D4E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 🔥 Danh sách sách
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: books.length > 5 ? 5 : books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
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
                  children: [
                    // Ảnh bìa
                    Container(
                      width: 45,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                        image: book.anhBia != null
                            ? DecorationImage(
                                image: NetworkImage(book.anhBia!),
                                fit: BoxFit.cover,
                                onError: (_, __) {},
                              )
                            : null,
                      ),
                      child: book.anhBia == null
                          ? const Icon(Icons.book, size: 24, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // Thông tin
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.tieuDe,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF222222),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            book.tacGia,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (book.loaiFile?.toUpperCase() ?? 'PDF') ==
                                          'EPUB'
                                      ? Colors.purple.withOpacity(0.1)
                                      : Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  book.loaiFile?.toUpperCase() ?? 'PDF',
                                  style: TextStyle(
                                    color:
                                        (book.loaiFile?.toUpperCase() ??
                                                'PDF') ==
                                            'EPUB'
                                        ? Colors.purple[700]
                                        : Colors.blue[700],
                                    fontSize: 10,
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

                    // Action buttons
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Colors.blue,
                          ),
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 30,
                            minHeight: 30,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _deleteBook(book.id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 30,
                            minHeight: 30,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222222),
              ),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
