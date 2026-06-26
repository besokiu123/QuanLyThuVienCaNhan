import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/reading_service.dart';
import '../../core/storage/auth_storage.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final ReadingService _readingService = ReadingService();

  bool _isLoading = true;
  String? _errorMessage;

  int _totalReading = 0;
  int _totalCompleted = 0;
  int _totalMinutes = 0;
  int _totalPages = 0;
  List<dynamic> _readingHistory = [];
  Map<String, dynamic> _genreStats = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stats = await _readingService.getUserStats();
      
      setState(() {
        _totalReading = stats['totalReading'] ?? 0;
        _totalCompleted = stats['totalCompleted'] ?? 0;
        _totalMinutes = stats['totalMinutes'] ?? 0;
        _totalPages = stats['totalPages'] ?? 0;
        _readingHistory = stats['readingHistory'] ?? [];
        _genreStats = stats['genreStats'] ?? {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Thống kê của tôi',
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
            onPressed: _loadStatistics,
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
                    'Đang tải thống kê...',
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
                        onPressed: _loadStatistics,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A5D4E),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // ===== TỔNG QUAN =====
                      _buildOverview(),
                      const SizedBox(height: 16),

                      // ===== BIỂU ĐỒ THỂ LOẠI =====
                      if (_genreStats.isNotEmpty) ...[
                        _buildGenreChart(),
                        const SizedBox(height: 16),
                      ],

                      // ===== TIẾN ĐỘ ĐỌC =====
                      _buildReadingProgress(),
                      const SizedBox(height: 16),

                      // ===== LỊCH SỬ ĐỌC =====
                      if (_readingHistory.isNotEmpty) ...[
                        _buildReadingHistory(),
                        const SizedBox(height: 16),
                      ],

                      // ===== THỐNG KÊ CHI TIẾT =====
                      _buildDetailStats(),
                    ],
                  ),
                ),
    );
  }

  // ================= OVERVIEW =================
  Widget _buildOverview() {
    return Container(
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
      child: Column(
        children: [
          const Text(
            'Tổng quan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverviewItem(
                value: '$_totalReading',
                label: 'Đang đọc',
                icon: Icons.play_circle_outline,
              ),
              _buildOverviewItem(
                value: '$_totalCompleted',
                label: 'Đã đọc',
                icon: Icons.check_circle_outline,
              ),
              _buildOverviewItem(
                value: '${_totalMinutes ~/ 60}h${_totalMinutes % 60}m',
                label: 'Thời gian',
                icon: Icons.timer,
              ),
              _buildOverviewItem(
                value: '$_totalPages',
                label: 'Trang đã đọc',
                icon: Icons.pages,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ================= GENRE CHART =================
  Widget _buildGenreChart() {
    final colors = [
      const Color(0xFF4A5D4E),
      const Color(0xFF6B8F7A),
      const Color(0xFF8CA89C),
      const Color(0xFFA9C4B8),
      const Color(0xFFC5D9CF),
    ];

    final entries = _genreStats.entries.toList();
    final total = entries.fold(0, (sum, e) => sum + (e.value as int));

    return Container(
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
            'Thể loại yêu thích',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sections: entries.asMap().entries.map((entry) {
                        final index = entry.key;
                        final e = entry.value;
                        final value = (e.value as int).toDouble();
                        final percentage = total > 0 ? value / total : 0;
                        
                        return PieChartSectionData(
                          color: colors[index % colors.length],
                          value: value,
                          title: '${(percentage * 100).toInt()}%',
                          radius: 50,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: entries.asMap().entries.map((entry) {
                      final index = entry.key;
                      final e = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colors[index % colors.length],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                e.key,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= READING PROGRESS =================
  Widget _buildReadingProgress() {
    return Container(
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
            'Tiến độ đọc',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildProgressItem(
                value: _totalReading + _totalCompleted,
                label: 'Tổng sách',
                color: const Color(0xFF4A5D4E),
              ),
              _buildProgressItem(
                value: _totalCompleted,
                label: 'Đã hoàn thành',
                color: Colors.green,
              ),
              _buildProgressItem(
                value: _totalReading,
                label: 'Đang đọc',
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem({
    required int value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ================= READING HISTORY =================
  Widget _buildReadingHistory() {
    return Container(
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
            'Lịch sử đọc gần đây',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 12),
          ..._readingHistory.take(5).map((item) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.menu_book, color: Color(0xFF4A5D4E)),
              title: Text(
                item['title'] ?? 'Không tên',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                'Đọc ${item['pages'] ?? 0} trang • ${item['date'] ?? ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              trailing: Text(
                '${item['minutes'] ?? 0}m',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ================= DETAIL STATS =================
  Widget _buildDetailStats() {
    return Container(
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
            'Thống kê chi tiết',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailItem(
            icon: Icons.menu_book,
            label: 'Tổng số sách',
            value: '${_totalReading + _totalCompleted}',
          ),
          _buildDetailItem(
            icon: Icons.timer,
            label: 'Tổng thời gian đọc',
            value: '${_totalMinutes ~/ 60}h${_totalMinutes % 60}m',
          ),
          _buildDetailItem(
            icon: Icons.pages,
            label: 'Tổng số trang đã đọc',
            value: '$_totalPages trang',
          ),
          _buildDetailItem(
            icon: Icons.speed,
            label: 'Trung bình mỗi sách',
            value: '${_totalCompleted > 0 ? (_totalPages ~/ _totalCompleted) : 0} trang',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF4A5D4E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF4A5D4E), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}