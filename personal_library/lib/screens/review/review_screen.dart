import 'package:flutter/material.dart';
import '../../services/review_service.dart';
import '../../models/review_model.dart';

class ReviewScreen extends StatefulWidget {
  final String bookId;
  final String bookTitle;

  const ReviewScreen({
    super.key,
    required this.bookId,
    required this.bookTitle,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _reviewController = TextEditingController();

  int _selectedRating = 0;
  int _hoverRating = 0;
  bool _isLoading = false;
  bool _isSubmitting = false;
  ReviewModel? _myReview;
  List<ReviewModel> _reviews = [];
  double _averageRating = 0;
  int _totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);

    try {
      final reviews = await _reviewService.getReviewsByBook(widget.bookId);

      // Tính trung bình
      if (reviews.isNotEmpty) {
        final total = reviews.fold(0, (sum, r) => sum + r.soSao);
        _averageRating = total / reviews.length;
        _totalReviews = reviews.length;
      }

      // Tìm review của user hiện tại (lấy review đầu tiên làm demo)
      // Trong thực tế, cần backend xác định user
      _myReview = reviews.isNotEmpty ? reviews.first : null;

      if (_myReview != null) {
        _selectedRating = _myReview!.soSao;
        _reviewController.text = _myReview!.nhanXet;
      }

      _reviews = reviews;
    } catch (e) {
      print('❌ Load reviews error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _submitReview() async {
    final nhanXet = _reviewController.text.trim();

    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn số sao'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (nhanXet.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập nhận xét'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _reviewService.saveReview(
        bookId: widget.bookId,
        soSao: _selectedRating,
        nhanXet: nhanXet,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đánh giá thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadReviews();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
      );
    }

    setState(() => _isSubmitting = false);
  }

  Future<void> _deleteReview() async {
    if (_myReview == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa đánh giá'),
        content: const Text('Bạn có chắc muốn xóa đánh giá này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
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
        await _reviewService.deleteReview(_myReview!.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã xóa đánh giá'),
            backgroundColor: Colors.green,
          ),
        );
        _myReview = null;
        _selectedRating = 0;
        _reviewController.clear();
        await _loadReviews();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Đánh giá sách',
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
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A5D4E)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== THÔNG TIN TỔNG QUAN =====
                  _buildRatingSummary(),
                  const SizedBox(height: 16),

                  // ===== FORM ĐÁNH GIÁ =====
                  _buildReviewForm(),
                  const SizedBox(height: 16),

                  // ===== DANH SÁCH ĐÁNH GIÁ =====
                  _buildReviewList(),
                ],
              ),
            ),
    );
  }

  // ===== TỔNG QUAN ĐÁNH GIÁ =====
  Widget _buildRatingSummary() {
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
      child: Row(
        children: [
          // Số sao trung bình
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF4A5D4E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _averageRating > 0
                      ? _averageRating.toStringAsFixed(1)
                      : '0.0',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < _averageRating.round()
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 14,
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.bookTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$_totalReviews đánh giá',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 4),
                _buildRatingBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== THANH TIẾN ĐỘ SAO =====
  Widget _buildRatingBar() {
    // Đếm số lượng từng sao
    final counts = List<int>.filled(5, 0);
    for (final review in _reviews) {
      if (review.soSao >= 1 && review.soSao <= 5) {
        counts[review.soSao - 1]++;
      }
    }

    return Column(
      children: List.generate(5, (index) {
        final starIndex = 4 - index;
        final count = counts[starIndex];
        final percentage = _totalReviews > 0
            ? (count / _totalReviews * 100).clamp(0, 100)
            : 0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            children: [
              Text(
                '${starIndex + 1}★',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    color: Colors.amber,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ===== FORM ĐÁNH GIÁ =====
  Widget _buildReviewForm() {
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
            'Đánh giá của bạn',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 12),

          // ===== CHỌN SAO =====
          // ===== CHỌN SAO =====
          Row(
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              final isSelected = starIndex <= _selectedRating;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    // Nếu đã chọn cùng số sao thì bỏ chọn (0)
                    if (_selectedRating == starIndex) {
                      _selectedRating = 0;
                    } else {
                      _selectedRating = starIndex;
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    isSelected ? Icons.star : Icons.star_border,
                    color: isSelected ? Colors.amber : Colors.grey[300],
                    size: 36,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedRating > 0
                ? 'Bạn đã chọn $_selectedRating sao'
                : 'Chọn số sao',
            style: TextStyle(
              color: _selectedRating > 0 ? Colors.amber[700] : Colors.grey[500],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),

          // ===== NHẬP NHẬN XÉT =====
          TextField(
            controller: _reviewController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Viết nhận xét của bạn...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4A5D4E)),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 12),

          // ===== NÚT LƯU =====
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A5D4E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _myReview != null ? 'Cập nhật' : 'Gửi đánh giá',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
              if (_myReview != null) ...[
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: _isSubmitting ? null : _deleteReview,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Xóa',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ===== DANH SÁCH ĐÁNH GIÁ =====
  Widget _buildReviewList() {
    if (_reviews.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
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
        child: const Column(
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Chưa có đánh giá nào',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Hãy là người đầu tiên đánh giá cuốn sách này!',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      );
    }

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
            'Tất cả đánh giá',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 12),
          ..._reviews.map((review) => _buildReviewItem(review)),
        ],
      ),
    );
  }

  // ===== ITEM ĐÁNH GIÁ =====
  Widget _buildReviewItem(ReviewModel review) {
    final isMyReview = review.id == _myReview?.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMyReview ? Colors.blue[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: isMyReview ? Border.all(color: Colors.blue[200]!) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF4A5D4E),
                child: review.anhDaiDien != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          review.anhDaiDien!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Text(
                            review.tenHienThi?.substring(0, 1) ?? '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        review.tenHienThi?.substring(0, 1) ?? '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review.tenHienThi ?? 'Người dùng',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (isMyReview) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Bạn',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < review.soSao ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 14,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              if (review.createdAt != null)
                Text(
                  _formatDate(review.createdAt!),
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.nhanXet,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

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
