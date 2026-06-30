const reviewService = require('../services/review.service');

// ================= LƯU ĐÁNH GIÁ =================
exports.saveReview = async (req, res) => {
    try {
        const { bookId, soSao, nhanXet } = req.body;
        const userId = req.user.id;

        console.log('📝 Save review:', { userId, bookId, soSao, nhanXet });

        // Validate input
        if (!bookId) {
            return res.status(400).json({ 
                success: false, 
                message: 'Thiếu bookId' 
            });
        }

        if (!soSao || soSao < 1 || soSao > 5) {
            return res.status(400).json({ 
                success: false, 
                message: 'Số sao phải từ 1 đến 5' 
            });
        }

        if (!nhanXet || nhanXet.trim() === '') {
            return res.status(400).json({ 
                success: false, 
                message: 'Nội dung đánh giá không được để trống' 
            });
        }

        const review = await reviewService.upsertReview(
            userId,
            bookId,
            soSao,
            nhanXet
        );

        res.status(200).json({
            success: true,
            message: 'Đánh giá thành công',
            data: review
        });
    } catch (error) {
        console.error('❌ Save review error:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Không thể lưu đánh giá'
        });
    }
};

// ================= LẤY DANH SÁCH ĐÁNH GIÁ =================
exports.getByBook = async (req, res) => {
    try {
        const { bookId } = req.params;
        
        console.log('📥 Get reviews for book:', bookId);

        const reviews = await reviewService.getReviewsByBook(bookId);

        res.status(200).json(reviews);
    } catch (error) {
        console.error('❌ Get reviews error:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Không thể lấy danh sách đánh giá'
        });
    }
};

// ================= XÓA ĐÁNH GIÁ =================
exports.remove = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user.id;

        console.log('🗑️ Delete review:', { id, userId });

        await reviewService.deleteReview(id, userId);

        res.status(200).json({
            success: true,
            message: 'Đã xóa đánh giá'
        });
    } catch (error) {
        console.error('❌ Delete review error:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Không thể xóa đánh giá'
        });
    }
};